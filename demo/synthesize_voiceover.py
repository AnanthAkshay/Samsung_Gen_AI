#!/usr/bin/env python3
"""
demo/synthesize_voiceover.py

Synthesizes the complete 4:30 voiceover track from demo/VOICEOVER.md using
local Windows System.Speech.Synthesis, perfectly synchronized with
each scene's timestamp onset, and muxes it with demo/out/demo_silent.mp4.
"""

import os
import subprocess
from pathlib import Path
from pydub import AudioSegment

ROOT = Path(__file__).resolve().parent.parent
DEMO_DIR = ROOT / "demo"
OUT_DIR = DEMO_DIR / "out"
CLIPS_DIR = DEMO_DIR / "voice_clips"
CLIPS_DIR.mkdir(parents=True, exist_ok=True)

# Scene definitions with exact start offsets (in milliseconds)
# Total duration is 270,000 ms (4m 30s)
SCENES = [
    # Segment 1: Title & Architecture (00:00 - 00:40)
    {
        "id": "s1a",
        "offset_ms": 1000,
        "text": "Hello everyone, and welcome to our demonstration for the Samsung Gen AI Hackathon, Theme Zero Five: Interruptible Real-Time Agents.",
    },
    {
        "id": "s1b_1",
        "offset_ms": 8500,
        "text": "Here we present an end-to-end full-duplex voice agent using Google's Gemini Native Realtime model, connected over WebRTC through the LiveKit Voice Agents SDK.",
    },
    {
        "id": "s1b_2",
        "offset_ms": 20500,
        "text": "Unlike traditional cascaded architectures that combine Whisper, an LLM, and TTS, our agent operates directly on native speech tokens, eliminating intermediate transcription bottlenecks.",
    },
    {
        "id": "s1c",
        "offset_ms": 32500,
        "text": "Voice activity detection, barge-in interruptions, and multi-step tool calls are all executed natively in a single model pass.",
    },

    # Segment 2: Benchmark Evidence (00:40 - 02:10)
    {
        "id": "s2a",
        "offset_ms": 41500,
        "text": "Here is our real evaluation evidence evaluated on Full-Duplex-Bench v3. To be completely transparent, our evaluation represents a partial benchmark run of twenty-eight scenarios across e-commerce, finance, housing, and travel domains. Across all twenty-eight cases, the agent achieved a one hundred percent completion rate with zero silent failures and invoked thirty-eight tool calls.",
    },
    {
        "id": "s2b",
        "offset_ms": 66500,
        "text": "Now let's examine a completed benchmark scenario: e-commerce zero-one. Looking at the scenario directory, we see the raw input audio containing realistic user disfluencies. The user said: 'Like, uh, well, I ordered something last week and haven't received it yet, order ID A-B-C one-two-three.' Our agent seamlessly filtered out the filler hesitations, executed the track_order tool with order ID ABC123, and confirmed that the order is out for delivery.",
    },
    {
        "id": "s2c",
        "offset_ms": 101500,
        "text": "In quantitative exact-match evaluation, our agent achieved a Tool Selection F1 score of point-seven-five-nine, with a perfect precision of one-point-zero. This means zero false-positive tool calls and zero hallucinations across all evaluated domains. The native audio agent reliably extracts structured arguments even while conversational disfluencies are present in the incoming audio stream.",
    },

    # Segment 3: Extension Demo (02:10 - 04:10)
    {
        "id": "s3a",
        "offset_ms": 131500,
        "text": "Next, we demonstrate our real-world extension: an in-car voice navigation assistant designed to minimize driver distraction. The LiveKit worker is live, listening on WebRTC for streaming driver audio and dispatching mock navigation events.",
    },
    {
        "id": "s3b",
        "offset_ms": 146500,
        "text": "In clip one, the driver self-corrects mid-sentence, stating: 'Navigate to Koramangala. No wait, take me to Indiranagar instead.' Notice how the agent waits for the correction, automatically invokes cancel_navigation on the discarded Koramangala intent, and sets Indiranagar as the active route. Both tool calls executed in proper chronological sequence.",
    },
    {
        "id": "s3c",
        "offset_ms": 181500,
        "text": "In clip two, the driver changes their mind completely mid-utterance: 'Take me to the airport. Actually, cancel that.' The agent immediately detects the explicit cancellation, suppresses any active route creation, and leaves zero navigation sessions active. The driver is never directed to a discarded destination, maintaining driver safety on the road.",
    },
    {
        "id": "s3d",
        "offset_ms": 211500,
        "text": "In clip three, the driver hesitates: 'Navigate to M G Road. Um, hold on. Yes, M G Road.' The agent understands that 'um, hold on' is natural filler speech. It avoids false cancellations, remains attentive, and triggers exactly one navigation call to M G Road.",
    },
    {
        "id": "s3e",
        "offset_ms": 236500,
        "text": "Our extension audit confirms all three disfluency scenarios passed with complete log transparency. Gemini Native Realtime reliably interprets conversational speech without the latency and failure modes of traditional cascaded stacks.",
    },

    # Segment 4: Reproduction & Conclusion (04:10 - 04:30)
    {
        "id": "s4a",
        "offset_ms": 251000,
        "text": "Our entire evaluation pipeline is fully reproducible with a single command: reproduce.ps1 for Windows PowerShell or reproduce.sh on Linux.",
    },
    {
        "id": "s4b",
        "offset_ms": 260500,
        "text": "The setup requires only your LiveKit Cloud credentials and a free Google AI Studio key. Thank you for watching our demonstration!",
    },
]


def synthesize_clip(clip_id: str, text: str, out_wav: Path):
    """Use PowerShell System.Speech to render speech cleanly."""
    escaped_text = text.replace('"', '`"').replace("'", "''")
    ps_cmd = (
        f"Add-Type -AssemblyName System.Speech; "
        f"$synth = New-Object System.Speech.Synthesis.SpeechSynthesizer; "
        f"$synth.SelectVoice('Microsoft David Desktop'); "
        f"$synth.Rate = 0; "
        f"$synth.SetOutputToWaveFile('{str(out_wav)}'); "
        f"$synth.Speak('{escaped_text}'); "
        f"$synth.Dispose()"
    )
    cmd = ["powershell", "-NoProfile", "-Command", ps_cmd]
    subprocess.run(cmd, check=True)


def build_full_audio():
    print("Synthesizing voice clips...")
    full_audio = AudioSegment.silent(duration=270000, frame_rate=48000)
    # Ensure 16-bit 48kHz stereo
    full_audio = full_audio.set_channels(2).set_sample_width(2)

    for item in SCENES:
        cid = item["id"]
        raw_wav = CLIPS_DIR / f"{cid}.wav"
        print(f"  Rendering [{cid}] at {item['offset_ms']} ms: {item['text'][:40]}...")
        synthesize_clip(cid, item["text"], raw_wav)

        clip_audio = AudioSegment.from_wav(str(raw_wav))
        clip_audio = clip_audio.set_frame_rate(48000).set_channels(2).set_sample_width(2)
        
        offset = item["offset_ms"]
        duration = len(clip_audio)
        print(f"    Duration: {duration} ms (ends at {offset + duration} ms)")
        full_audio = full_audio.overlay(clip_audio, position=offset)

    raw_voice_path = OUT_DIR / "voice_raw.wav"
    norm_voice_path = OUT_DIR / "voice_norm.wav"
    full_audio.export(str(raw_voice_path), format="wav")
    print(f"Exported raw voice track: {raw_voice_path}")

    # Loudness normalization to -16 LUFS broadcast standard
    print("Normalizing audio loudness to -16 LUFS...")
    cmd_norm = [
        "ffmpeg", "-y",
        "-i", str(raw_voice_path),
        "-af", "loudnorm=I=-16:TP=-1.5:LRA=11",
        "-ar", "48000",
        "-c:a", "pcm_s16le",
        str(norm_voice_path),
    ]
    subprocess.run(cmd_norm, check=True)
    print(f"Exported normalized voice track: {norm_voice_path}")
    return norm_voice_path


def mux_video_with_audio(norm_voice_path: Path):
    silent_video = OUT_DIR / "demo_silent.mp4"
    final_video = OUT_DIR / "final_submission_with_voice.mp4"

    print("Muxing normalized audio with silent video...")
    cmd_mux = [
        "ffmpeg", "-y",
        "-i", str(silent_video),
        "-i", str(norm_voice_path),
        "-c:v", "copy",
        "-c:a", "aac",
        "-b:a", "192k",
        "-t", "00:04:30.00",
        str(final_video),
    ]
    subprocess.run(cmd_mux, check=True)
    print(f"Successfully generated final submission video: {final_video}")

    # Verify duration & streams
    cmd_probe = [
        "ffprobe", "-v", "error",
        "-show_entries", "format=duration,size,bit_rate",
        "-show_streams",
        str(final_video),
    ]
    res = subprocess.run(cmd_probe, capture_output=True, text=True)
    print("FFprobe Verification:")
    print(res.stdout)


if __name__ == "__main__":
    norm_audio = build_full_audio()
    mux_video_with_audio(norm_audio)
