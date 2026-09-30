# AI Tools & Models Disclosure

> **Samsung Gen AI Hackathon 3.0 — Theme 05: Interruptible Real-Time Agents**  
> Submitted by: AnanthAkshay / Samsung_Gen_AI team  
> Repository: https://github.com/AnanthAkshay/Samsung_Gen_AI

This document lists every AI tool, model, and AI-assisted development environment used during this project, and describes the role each played.

---

## AI Models Used in the Submitted System

| Tool / Model | Provider | Role in Submission |
|:-------------|:---------|:-------------------|
| **Gemini 2.5 Flash Native Audio** (`gemini-2.5-flash-native-audio-preview-12-2025`) | Google DeepMind | **Primary agent model.** Handles all speech understanding, intent detection, function calling, and audio response synthesis end-to-end via the Gemini Live API. This is the core evaluated system. |
| **NVIDIA Parakeet TDT 0.6B v2** | NVIDIA (via HuggingFace) | **Benchmark ASR only.** Used by `run_tool_benchmark_all_released.py` to transcribe input and output audio to text for latency measurement and tool-call extraction. Not used at agent inference time. |

---

## AI Models Used Optionally / Not in Primary Submitted Results

| Tool / Model | Provider | Role |
|:-------------|:---------|:-----|
| **GPT-4o** | OpenAI | **Optional LLM judge only.** The evaluation scripts `evaluate_tool_calls.py` and `evaluate_pass_rate.py` accept a `--use-llm` flag that calls GPT-4o to score response quality (`response_qual`). This was **not used** in the reported results — all reported metrics (F1, pass rate, latency) use exact-match evaluation with no OpenAI key. |

---

## AI Tools Used for Development Assistance

| Tool | Provider | What it was used for |
|:-----|:---------|:---------------------|
| **Claude (Sonnet / Opus)** | Anthropic | Development assistance via Antigravity IDE: code review, debugging of benchmark harness, drafting reproduce scripts, writing documentation (including this file and README.md). Claude was used interactively during development — it did not generate any benchmark-facing agent prompts or tool definitions autonomously. |
| **Gemini** (chat / AI Studio) | Google | Checked Gemini Live API usage patterns and `livekit-plugins-google` integration documentation. |

---

## Clarifications

- **Agent prompts are human-authored.** The system prompt in `lk_agent_tool.py` (`VoiceAgent.instructions`) was written and reviewed by the team. Claude was used to review and critique it, but all final wording decisions were made by human team members.
- **No benchmark data was used to fine-tune any model.** The Gemini model is used zero-shot with no fine-tuning.
- **No benchmark scenario IDs, dialogue text, or expected answers are hardcoded** in the agent code or tool definitions. `mock_apis.py` returns generic responses keyed on the caller-provided arguments (no lookup table of benchmark-specific answers).
- **OpenAI GPT-4o was NOT used** as part of the submitted agent or for any reported metric. It is wired into the evaluation scripts as an optional judge path only.

---

*Disclosure prepared: 2026-09-30*
