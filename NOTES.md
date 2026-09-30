# Project Notes & Error Resolution Log

This document records technical issues, bugs, error traces, root cause analyses, and solutions encountered during development and benchmark evaluation for the **Samsung Gen AI Hackathon 3.0 (Theme 05: Interruptible Real-Time Agents)**.

---

## Error Resolution Template

````markdown
### [ERR-00X] <Short summary of error>

- **Timestamp:** YYYY-MM-DD HH:MM
- **Component:** (LiveKit Agent / WebRTC / STT / LLM / TTS / Benchmark / Environment)
- **Error Message / Trace:**
  ```text
  <paste exact error log or stack trace here>
  ```
````

- **Root Cause:**
  <explain why this happened>
- **Resolution:**
  <explain step-by-step fix applied>
- **Status:** Resolved / In Progress / Blocked

````

---

## Log Entries

### [ERR-001] Missing FFmpeg audio decoder on Windows
- **Timestamp:** 2026-09-24 22:37
- **Component:** Audio streaming / `livekit_inference.py`
- **Error Message / Trace:**
  ```text
  ffmpeg : The term 'ffmpeg' is not recognized as the name of a cmdlet, function, script file, or operable program.
  RuntimeError: ffmpeg is required. Install with: brew install ffmpeg
````

- **Root Cause:** FFmpeg executable was not pre-installed or present in Windows `PATH`. `livekit_inference.py` calls `ffmpeg` as a subprocess to transcode audio to 48kHz mono 16-bit PCM.
- **Resolution:** Installed `Gyan.FFmpeg` via `winget` and registered its binary folder (`...\ffmpeg-9.0.2-full_build\bin`) to user and process `PATH`.
- **Status:** Resolved

### [ERR-002] Hardcoded POSIX `/tmp` paths causing `FileNotFoundError` on Windows

- **Timestamp:** 2026-09-24 22:42
- **Component:** LiveKit Voice Agent / `cascaded_agent.py` & `lk_agent_tool.py`
- **Error Message / Trace:**
  ```text
  FileNotFoundError: [Errno 2] No such file or directory: '/tmp/agent_heartbeat.log'
  FileNotFoundError: [Errno 2] No such file or directory: '/tmp/agent_tool_calls.log'
  ```
- **Root Cause:** Both agent templates hardcode `/tmp/agent_heartbeat.log` and `/tmp/agent_tool_calls.log`. On Windows, Python interprets `/tmp/...` relative to `C:\tmp`, which does not exist by default.
- **Resolution:** Initialized `C:\tmp` directory to ensure logging succeeds on Windows without crashing agent worker runs.
- **Status:** Resolved

### [ERR-003] NeMo ASR Toolkit dependency resolution on Windows

- **Timestamp:** 2026-09-24 22:41
- **Component:** Benchmark ASR evaluation / `run_tool_benchmark.py`
- **Error Message / Trace:**
  Potential failure when importing `nemo.collections.asr` without compatible PyTorch and CUDA runtime bindings on Python 3.10.
- **Resolution:** Installed `nemo_toolkit[asr]` (3.0.0) alongside PyTorch (2.14.0) into the dedicated Python 3.10 virtual environment and verified clean import.
- **Status:** Resolved

### [ARCH-001] Switched from Cascaded (OpenAI) to Native Realtime (Google Gemini)

- **Timestamp:** 2026-09-25 18:54
- **Component:** Core Voice Agent Architecture / `lk_agent_tool.py`
- **Rationale & Benefits:**
  - Transitioned from the multi-stage cascaded pipeline (`cascaded_agent.py`: Whisper STT + GPT-4o + OpenAI TTS) to the native multimodal realtime agent (`lk_agent_tool.py`: `gemini2_5` / `gemini3_1`).
  - **Zero Cost:** Uses Google AI Studio free tier for Gemini Multimodal Live, removing all paid API dependencies for agent runtime.
  - **Latency Advantage:** Benchmark published latency drops from ~10.12s (Cascaded) to ~4.25s (Gemini Live).
  - **Native Disfluency Processing:** Audio is processed natively end-to-end rather than serialized through rigid intermediate text transcripts.
- **Actions Taken:**
  - Installed `livekit-plugins-google` (1.8.3) into `venv`.
  - Updated [.env.example](file:///a:/Samsung_2/.env.example) to strictly require only LiveKit Cloud and `GOOGLE_API_KEY`.
  - Created [`reproduce.sh`](file:///a:/Samsung_2/reproduce.sh) and [`reproduce.ps1`](file:///a:/Samsung_2/reproduce.ps1) targeting `LK_PROVIDER=gemini2_5`.
  - Clarified separation of agent execution from evaluation LLM judge (exact-match fallback enabled without OpenAI key).
- **Status:** Active

### [ERR-004] Gemini baseline worker unavailable during full run

- **Timestamp:** 2026-09-30 20:30
- **Component:** LiveKit Agent / Benchmark
- **Error Message / Trace:**
  ```text
  {"message": "job did not ack shutdown in time", "level": "ERROR", "name": "livekit.agents", "room": "eval-ce9d3e9d", "pid": 6056, "timestamp": "2026-09-30T14:43:11.374825+00:00"}
  {"message": "worker is at full capacity, marking as unavailable", "level": "INFO", "name": "livekit.agents", "load": 0.7338000000000025, "threshold": 0.7, "pid": 6056, "timestamp": "2026-09-30T15:00:02.542198+00:00"}
  VS Code reported: command completed with exit code 1. No fatal traceback or Google quota/API error was captured in agent-debug.log; Windows Application/System logs had no matching crash event.
  ```
- **Root Cause:** Confirmed cause of later silent results: the local worker was marked unavailable after effective load exceeded its 0.7 threshold. The precise cause of the worker command's exit code 1 is not established; LiveKit's source logs the shutdown-ack timeout but continues waiting, so that message alone does not explain the process exit.
- **Resolution:** Stopped only the active benchmark and its inference processes. Preserved all output files. Do not resume until the exit-code cause is captured and the worker-availability failure is addressed; future runs must reject silent results instead of marking them completed.
- **Status:** Blocked

### [ERR-005] Python 3.10 NeMo tarfile incompatibility

- **Timestamp:** 2026-09-30 20:03
- **Component:** Benchmark ASR / Environment
- **Error Message / Trace:**
  ```text
  TypeError: TarFile.extract() got an unexpected keyword argument 'filter'
  ```
- **Root Cause:** NeMo's safe extraction uses the `filter="data"` argument, which is unavailable in Python 3.10.11's standard-library tarfile API.
- **Resolution:** Installed `backports.tarfile==1.2.0` and made `load_asr_model()` use its `open()` implementation when the standard library lacks the filter parameter. Verified the NeMo ASR model restored successfully.
- **Status:** Resolved

### [ERR-006] Python console encoding prevented agent startup

- **Timestamp:** 2026-09-30 20:02
- **Component:** LiveKit Agent / Windows Environment
- **Error Message / Trace:**
  ```text
  UnicodeEncodeError: 'charmap' codec can't encode character '\U0001f527' in position 0
  ```
- **Root Cause:** The agent prints a Unicode wrench during import while the PowerShell process uses CP1252.
- **Resolution:** Set `PYTHONUTF8=1` for the agent and benchmark processes.
- **Status:** Resolved

---
