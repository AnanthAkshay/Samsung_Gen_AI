# Interruptible Real-Time Voice Agent — Samsung Gen AI Hackathon 3.0

> **Theme 05 — Interruptible Real-Time Agents**
> **Benchmark:** [Full-Duplex-Bench v3 (FDB-v3)](https://github.com/DanielLin94144/Full-Duplex-Bench) — multi-step tool calling under real-world speech disfluency
> **Stack:** LiveKit Voice Agents SDK · Google Gemini 2.5 Flash Native Audio (end-to-end speech model)
> **Team:** MSRIT_Cache_Me · [AI usage disclosure](DISCLOSURE.md)

A low-latency, full-duplex conversational voice agent that understands spontaneous human speech — hesitations, filler words, self-corrections — supports immediate mid-utterance barge-in, and reliably executes **multi-step tool calls** across four domains, all natively handled by a single realtime audio model.

---

## Table of Contents

1. [Why This Project](#1-why-this-project)
2. [Architecture](#2-architecture)
3. [Repository Layout](#3-repository-layout)
4. [Benchmark & Evaluation Methodology](#4-benchmark--evaluation-methodology)
5. [Results](#5-results)
6. [Extension Demo — In-Car Voice Navigation Assistant](#6-extension-demo--in-car-voice-navigation-assistant)
7. [Setup](#7-setup)
8. [One-Command Reproduction](#8-one-command-reproduction)
9. [Manual Pipeline Walkthrough](#9-manual-pipeline-walkthrough)
10. [Configuration & API Keys](#10-configuration--api-keys)
11. [Models & Providers (Citations)](#11-models--providers-citations)
12. [Known Issues & Troubleshooting](#12-known-issues--troubleshooting)

---

## 1. Why This Project

Real conversations are messy. Speakers pause mid-sentence, say "um", change their mind ("book to the mall — no wait, the office"), and interrupt the agent before it finishes. FDB-v3 measures exactly this: can a voice agent wait for the right moment, ignore disfluencies, and still fire the correct sequence of tool calls with correct arguments?

This submission answers with a **fully native approach**: instead of a cascaded STT → LLM → TTS pipeline (which serializes speech through rigid text transcripts and adds latency at every stage), a single end-to-end audio model — **Gemini 2.5 Flash Native Audio** — handles speech understanding, turn-taking, interruption, intent detection, function calling, and spoken responses in one model pass.

| Design decision | Rationale |
|:---|:---|
| Native realtime (Gemini Live) over cascaded pipeline | ~4.25 s vs ~10.12 s published latency; zero paid API keys for agent runtime; native disfluency handling (see [NOTES.md](NOTES.md) ARCH-001) |
| LiveKit Cloud WebRTC transport | Production-grade real-time audio, free tier, built-in room dispatch |
| Exact-match evaluation (no LLM judge) | Reported metrics reproducible **without any paid API key** |
| Mock tool backends | Deterministic, auditable tool behavior with configurable latency profiles |

---

## 2. Architecture

```
 User Audio (WebRTC)
        │
        ▼
 LiveKit Room ◄────────────── LiveKit Cloud (transport + dispatch)
        │
        ▼
 Gemini 2.5 Flash Native Audio          ── end-to-end: no separate STT / LLM / TTS
        │   • VAD & turn-taking (native)
        │   • Barge-in & interruption cutoff (native)
        │   • Intent detection & multi-step reasoning (native)
        ▼
 Tool-Calling Engine (LiveKit function_tool)
        │
        ▼
 MockAPIRegistry — 12 tools across 4 domains   ──  latency_injector.py simulates API latency
        │
        ▼
 Agent audio reply ──► LiveKit Room ──► User
```

**Key point:** VAD, barge-in handling, and interruption of spoken output are *native model capabilities* here — there is no separate VAD component, no intermediate text transcription, and no TTS stage to coordinate.

### Primary components

| Component | File | Role |
|:---|:---|:---|
| Agent worker | [`Full-Duplex-Bench/v3/lk_agent_tool.py`](Full-Duplex-Bench/v3/lk_agent_tool.py) | LiveKit agent with swappable realtime providers (`LK_PROVIDER=gemini2_5` selects Gemini); per-call latency breakdown logging |
| Tool backends | [`Full-Duplex-Bench/v3/mock_apis.py`](Full-Duplex-Bench/v3/mock_apis.py) | 12 deterministic mock tools across 4 domains, with a call logger |
| Latency simulation | [`Full-Duplex-Bench/v3/latency_injector.py`](Full-Duplex-Bench/v3/latency_injector.py) | Configurable per-tool API latency profiles (e.g. `instant`) |
| Benchmark runner | [`Full-Duplex-Bench/v3/run_tool_benchmark_all_released.py`](Full-Duplex-Bench/v3/run_tool_benchmark_all_released.py) | Streams each benchmark WAV through a LiveKit room, captures agent audio, records tool calls |
| LiveKit client | [`Full-Duplex-Bench/v3/livekit_inference.py`](Full-Duplex-Bench/v3/livekit_inference.py) | Headless LiveKit client for streaming benchmark audio |
| ASR (evaluation only) | NVIDIA Parakeet TDT 0.6B v2 via [`run_tool_benchmark.py`](Full-Duplex-Bench/v3/run_tool_benchmark.py) | Transcribes agent responses for latency measurement and tool-call extraction — **not part of the agent runtime** |
| Evaluators | [`evaluate_tool_calls.py`](Full-Duplex-Bench/v3/evaluate_tool_calls.py), [`evaluate_pass_rate.py`](Full-Duplex-Bench/v3/evaluate_pass_rate.py), [`analyze_tool_latency.py`](Full-Duplex-Bench/v3/analyze_tool_latency.py) | F1 / pass-rate / latency scoring; exact-match by default, optional GPT-4o judge via `--use-llm` |
| Cascaded baseline | [`Full-Duplex-Bench/v3/cascaded_agent.py`](Full-Duplex-Bench/v3/cascaded_agent.py) | Kept for comparison: Silero VAD + Whisper STT + GPT-4o + OpenAI TTS |
| Extension demo | [`extension_demo.py`](extension_demo.py) | Standalone in-car navigation assistant (see §6) |
| Reproduction scripts | [`reproduce.sh`](reproduce.sh) / [`reproduce.ps1`](reproduce.ps1) | One-command end-to-end pipeline (Linux/macOS / Windows) |

---

## 3. Repository Layout

```
.
├── README.md                        ← you are here
├── DISCLOSURE.md                    AI tools & models usage disclosure (required by hackathon)
├── NOTES.md                         Error log: root causes & resolutions for every blocker hit
├── extension_demo.py                In-car navigation extension demo (standalone worker)
├── reproduce.sh / reproduce.ps1     One-command end-to-end reproduction
├── .env.example                     Environment variable template
├── tests/
│   └── test_extension_tools.py      Offline unit tests for extension tool logic
├── logs/                            Evaluation outputs & run artifacts (gitignored except summary)
│   └── gemini2_5_summary_metrics.json   Best completed run's summary metrics
└── Full-Duplex-Bench/               Vendored FDB benchmark (v1/v1.5, v2, v3)
    └── v3/                          Active benchmark version — all pipeline code lives here
        ├── lk_agent_tool.py             Agent worker (swappable realtime providers)
        ├── cascaded_agent.py            Cascaded baseline (STT + LLM + TTS)
        ├── mock_apis.py                 12 mock tools across 4 domains
        ├── latency_injector.py          Simulated API latency
        ├── livekit_inference.py         Headless LiveKit audio streaming client
        ├── run_tool_benchmark.py        Core inference helpers (ASR, LiveKit, latency)
        ├── run_tool_benchmark_all_released.py   Batch inference over all scenarios
        ├── evaluate_tool_calls.py       Tool selection F1 / argument accuracy
        ├── evaluate_pass_rate.py        Strict binary pass rate
        ├── analyze_tool_latency.py      Fine-grained latency analysis
        ├── benchmark_data_v2.json       Scenario definitions (79 scenarios)
        └── fdb_v3_data_released/        Benchmark audio (downloaded — see §7)
```

---

## 4. Benchmark & Evaluation Methodology

### The benchmark

FDB-v3 evaluates voice agents on **multi-step tool calling under real-world disfluency**:

- **100 examples** — 79 unique scenarios, 12 human speakers
- **4 domains** — e-commerce support, finance & billing, housing & location, travel & identity
- **3 difficulty levels** — easy (1 tool call), medium (2), hard (3)
- **Human-recorded audio** with natural hesitations, filler words, and mid-utterance self-corrections
- **12 available tools** the agent may call:

| Domain | Tools |
|:---|:---|
| Travel & Identity | `search_flights`, `book_flight`, `update_identity_doc` |
| Finance & Billing | `get_card_benefits`, `get_exchange_rate`, `modify_autopay` |
| Housing & Location | `search_apartments`, `calculate_commute`, `update_search_filter` |
| E-Commerce | `track_order`, `search_products`, `add_to_cart` |

### How a scenario is run

1. The benchmark runner opens a fresh LiveKit room per scenario.
2. The scenario's input WAV (human speech, 48 kHz) is streamed into the room.
3. The agent listens, decides on tool calls, executes them against the mock backend, and replies with audio.
4. The agent's spoken response is captured and transcribed with Parakeet ASR (evaluation only).
5. Tool calls are extracted from the agent's logs and compared against ground truth.

### Metrics

| Metric | What it measures |
|:---|:---|
| **Tool Selection F1** | Harmonic mean of precision (no hallucinated calls) and recall (no missed calls) over expected tool names |
| **Argument Accuracy** | Correctness of arguments — exact string match by default; semantic via optional GPT-4o judge |
| **Strict Pass Rate** | Scenario passes only if **all** expected tools were called with correct arguments (no missing, extra, or wrong) |
| **Response Quality** | Optional GPT-4o judge score (`--use-llm` only; requires `OPENAI_API_KEY`) |
| **Latency** | Time from end of user speech to agent's first audio token; plus tool-call and task-completion latency |

### Integrity guarantees

- No benchmark scenario IDs, dialogue text, or expected answers are hardcoded into agent prompts, tool definitions, or mock backends ([DISCLOSURE.md §8.3](DISCLOSURE.md)).
- The Gemini model is used **zero-shot** — no fine-tuning on benchmark data.
- Parakeet ASR is used **only for evaluation transcription**, never during agent inference.

---

## 5. Results

> **⚠️ Partial run — 15 of 100 scenarios.** The best completed run (`logs/baseline_20260930_201711`) covered 15 scenarios across all 4 domains before the local agent worker hit its CPU load threshold (see [NOTES.md](NOTES.md) ERR-004). These are statistically valid sample numbers, not full-benchmark results; a full run needs a dedicated machine or reduced concurrency.

**Model:** `gemini-2.5-flash-native-audio-preview-12-2025` · **Evaluation:** exact-match (no paid API keys)

| Metric | Value | Detail |
|:---|:---|:---|
| **Strict Pass Rate** | **0.667** | 10 / 15 scenarios passed with all required tool calls and correct arguments |
| **Tool Selection F1** | **0.759** | TP = 11, FP = 0, FN = 7 |
| **Tool Selection Precision** | **1.000** | Zero hallucinated tool calls across all 15 scenarios |
| **Tool Selection Recall** | **0.611** | All 5 failures were *no-response* cases (agent answered without calling any tool) |
| **Avg Response Latency** | **10.43 s** | User speech end → first agent audio token (n = 10, excludes no-response) |
| **Latency Range** | 5.24 s – 18.32 s | Observed min / max across measured scenarios |
| **Response Quality (LLM judge)** | not computed | Requires `OPENAI_API_KEY`; exact-match evaluation only |

**Failure analysis:** every failed scenario was a *no-response* — the agent produced a spoken answer but invoked no tool (all in the e-commerce domain, all affecting `search_products` / `add_to_cart` / `track_order`). Full details in `logs/gemini2_5_summary_metrics.json`. The standout signal is **perfect precision**: the agent never hallucinated a tool call, even under heavy disfluency.

---

## 6. Extension Demo — In-Car Voice Navigation Assistant

[`extension_demo.py`](extension_demo.py) demonstrates the same LiveKit + Gemini Native Realtime stack applied to a different domain: a driver-facing navigation assistant whose headline behavior is **mid-utterance destination correction** — *"Take me to the mall — no wait, go to the office"* must end up navigating to the office, and only the office.

### Tools (all mock — logging only, no real GPS or routing)

| Tool | Behavior |
|:---|:---|
| `navigate_to(destination)` | Records the destination as active |
| `cancel_navigation()` | Clears the active destination |
| `get_eta()` | Returns an ETA if navigation is active, otherwise "no active navigation" |

### Prompted behaviors

1. **Wait for the full sentence** before calling any tool — never act on partial input.
2. **Honor mid-sentence corrections** — use only the final corrected destination; never mention the discarded one.
3. **Cancel-then-renavigate** when the driver changes an active destination.
4. **Ignore fillers** ("um", "uh", "hold on", "let me think") — a hesitation is a pause, not a cancellation command.

### Running the demo

```bash
# 1. Activate the venv and ensure .env has LiveKit + GOOGLE_API_KEY credentials
.\venv\Scripts\Activate.ps1        # Windows
source venv/bin/activate           # Linux / macOS

# 2. Start the extension worker in dev mode
python extension_demo.py dev

# 3. Open the LiveKit Agents Playground (cloud.livekit.io), join a room, and speak
```

Every tool call is appended as a JSON line to `logs/extension_tool_calls.log` (also printed to the terminal), making each interaction auditable:

```json
{"t": 1759200000.0, "event": "navigate_to", "destination": "office"}
{"t": 1759200005.0, "event": "cancel_navigation", "was": "office"}
```

### Tests

Offline unit tests verify the tool logic (log event sequence, cancel behavior) without LiveKit or network:

```bash
python tests/test_extension_tools.py
```

### ⚠️ Do not run alongside the benchmark worker

`extension_demo.py` and `lk_agent_tool.py` both register as workers on the same LiveKit Cloud project. Running both simultaneously causes room-dispatch conflicts and corrupts benchmark results. **Always stop one before starting the other.**

---

## 7. Setup

### Prerequisites

| Requirement | Notes |
|:---|:---|
| **Python 3.10** | Required for Full-Duplex-Bench v3 NeMo/ASR compatibility |
| **FFmpeg** | On `PATH`; used to transcode audio to 48 kHz mono 16-bit PCM |
| **LiveKit Cloud account** | Free tier at [cloud.livekit.io](https://cloud.livekit.io) |
| **Google AI Studio key** | Free tier at [aistudio.google.com](https://aistudio.google.com) |

### Installation

```bash
# 1. Clone
git clone https://github.com/AnanthAkshay/Samsung_Gen_AI.git
cd Samsung_Gen_AI

# 2. Create and activate a Python 3.10 virtual environment
#    Windows PowerShell:
py -3.10 -m venv venv
.\venv\Scripts\Activate.ps1
#    Linux / macOS:
python3.10 -m venv venv
source venv/bin/activate

# 3. Install pinned dependencies
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

# 4. Configure environment (see §10)
cp .env.example .env
#    ... then edit .env with your credentials
```

The benchmark audio dataset (`fdb_v3_data_released/`, ~100 WAV files) is downloaded automatically by the reproduction scripts; or fetch it manually from [Google Drive](https://drive.google.com/file/d/1SO_4MTazWQ_jvCx0dtmpQ-t40bdd07yz/view?usp=sharing) and extract into `Full-Duplex-Bench/v3/`.

---

## 8. One-Command Reproduction

```bash
# Windows PowerShell
.\reproduce.ps1

# Linux / macOS / Bash
./reproduce.sh
```

The script performs the full pipeline, in order:

1. **Environment validation** — checks `GOOGLE_API_KEY` and all three LiveKit credentials, fails fast with clear messages if missing.
2. **Venv + dependencies** — creates/activates a Python 3.10 venv and installs the pinned package set.
3. **Dataset check** — downloads and extracts the benchmark audio from Google Drive if absent.
4. **Agent worker** — boots the Gemini Native Realtime agent (`lk_agent_tool.py`, `LK_PROVIDER=gemini2_5`) in the background with cleanup on exit.
5. **Batch inference** — streams all benchmark scenarios through LiveKit rooms (`run_tool_benchmark_all_released.py`).
6. **Evaluation** — runs exact-match tool-accuracy (F1) and pass-rate scoring; if `OPENAI_API_KEY` is set, the optional GPT-4o LLM-judge pass for `response_qual` is added automatically (not required for primary metrics).

Results land in `logs/` as timestamped JSON reports.

---

## 9. Manual Pipeline Walkthrough

Prefer to run each stage yourself (three terminals):

```bash
cd Full-Duplex-Bench/v3

# Terminal 1 — start the agent worker
LK_PROVIDER=gemini2_5 python lk_agent_tool.py start
#   or: python lk_agent_tool.py dev        (auto-dispatch on room join)
#   or: python lk_agent_tool.py console    (local mic/speaker, no LiveKit Cloud)

# Terminal 2 — batch inference over all scenarios
python run_tool_benchmark_all_released.py --provider gemini2_5
#   --force       overwrite existing results
#   --asr-only    skip inference, only transcribe existing agent audio

# Terminal 3 — evaluation (stop the agent first)
python evaluate_tool_calls.py \
    --benchmark benchmark_data_v2.json \
    --results-dir fdb_v3_data_released \
    --provider gemini2_5 \
    --output ../logs/gemini2_5_eval.json
    # add --use-llm for the optional GPT-4o judge

python evaluate_pass_rate.py \
    --benchmark benchmark_data_v2.json \
    --results-dir fdb_v3_data_released \
    --provider gemini2_5 \
    --output ../logs/gemini2_5_pass_rate.json

python analyze_tool_latency.py \
    --results-dir fdb_v3_data_released \
    --provider gemini2_5
```

The agent worker supports multiple providers via `LK_PROVIDER` (`gemini2_5`, `gemini3_1`, `gpt_realtime`, `azure_openai`, `grok`, `ultravox`, or `cascaded` via `cascaded_agent.py`) — useful for A/B comparisons against the benchmark's other baseline agents.

---

## 10. Configuration & API Keys

Copy [`.env.example`](.env.example) → `.env` (the scripts also accept `Full-Duplex-Bench/v3/.env.local`):

| Variable | Required | Purpose |
|:---|:---:|:---|
| `LIVEKIT_URL` | ✅ | LiveKit Cloud room URL ([console](https://cloud.livekit.io)) |
| `LIVEKIT_API_KEY` | ✅ | LiveKit auth key |
| `LIVEKIT_API_SECRET` | ✅ | LiveKit auth secret |
| `GOOGLE_API_KEY` | ✅ | Gemini Native Realtime agent ([AI Studio free tier](https://aistudio.google.com)) |
| `LK_PROVIDER` | ✅ | Agent backend: `gemini2_5` (default) or `gemini3_1` |
| `GOOGLE_VOICE` | – | Voice name (default `Puck`; also `Charon`, `Kore`, `Fenrir`, `Aoede`) |
| `OPENAI_API_KEY` | – | **Optional.** GPT-4o LLM judge, only with `--use-llm`; not needed for agent runtime or primary metrics |
| `EXT_VOICE` / `EXT_GEMINI_MODEL` | – | Override voice / model for `extension_demo.py` only |

**Cost profile:** the entire agent runtime *and* the reported evaluation run on free tiers — no paid API keys are required.

---

## 11. Models & Providers (Citations)

- **LiveKit Agents SDK**
  > LiveKit. *LiveKit Agents: Framework for real-time multimodal AI*. (2024). https://github.com/livekit/agents

- **Google Gemini Native Realtime** (`gemini-2.5-flash-native-audio-preview-12-2025`)
  > Google DeepMind. *Gemini 2.5 Flash: Multimodal Realtime API*. (2025). https://ai.google.dev/gemini-api/docs/live

- **Full-Duplex-Bench v3**
  > Lin, G.-T., Chen, C., Chen, Z., & Lee, H.-y. *Full-Duplex-Bench-v3: Benchmarking Tool Use for Full-Duplex Voice Agents Under Real-World Disfluency*. arXiv:2604.04847 (2026). https://github.com/DanielLin94144/Full-Duplex-Bench

- **NVIDIA Parakeet TDT 0.6B v2** (benchmark ASR only — not part of agent runtime)
  > NVIDIA. *parakeet-tdt-0.6b-v2*. (2024). https://huggingface.co/nvidia/parakeet-tdt-0.6b-v2

- **Silero VAD** (reference — used only in the cascaded baseline, not in the primary agent)
  > Silero Team. *Silero VAD*. (2021). https://github.com/snakers4/silero-vad

---

## 12. Known Issues & Troubleshooting

Development blockers and their resolutions are tracked in [NOTES.md](NOTES.md). Quick reference:

| Symptom | Fix |
|:---|:---|
| `ffmpeg is not recognized` / audio decode errors | Install FFmpeg and add its `bin` folder to `PATH` (NOTES.md ERR-001) |
| `FileNotFoundError: /tmp/agent_*.log` on Windows | Create `C:\tmp`, or run from an environment where `/tmp` resolves (ERR-002) |
| `UnicodeEncodeError: 'charmap' codec` on agent startup | Set `PYTHONUTF8=1` for agent and benchmark processes (ERR-006) |
| `TarFile.extract() got an unexpected keyword argument 'filter'` | Python 3.10 + NeMo: `pip install backports.tarfile==1.2.0` (ERR-005) |
| Worker stops accepting jobs mid-run (`full capacity` / load threshold) | Reduce concurrency or use a dedicated machine; check `load` vs `threshold` in agent logs (ERR-004) |
| Agent never joins the room | Ensure only **one** worker (benchmark or extension) is running per LiveKit project |

---

*Questions about AI usage, feature origins, or evaluation integrity? See [DISCLOSURE.md](DISCLOSURE.md).*
