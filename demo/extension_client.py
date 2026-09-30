#!/usr/bin/env python3
"""
demo/extension_client.py

Headless LiveKit client for the extension demo:
Streams synthesized audio clips into a LiveKit room and saves the agent's
audio reply.
Reuses the proven room joining and audio streaming approach from
Full-Duplex-Bench/v3/livekit_inference.py without modifying benchmark files.
"""

import argparse
import asyncio
import logging
import os
import subprocess
import time
import uuid
import wave
from pathlib import Path

import numpy as np
from dotenv import load_dotenv
from livekit import api, rtc

# Load environment variables silently
ROOT = Path(__file__).resolve().parent.parent
load_dotenv(ROOT / ".env")
load_dotenv(ROOT / ".env.local")

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(message)s",
)
log = logging.getLogger("extension_client")

SAMPLE_WIDTH = 2
PUBLISH_SAMPLE_RATE = 48000
CAPTURE_SAMPLE_RATE = 24000
CHUNK_DURATION_MS = 20


def read_wav_pcm16(path: str, target_rate: int = 48000) -> tuple[bytes, int, int]:
    """Read WAV file and ensure mono PCM-16 at target_rate."""
    try:
        with wave.open(path, "rb") as wf:
            rate = wf.getframerate()
            ch = wf.getnchannels()
            sw = wf.getsampwidth()
            if ch == 1 and sw == 2 and rate == target_rate:
                return wf.readframes(wf.getnframes()), rate, 1
    except wave.Error:
        pass

    log.info("Converting '%s' to %d Hz mono 16-bit PCM via ffmpeg ...", path, target_rate)
    result = subprocess.run(
        [
            "ffmpeg", "-y",
            "-i", path,
            "-f", "s16le",
            "-acodec", "pcm_s16le",
            "-ar", str(target_rate),
            "-ac", "1",
            "pipe:1",
        ],
        capture_output=True,
        check=True,
    )
    return result.stdout, target_rate, 1


def write_wav(path: str, pcm_data: bytes, sample_rate: int, channels: int = 1):
    """Write raw PCM-16 bytes to a WAV file."""
    Path(path).parent.mkdir(parents=True, exist_ok=True)
    with wave.open(path, "wb") as wf:
        wf.setnchannels(channels)
        wf.setsampwidth(SAMPLE_WIDTH)
        wf.setframerate(sample_rate)
        wf.writeframes(pcm_data)


async def run_client(
    input_wav: str,
    output_wav: str,
    room_name: str,
    response_wait_sec: float = 8.0,
):
    url = os.getenv("LIVEKIT_URL")
    api_key = os.getenv("LIVEKIT_API_KEY")
    api_secret = os.getenv("LIVEKIT_API_SECRET")

    if not all([url, api_key, api_secret]):
        raise RuntimeError("Missing LiveKit credentials in .env")

    pcm_data, src_rate, src_channels = read_wav_pcm16(input_wav, PUBLISH_SAMPLE_RATE)
    total_samples = len(pcm_data) // SAMPLE_WIDTH
    duration_sec = total_samples / src_rate
    log.info("Loaded input: %s (%.2fs, %d Hz, mono)", input_wav, duration_sec, src_rate)

    token = (
        api.AccessToken(api_key, api_secret)
        .with_identity("driver-synthesized-input")
        .with_name("Driver")
        .with_grants(api.VideoGrants(room_join=True, room=room_name))
        .to_jwt()
    )

    # Allocate output buffer large enough for input duration + response_wait
    max_record_sec = duration_sec + response_wait_sec + 5.0
    target_samples = int(max_record_sec * CAPTURE_SAMPLE_RATE)
    output_buf = np.zeros(target_samples, dtype=np.int16)
    write_pos = 0

    recording_started = asyncio.Event()
    recording_stop = asyncio.Event()
    agent_connected = asyncio.Event()

    room = rtc.Room()
    receiving_task: asyncio.Task | None = None

    async def _receive_agent_audio(track: rtc.Track):
        nonlocal write_pos
        stream = rtc.AudioStream(
            track,
            sample_rate=CAPTURE_SAMPLE_RATE,
            num_channels=1,
        )
        log.info("Subscribed to agent audio stream.")
        await recording_started.wait()

        try:
            while not recording_stop.is_set():
                try:
                    frame_event = await asyncio.wait_for(stream.__anext__(), timeout=0.5)
                    frame = frame_event.frame
                    samples = np.frombuffer(bytes(frame.data), dtype=np.int16)
                    n = len(samples)
                    remaining = target_samples - write_pos
                    if remaining <= 0:
                        break
                    to_write = min(n, remaining)
                    output_buf[write_pos : write_pos + to_write] = samples[:to_write]
                    write_pos += to_write
                except asyncio.TimeoutError:
                    continue
                except StopAsyncIteration:
                    break
        except Exception as e:
            log.warning("Audio receive exception: %s", e)
        finally:
            await stream.aclose()
            log.info("Agent audio stream finished. Recorded %.2fs.", write_pos / CAPTURE_SAMPLE_RATE)

    @room.on("track_subscribed")
    def on_track_subscribed(track, publication, participant):
        if track.kind == rtc.TrackKind.KIND_AUDIO:
            log.info("Subscribed to audio track from '%s'", participant.identity)
            agent_connected.set()
            nonlocal receiving_task
            receiving_task = asyncio.create_task(_receive_agent_audio(track))

    @room.on("participant_connected")
    def on_participant_connected(participant):
        log.info("Participant joined: %s", participant.identity)
        if participant.identity != "driver-synthesized-input":
            agent_connected.set()

    log.info("Connecting to room '%s' ...", room_name)
    await room.connect(url, token, options=rtc.RoomOptions(auto_subscribe=True))
    log.info("Connected. Waiting for CarAssistant agent worker to join ...")

    # Wait up to 25 seconds for the agent worker to join
    try:
        await asyncio.wait_for(agent_connected.wait(), timeout=25.0)
    except asyncio.TimeoutError:
        log.warning("Agent worker did not join within 25s. Continuing to stream anyway.")

    # Publish audio track
    source = rtc.AudioSource(src_rate, src_channels)
    local_track = rtc.LocalAudioTrack.create_audio_track("driver-voice", source)
    pub_opts = rtc.TrackPublishOptions()
    pub_opts.source = rtc.TrackSource.SOURCE_MICROPHONE
    await room.local_participant.publish_track(local_track, pub_opts)

    # Allow agent greeting or connection stabilization
    await asyncio.sleep(2.0)

    samples_per_chunk = src_rate * CHUNK_DURATION_MS // 1000
    chunk_bytes = samples_per_chunk * src_channels * SAMPLE_WIDTH

    stream_start_time = time.time()
    recording_started.set()
    log.info("Streaming user voice clip (%.2fs) ...", duration_sec)

    offset = 0
    while offset < len(pcm_data):
        end = min(offset + chunk_bytes, len(pcm_data))
        chunk = pcm_data[offset:end]
        num_samples = len(chunk) // (SAMPLE_WIDTH * src_channels)
        frame = rtc.AudioFrame(
            data=chunk,
            sample_rate=src_rate,
            num_channels=src_channels,
            samples_per_channel=num_samples,
        )
        await source.capture_frame(frame)
        offset = end
        await asyncio.sleep(CHUNK_DURATION_MS / 1000)

    # Trailing silence for VAD
    silence_chunks = 1500 // CHUNK_DURATION_MS
    silence_data = b"\x00" * chunk_bytes
    for _ in range(silence_chunks):
        frame = rtc.AudioFrame(
            data=silence_data,
            sample_rate=src_rate,
            num_channels=src_channels,
            samples_per_channel=samples_per_chunk,
        )
        await source.capture_frame(frame)
        await asyncio.sleep(CHUNK_DURATION_MS / 1000)

    log.info("Finished streaming clip. Waiting %.1fs for agent tool call & response ...", response_wait_sec)
    await asyncio.sleep(response_wait_sec)

    recording_stop.set()
    if receiving_task and not receiving_task.done():
        await asyncio.sleep(0.2)
        if not receiving_task.done():
            receiving_task.cancel()
            try:
                await receiving_task
            except asyncio.CancelledError:
                pass

    if output_wav:
        saved_bytes = output_buf[:write_pos].tobytes()
        write_wav(output_wav, saved_bytes, CAPTURE_SAMPLE_RATE, 1)
        actual_speech = np.count_nonzero(output_buf[:write_pos]) / CAPTURE_SAMPLE_RATE
        log.info("Saved agent reply: %s (%.2fs, ~%.2fs speech)", output_wav, write_pos / CAPTURE_SAMPLE_RATE, actual_speech)

    await room.disconnect()
    log.info("Disconnected from room '%s'.", room_name)


def main():
    parser = argparse.ArgumentParser(description="Extension demo LiveKit client")
    parser.add_argument("-i", "--input", required=True, help="Input WAV file path")
    parser.add_argument("-o", "--output", default="", help="Output WAV file path (agent reply)")
    parser.add_argument("--room", default="", help="LiveKit room name")
    parser.add_argument("--wait", type=float, default=7.0, help="Wait time after speech in seconds")
    args = parser.parse_args()

    room = args.room or f"eval-ext-{uuid.uuid4().hex[:8]}"
    asyncio.run(run_client(args.input, args.output, room, args.wait))


if __name__ == "__main__":
    main()
