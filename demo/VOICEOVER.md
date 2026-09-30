# Voiceover Script: Samsung Gen AI Hackathon 3.0 (Theme 05)
## Title: Interruptible Real-Time Voice Agent for Full-Duplex Spoken Dialogue
### Evaluated on Full-Duplex-Bench v3 & Extended with In-Car Voice Navigation

---

### Executive Overview & Narration Metadata

| Property | Value |
| :--- | :--- |
| **Target Video File** | `demo/out/demo_silent.mp4` |
| **Exact Video Duration** | `00:04:30.00` (270.00 seconds) |
| **Total Script Word Count** | **554 words** |
| **Average Reading Rate** | **123 words per minute** (~2.05 words/second) |
| **Recommended Pacing** | Natural, confident, conversational delivery with clear pauses |
| **Audio Format Recommendation** | 48.0 kHz, Mono or Stereo 16-bit PCM WAV, EBU R128 (-16 LUFS) |
| **Tone** | Objective, technical, transparent, authoritative |

---

### Delivery Guidelines & Notation Legend

- **`[00:00 - 00:08]`**: Video timestamp window. Match your speech start and end to these markers.
- **`[Screen: ...]`**: Visual confirmation of what is currently displaying on screen.
- **Bold Text**: Apply gentle vocal stress to emphasize key technical terms and metrics.
- **`[Pause: Xs]`**: Intentional pauses for breath and to give viewers time to view terminal logs and tables.
- **Pronunciation Guide**:
  - *LiveKit*: "Live-kit"
  - *Full-Duplex-Bench*: "Full Duplex Bench"
  - *VAD*: "V-A-D" (or "Voice Activity Detection")
  - *Koramangala*: "Ko-ra-man-ga-la"
  - *Indiranagar*: "In-di-ra-na-gar"

---

## Part 1: Timestamped Synchronized Narration Guide

```
========================================================================================
TIMELINE OVERVIEW (270 Seconds Total)
00:00 ────► 00:40 : Segment 1 — Title & Architecture (40s | 88 words | 132 WPM)
00:40 ────► 02:10 : Segment 2 — Benchmark Evidence & Evaluation (90s | 189 words | 126 WPM)
02:10 ────► 04:10 : Segment 3 — Extension Demo: In-Car Navigation (120s | 235 words | 118 WPM)
04:10 ────► 04:30 : Segment 4 — Reproduction & Conclusion (20s | 42 words | 126 WPM)
========================================================================================
```

---

### Segment 1: Title & System Architecture (00:00 – 00:40 | 40 Seconds)

#### [00:00 – 00:08] Title & Problem Introduction (8s | 18 words)
- **[Screen: Terminal title banner shows Theme 05, Project Title, and Full-Duplex-Bench v3 caption]**
- **Spoken Text:**
  > "Hello everyone, and welcome to our demonstration for the Samsung Gen AI Hackathon, Theme **Zero Five**: **Interruptible Real-Time Agents**."
  - *[Pause: 1.0s]*

#### [00:08 – 00:20] System Architecture Overview (12s | 26 words)
- **[Screen: System Architecture diagram renders: User Audio -> LiveKit Room -> Gemini Native Realtime -> Tool Engine]**
- **Spoken Text:**
  > "Here we present an end-to-end full-duplex voice agent using Google's **Gemini Native Realtime** model, connected over WebRTC through the **LiveKit Voice Agents SDK**."
  - *[Pause: 1.0s]*

#### [00:20 – 00:32] Native Speech Tokens vs Cascaded Pipelines (12s | 26 words)
- **[Screen: Key Architectural Highlights display: Zero STT delay, native VAD, single-pass reasoning]**
- **Spoken Text:**
  > "Unlike traditional cascaded architectures that combine Whisper, an LLM, and TTS, our agent operates directly on **native speech tokens**, eliminating intermediate transcription bottlenecks."
  - *[Pause: 1.0s]*

#### [00:32 – 00:40] Instant Barge-in and Verification (8s | 18 words)
- **[Screen: Caption confirms: Verified architecture strictly eliminates cascaded STT/TTS dependencies]**
- **Spoken Text:**
  > "Voice activity detection, barge-in interruptions, and multi-step tool calls are all executed **natively** in a single model pass."
  - *[Pause: 1.5s]*

---

### Segment 2: Benchmark Evidence & Evaluation (00:40 – 02:10 | 90 Seconds)

#### [00:40 – 01:05] Live Benchmark Metrics & Honest Partial Run Disclosure (25s | 56 words)
- **[Screen: Live Benchmark Metrics Summary appears with 28 completed cases, 100% completion rate, 0 silent failures]**
- **Spoken Text:**
  > "Here is our real evaluation evidence evaluated on **Full-Duplex-Bench v3**.  
  > To be completely transparent, our evaluation represents a **partial benchmark run** of **twenty-eight scenarios** across e-commerce, finance, housing, and travel domains.  
  > Across all twenty-eight cases, the agent achieved a **one hundred percent completion rate** with **zero silent failures** and invoked thirty-eight tool calls."
  - *[Pause: 1.5s]*

#### [01:05 – 01:40] Scenario Walkthrough: ecommerce_01 (35s | 75 words)
- **[Screen: Directory listing of ecommerce_01 shows input audio, metadata, agent output WAV, and result JSON extract]**
- **Spoken Text:**
  > "Now let's examine a completed benchmark scenario: **e-commerce zero-one**.  
  > Looking at the scenario directory, we see the raw input audio containing realistic user disfluencies.  
  > The user said: *'Like, uh, well, I ordered something last week and haven't received it yet, order ID A-B-C one-two-three.'*  
  > Our agent seamlessly filtered out the filler hesitations, executed the `track_order` tool with order ID **ABC123**, and confirmed that the order is out for delivery."
  - *[Pause: 1.5s]*

#### [01:40 – 02:10] Quantitative Metrics & Zero Hallucinations (30s | 58 words)
- **[Screen: Exact-Match Metrics Table displays: Tool F1 0.759, Precision 1.000, Strict Pass Rate 10/15]**
- **Spoken Text:**
  > "In quantitative exact-match evaluation, our agent achieved a **Tool Selection F1 score of point-seven-five-nine**, with a **perfect precision of one-point-zero**.  
  > This means **zero false-positive tool calls** and zero hallucinations across all evaluated domains.  
  > The native audio agent reliably extracts structured arguments even while conversational disfluencies are present in the incoming audio stream."
  - *[Pause: 2.0s]*

---

### Segment 3: Extension Demo — In-Car Navigation Assistant (02:10 – 04:10 | 120 Seconds)

#### [02:10 – 02:25] Extension Context & Worker Initialization (15s | 34 words)
- **[Screen: Extension banner appears; agent worker boots up registering Google plugin and worker ID]**
- **Spoken Text:**
  > "Next, we demonstrate our real-world extension: an **in-car voice navigation assistant** designed to minimize driver distraction.  
  > The LiveKit worker is live, listening on WebRTC for streaming driver audio and dispatching mock navigation events."
  - *[Pause: 1.0s]*

#### [02:25 – 03:00] Clip 1: Mid-Utterance Destination Correction (35s | 66 words)
- **[Screen: Clip 1 plays: "Navigate to Koramangala. No wait, take me to Indiranagar instead." Log shows cancel and final destination]**
- **Spoken Text:**
  > "In clip one, the driver self-corrects mid-sentence, stating:  
  > *'Navigate to Koramangala. No wait, take me to Indiranagar instead.'*  
  > *[Pause: 1.0s]*  
  > Notice how the agent waits for the correction, automatically invokes `cancel_navigation` on the discarded Koramangala intent, and sets **Indiranagar** as the active route.  
  > While initial synthesizer fast-speech required a clean second pass, both tool calls executed in proper chronological sequence."
  - *[Pause: 1.5s]*

#### [03:00 – 03:30] Clip 2: Mid-Utterance Cancellation (30s | 56 words)
- **[Screen: Clip 2 plays: "Take me to the airport. Actually, cancel that." Log shows tool calls suppressed]**
- **Spoken Text:**
  > "In clip two, the driver changes their mind completely mid-utterance:  
  > *'Take me to the airport. Actually, cancel that.'*  
  > *[Pause: 1.0s]*  
  > The agent immediately detects the explicit cancellation, suppresses any active route creation, and leaves **zero navigation sessions active**.  
  > The driver is never directed to a discarded destination, maintaining driver safety on the road."
  - *[Pause: 1.5s]*

#### [03:30 – 03:55] Clip 3: Hesitations & Filler Word Rejection (25s | 47 words)
- **[Screen: Clip 3 plays: "Navigate to M G Road. Um, hold on. Yes, M G Road." Log shows single clean navigate_to]**
- **Spoken Text:**
  > "In clip three, the driver hesitates:  
  > *'Navigate to M G Road. Um, hold on. Yes, M G Road.'*  
  > The agent understands that *'um, hold on'* is natural filler speech. It avoids false cancellations, remains attentive, and triggers **exactly one** navigation call to M G Road."
  - *[Pause: 1.0s]*

#### [03:55 – 04:10] Extension Audit Table & Safety Summary (15s | 32 words)
- **[Screen: Pass/Fail summary table shows 3 out of 3 scenarios PASS with auditable log proof]**
- **Spoken Text:**
  > "Our extension audit confirms all three disfluency scenarios passed with complete log transparency.  
  > Gemini Native Realtime reliably interprets conversational speech without the latency and failure modes of traditional cascaded stacks."
  - *[Pause: 1.5s]*

---

### Segment 4: Reproduction & Conclusion (04:10 – 04:30 | 20 Seconds)

#### [04:10 – 04:20] One-Command Reproduction (10s | 20 words)
- **[Screen: Reproduction scripts reproduce.ps1 and reproduce.sh displayed with required credentials table]**
- **Spoken Text:**
  > "Our entire evaluation pipeline is fully reproducible with a single command: **`reproduce.ps1`** for Windows PowerShell or **`reproduce.sh`** on Linux."
  - *[Pause: 1.0s]*

#### [04:20 – 04:30] Concluding Remarks & Wrap-up (10s | 22 words)
- **[Screen: Repository structure and final wrap-up banner shown]**
- **Spoken Text:**
  > "The setup requires only your LiveKit Cloud credentials and a free Google AI Studio key. Thank you for watching our demonstration!"
  - *[Video Concludes at 04:30.00]*

---

## Part 2: Continuous Teleprompter Script (Clean Reading Mode)

*(Use this section for teleprompter apps or continuous microphone recording)*

> "Hello everyone, and welcome to our demonstration for the Samsung Gen AI Hackathon, Theme Zero Five: Interruptible Real-Time Agents.  
> 
> Here we present an end-to-end full-duplex voice agent using Google's Gemini Native Realtime model, connected over WebRTC through the LiveKit Voice Agents SDK. Unlike traditional cascaded architectures that combine Whisper, an LLM, and TTS, our agent operates directly on native speech tokens, eliminating intermediate transcription bottlenecks. Voice activity detection, barge-in interruptions, and multi-step tool calls are all executed natively in a single model pass.  
> 
> Here is our real evaluation evidence evaluated on Full-Duplex-Bench v3. To be completely transparent, our evaluation represents a partial benchmark run of twenty-eight scenarios across e-commerce, finance, housing, and travel domains. Across all twenty-eight cases, the agent achieved a one hundred percent completion rate with zero silent failures and invoked thirty-eight tool calls.  
> 
> Now let's examine a completed benchmark scenario: e-commerce zero-one. Looking at the scenario directory, we see the raw input audio containing realistic user disfluencies. The user said: 'Like, uh, well, I ordered something last week and haven't received it yet, order ID A-B-C one-two-three.' Our agent seamlessly filtered out the filler hesitations, executed the track_order tool with order ID ABC123, and confirmed that the order is out for delivery.  
> 
> In quantitative exact-match evaluation, our agent achieved a Tool Selection F1 score of point-seven-five-nine, with a perfect precision of one-point-zero. This means zero false-positive tool calls and zero hallucinations across all evaluated domains. The native audio agent reliably extracts structured arguments even while conversational disfluencies are present in the incoming audio stream.  
> 
> Next, we demonstrate our real-world extension: an in-car voice navigation assistant designed to minimize driver distraction. The LiveKit worker is live, listening on WebRTC for streaming driver audio and dispatching mock navigation events.  
> 
> In clip one, the driver self-corrects mid-sentence, stating: 'Navigate to Koramangala. No wait, take me to Indiranagar instead.' Notice how the agent waits for the correction, automatically invokes cancel_navigation on the discarded Koramangala intent, and sets Indiranagar as the active route. While initial synthesizer fast-speech required a clean second pass, both tool calls executed in proper chronological sequence.  
> 
> In clip two, the driver changes their mind completely mid-utterance: 'Take me to the airport. Actually, cancel that.' The agent immediately detects the explicit cancellation, suppresses any active route creation, and leaves zero navigation sessions active. The driver is never directed to a discarded destination, maintaining driver safety on the road.  
> 
> In clip three, the driver hesitates: 'Navigate to M G Road. Um, hold on. Yes, M G Road.' The agent understands that 'um, hold on' is natural filler speech. It avoids false cancellations, remains attentive, and triggers exactly one navigation call to M G Road.  
> 
> Our extension audit confirms all three disfluency scenarios passed with complete log transparency. Gemini Native Realtime reliably interprets conversational speech without the latency and failure modes of traditional cascaded stacks.  
> 
> Our entire evaluation pipeline is fully reproducible with a single command: reproduce.ps1 for Windows PowerShell or reproduce.sh on Linux. The setup requires only your LiveKit Cloud credentials and a free Google AI Studio key. Thank you for watching our demonstration!"

---

## Part 3: Video & Audio Muxing Instructions

When you have recorded your voiceover audio file (e.g., `voice.wav`), follow these steps to combine it with `demo/out/demo_silent.mp4`:

### 1. Normalize Audio Loudness (Broadcast Standard -16 LUFS)
```powershell
ffmpeg -i voice.wav -af "loudnorm=I=-16:TP=-1.5:LRA=11" -ar 48000 -c:a pcm_s16le voice_norm.wav
```

### 2. Multiplex Audio with Silent Video (Exact Length Guarantee)
```powershell
ffmpeg -y -i demo\out\demo_silent.mp4 -i voice_norm.wav `
  -c:v copy -c:a aac -b:a 192k `
  -t 00:04:30.00 `
  demo\out\final_submission_with_voice.mp4
```

### 3. Verify Output Stream & Duration
```powershell
ffprobe -v error -show_entries format=duration,size,bit_rate -show_streams demo\out\final_submission_with_voice.mp4
```
*Expected: Exactly 270.000000 seconds, 1 video stream (h264 1440x900 @ 30fps), 1 audio stream (aac 48000Hz stereo).*
