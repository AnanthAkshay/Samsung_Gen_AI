# Benchmark Results Directory

This directory stores evaluation runs and scoring artifacts for Team Cache_Me's submission on **Full-Duplex-Bench v3 (FDB-v3)**.

## Verified Baseline Run: `baseline_final_20261001_020033`

- **Benchmark**: In-the-Wild Speech & Multi-Step Tool Calling (FDB-v3, 100 released scenarios)
- **Model**: `gemini-2.5-flash-native-audio-preview-12-2025`
- **Voice**: `Puck`
- **Evaluation Mode**: Exact-match string comparison (no LLM judge / no paid API key required)
- **Timestamp**: `2026-10-01T16:04:18Z`

### Summary Metrics

| Metric | Result |
| :--- | :--- |
| **Total Scenarios Evaluated** | 100 / 100 |
| **Strict Pass Rate** | **45 / 100 (45.0%)** |
| **Mean Tool Selection F1** | **0.823** |
| **Mean Argument Accuracy** | **0.528** |
| **Mean Response Latency** | **11.732 s** (excludes 5 interruption cases) |
| **Turn-Taking Success Rate** | **100 / 100 (100.0%)** |

### Breakdown by Domain

| Domain | Pass Rate | Scenarios |
| :--- | :--- | :--- |
| **Finance & Billing** | 92.0% (23 / 25) | 25 |
| **E-Commerce Support** | 58.6% (17 / 29) | 29 |
| **Housing & Location** | 11.5% (3 / 26) | 26 |
| **Travel & Identity** | 10.0% (2 / 20) | 20 |

### Breakdown by Difficulty

| Difficulty | Pass Rate | Scenarios |
| :--- | :--- | :--- |
| **Easy (1 tool call)** | 52.8% (19 / 36) | 36 |
| **Medium (2 tool calls)** | 41.2% (14 / 34) | 34 |
| **Hard (3 tool calls)** | 40.0% (12 / 30) | 30 |

### Artifact Files in `baseline_final_20261001_020033/`

- `summary_metrics.json`: Full machine-readable aggregate metrics.
- `pass_rate_report.json`: Per-scenario strict pass/fail status and failure categorization.
- `tool_calls_report.json`: Tool selection F1, argument matches, and timing details.
- `fdb_v3_data_released/`: Snapshot of individual `result_gemini2_5.json` outputs for all 100 scenarios.

Future runs invoked via `./reproduce.sh` or `.\reproduce.ps1` create new timestamped folders (e.g. `results/baseline_<YYYYMMDD_HHMMSS>/`).
