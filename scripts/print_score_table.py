#!/usr/bin/env python3
"""Print exact-match vs LLM-judge scores for a results directory."""

import argparse
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "results_dir",
        nargs="?",
        default=str(ROOT / "results" / "latest"),
        help="Results folder containing summary_exact_match.json and/or summary_llm_judge.json",
    )
    args = parser.parse_args()
    script = ROOT / "scripts" / "run_scoring.py"
    subprocess.check_call(
        [
            sys.executable,
            str(script),
            "--python",
            sys.executable,
            "--v3-dir",
            str(ROOT / "Full-Duplex-Bench" / "v3"),
            "--data-dir",
            str(ROOT / "Full-Duplex-Bench" / "v3" / "fdb_v3_data_released"),
            "--results-dir",
            str(Path(args.results_dir)),
            "--provider",
            "gemini2_5",
            "--run-id",
            Path(args.results_dir).name,
            "--table-only",
        ]
    )


if __name__ == "__main__":
    main()
