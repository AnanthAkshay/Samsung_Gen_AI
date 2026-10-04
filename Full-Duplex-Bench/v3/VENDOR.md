# Vendored Full-Duplex-Bench v3

This tree is **vendored** into the submission. `reproduce.sh` / `reproduce.ps1` **do not clone** upstream.

## Pin

- Upstream: https://github.com/DanielLin94144/Full-Duplex-Bench
- Commit: `3e799c45a045256f47d5f1c9cda90157e2d2ec9e`
- Audio (`fdb_v3_data_released/`) is **not** vendored. Download from the [v3 README Data section](README.md#data) (Google Drive id `1SO_4MTazWQ_jvCx0dtmpQ-t40bdd07yz`).

## Why vendor instead of clone-and-patch

Organizers run **this** repo. A second `git clone` of upstream can fail (network, default branch drift). Vendoring the pinned v3 sources plus our small harness edits makes a fresh clone of the submission enough, as long as audio is downloaded.

The documentary diff versus that commit is [`patches/fdb_v3_changes.patch`](../../patches/fdb_v3_changes.patch). The patch is **already applied** in this folder; the scripts do not re-apply it.

## What we changed (not agent prompts / tool schemas)

- `lk_agent_tool.py`: load repo-root `.env`, `agent_config.json` provider/model/voice/seed, Windows `/tmp` mkdir, `AgentServer(load_threshold=0.95)`. Instructions and tool definitions are unchanged from upstream.
- `run_tool_benchmark_all_released.py`: `--limit` for smoke tests; local RNG seed from `agent_config.json`.
- `evaluate_tool_calls.py` / `evaluate_pass_rate.py`: also load the repo-root `.env` so `OPENAI_API_KEY` is visible to the gpt-4o judge.
- `summarize_evaluation.py`: `--evaluation-mode` label for exact-match vs LLM-judge summaries.

## Verify after a fresh clone

```bash
grep -n "RANDOM_SEED" Full-Duplex-Bench/v3/lk_agent_tool.py
grep -n "add_argument" Full-Duplex-Bench/v3/run_tool_benchmark_all_released.py | grep limit
```
