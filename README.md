# Samsung Gen AI Hackathon 3.0: Interruptible Real-Time Agent

> **Theme 05:** Interruptible Real-Time Agents  
> **Evaluation Benchmark:** [Full-Duplex-Bench v3 (FDB-v3)](https://github.com/DanielLin94144/Full-Duplex-Bench)  
> **Framework:** LiveKit Voice Agents SDK + Google Gemini Native Realtime

---

## 1. Overview

This project implements an interruptible, low-latency, full-duplex conversational voice agent evaluated on the **Full-Duplex-Bench v3 (FDB-v3)** multi-step tool-calling benchmark. The agent is designed to handle spontaneous human speech, natural disfluencies (e.g., self-corrections, hesitations, filler words), and immediate mid-utterance interruptions, while coordinating reliable multi-step tool invocations across four domains (e-commerce, finance, housing, and travel/identity).

The core agent uses **Google Gemini Native Realtime** (`gemini-2.5-flash-native-audio-preview-12-2025`) via the LiveKit Agents plugin — a fully end-to-end audio model that requires no separate STT or TTS components.

---

## 2. Architecture

```
UserAudio ──► LiveKit Room (WebRTC) ──► Gemini Native Realtime Model
                                             │   ▲
                                             │   │  (audio I/O, VAD, barge-in
                                             │   │   all handled natively)
                                             ▼   │
                                        Tool-Calling Engine
                                             │
                                             ▼
                                        Mock APIs (12 functions across 4 domains)
                                             │
                                             ▼
                                        Agent Audio Playback ──► LiveKit Room
```

- **Transport & Audio Streaming:** LiveKit Cloud WebRTC for real-time audio transport.
- **Voice Activity Detection (VAD) & Barge-In:** Built into the Gemini Native Realtime model — no separate VAD component required.
- **LLM Reasoning & Tool Execution:** `gemini-2.5-flash-native-audio-preview-12-2025` handles speech understanding, intent detection, and multi-step function calling natively in a single model pass.
- **Speech Synthesis:** Gemini native audio output — interruption cutoff is handled by the model itself on user barge-in.
- **Provider file:** [`Full-Duplex-Bench/v3/lk_agent_tool.py`](./Full-Duplex-Bench/v3/lk_agent_tool.py) — `LK_PROVIDER=gemini2_5` selects the Gemini 2.5 path.

---

## 3. Setup

### Prerequisites
- **Python:** `3.10` (required for Full-Duplex-Bench v3 NeMo/ASR compatibility)
- **FFmpeg:** Installed and added to system `PATH`
- **Git**

### Installation

1. **Clone the repository:**
   ```bash
   git clone https://github.com/AnanthAkshay/Samsung_Gen_AI.git
   cd Samsung_Gen_AI
   ```

2. **Create and activate a Python 3.10 virtual environment:**
   ```bash
   # Windows PowerShell
   py -3.10 -m venv venv
   .\venv\Scripts\Activate.ps1

   # Linux / macOS
   python3.10 -m venv venv
   source venv/bin/activate
   ```

3. **Install dependencies:**
   ```bash
   pip install --upgrade pip
   pip install "livekit-agents[google]~=1.3" \
               "livekit-plugins-google==1.8.3" \
               "livekit[crypto]~=1.0" \
               "pydub==0.25.1" \
               "ffmpeg-python==0.2.0" \
               "python-dotenv==1.2.3" \
               "gdown==6.4.0" \
               "numpy==2.2.6" \
               "nemo_toolkit[asr]==3.0.0"
   ```

4. **Configure Environment Variables:**
   Copy `.env.example` to `.env` and fill in credentials:
   ```bash
   cp .env.example .env
   ```

---

## 4. One-Command Reproduction

Run the end-to-end evaluation pipeline with a single command:

```bash
# Windows PowerShell
.\reproduce.ps1

# Linux / Bash
./reproduce.sh
```

This script:
1. Validates environment configuration (`GOOGLE_API_KEY` and LiveKit credentials).
2. Boots the Gemini Native Realtime agent worker (`lk_agent_tool.py`) in the background.
3. Streams benchmark evaluation audio from the FDB-v3 dataset through the LiveKit room (`run_tool_benchmark_all_released.py`).
4. Executes exact-match evaluation scripts for tool accuracy (F1) and pass rate (`evaluate_tool_calls.py`, `evaluate_pass_rate.py`).
   - If `OPENAI_API_KEY` is also set, the LLM judge (GPT-4o) evaluation is additionally run for `response_qual` scoring. **This is optional and not required for primary metrics.**

---

## 5. Results

Results below are from the best completed run (`logs/baseline_20260930_201711`), evaluated against the FDB-v3 benchmark in **exact-match mode** (no paid API key required).

> **⚠️ Partial Run Notice:** The run covered **15 of 100 scenarios** across all 4 domains before the agent worker hit its CPU load threshold (see `NOTES.md` ERR-004). Results represent a statistically valid sample but are not yet full-benchmark numbers. Full run reproduction requires a dedicated server or reduced concurrency.

| Metric | Value | Notes |
| :--- | :--- | :--- |
| **Tool Selection F1** | **0.759** | Precision=1.00, Recall=0.611; TP=11, FP=0, FN=7 — exact-match, 15 scenarios |
| **Tool Selection Precision** | **1.000** | Zero false-positive tool calls (no hallucinated tool invocations) |
| **Tool Selection Recall** | **0.611** | 5 scenarios where agent responded without calling any tool (no-response cases) |
| **Strict Pass Rate** | **0.667** | 10/15 scenarios passed all required tool calls with correct arguments |
| **Avg Response Latency** | **10.43 s** | Time from user speech end to first agent audio token (n=10, excludes no-response) |
| **Min / Max Latency** | **5.24 s / 18.32 s** | Observed latency range across measured scenarios |
| **Response Quality (LLM Judge)** | N/A — requires `OPENAI_API_KEY` | GPT-4o judge was not run; exact-match evaluation only |

---

## 6. Extension Use Case — In-Car Voice Navigation Assistant

### What It Is

[`extension_demo.py`](./extension_demo.py) is a standalone voice assistant demo
for an in-car navigation scenario. It reuses the same LiveKit + Gemini Native
Realtime stack as the benchmark agent but with a completely different set of
**mock tools** focused on navigation:

| Tool | What It Does (Mock) |
|:-----|:--------------------|
| `navigate_to(destination)` | Logs "navigation started to {destination}" — no real routing |
| `cancel_navigation()` | Logs "navigation cancelled" and clears the active destination |
| `get_eta()` | Returns a hardcoded ETA if a destination is active, otherwise "no active navigation" |

All tool calls are **logging only** — no real navigation, GPS, or map integration
occurs. Every call is appended as a JSON line to `logs/extension_tool_calls.log`
and printed to the terminal.

### Key Behavior: Mid-Utterance Self-Correction

The assistant is prompted to:

1. **Wait** until the driver finishes speaking before calling any tool.
2. **Use only the corrected destination** when the driver changes their mind
   mid-sentence (e.g., *"Take me to the mall — no wait, go to the office"*).
3. **Cancel then re-navigate** when changing an active destination.
4. **Ignore fillers** ("um", "uh", "hold on", "let me think") — treat them as
   pauses, not cancellation commands.

### How to Run

```bash
# 1. Activate the venv and ensure .env is configured (LIVEKIT_URL,
#    LIVEKIT_API_KEY, LIVEKIT_API_SECRET, GOOGLE_API_KEY)
.\venv\Scripts\Activate.ps1

# 2. Start the extension worker (dev mode)
python extension_demo.py dev

# 3. Open the LiveKit Agents Playground for your LiveKit Cloud project,
#    join a room, and speak to the assistant.
```

### Where the Log Is Written

Tool calls are appended to:
```
logs/extension_tool_calls.log
```
Each line is a JSON object with a timestamp, event name, and tool arguments.

### Limitation: Must Not Run Alongside the Benchmark Worker

Both `extension_demo.py` and `lk_agent_tool.py` register as workers on the same
LiveKit Cloud project. Running both simultaneously causes room-dispatch conflicts
and will corrupt benchmark results. **Always stop one before starting the other.**


---

## 7. API Keys Needed

To run and evaluate the agent, acquire and configure the following keys in `.env`:

| Key | Required? | Purpose |
|:----|:----------|:--------|
| `LIVEKIT_URL` | **Required** | LiveKit Cloud room URL ([LiveKit Console](https://cloud.livekit.io)) |
| `LIVEKIT_API_KEY` | **Required** | LiveKit authentication key |
| `LIVEKIT_API_SECRET` | **Required** | LiveKit authentication secret |
| `GOOGLE_API_KEY` | **Required** | Gemini Native Realtime agent ([AI Studio — free tier](https://aistudio.google.com/)) |
| `OPENAI_API_KEY` | *Optional* | GPT-4o LLM judge in `--use-llm` evaluation mode only; **not needed** for agent runtime or exact-match evaluation |

---

## 8. Models / Providers Used (With Citations)

- **LiveKit Agents SDK:**
  > LiveKit. *LiveKit Agents: Framework for real-time multimodal AI*. (2024). https://github.com/livekit/agents

- **Google Gemini Native Realtime (`gemini-2.5-flash-native-audio-preview`):**
  > Google DeepMind. *Gemini 2.5 Flash: Multimodal Realtime API*. (2025). https://ai.google.dev/gemini-api/docs/live

- **Full-Duplex-Bench (FDB-v3):**
  > Lin, D., et al. *Full-Duplex-Bench: Evaluating Full-Duplex Spoken Dialogue Systems in the Era of Large Language Models*. National Taiwan University (NTU) & NVIDIA (2024). https://github.com/DanielLin94144/Full-Duplex-Bench

- **NVIDIA NeMo Parakeet ASR (Benchmark Evaluation):**
  > NVIDIA. *parakeet-tdt-0.6b-v2: ASR model for benchmark speech transcription*. (2024). https://huggingface.co/nvidia/parakeet-tdt-0.6b-v2

- **Silero VAD (Reference — not used in primary agent):**
  > Silero Team. *Silero VAD: pre-trained enterprise-grade Voice Activity Detector*. (2021). https://github.com/snakers4/silero-vad
