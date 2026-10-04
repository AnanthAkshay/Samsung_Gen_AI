#!/usr/bin/env python3
"""Snapshot result JSON files and run exact-match plus optional LLM-judge scoring."""

from __future__ import annotations

import argparse
import json
import re
import shutil
import subprocess
import sys
from pathlib import Path

FOLDER_RE = re.compile(r"^(.+)_([0-9a-f]{24})$")


def scenario_dirs(data_dir: Path, limit: int | None) -> list[Path]:
    dirs = sorted(
        p
        for p in data_dir.iterdir()
        if p.is_dir() and not p.name.startswith(".") and FOLDER_RE.match(p.name)
    )
    if limit is not None and limit > 0:
        dirs = dirs[:limit]
    return dirs


def snapshot_results(data_dir: Path, snapshot_dir: Path, provider: str, limit: int | None) -> int:
    if snapshot_dir.exists():
        shutil.rmtree(snapshot_dir)
    snapshot_dir.mkdir(parents=True, exist_ok=True)
    copied = 0
    for folder in scenario_dirs(data_dir, limit):
        src = folder / f"result_{provider}.json"
        if not src.is_file():
            continue
        dest_dir = snapshot_dir / folder.name
        dest_dir.mkdir(parents=True, exist_ok=True)
        shutil.copy2(src, dest_dir / src.name)
        meta = folder / "metadata.json"
        if meta.is_file():
            shutil.copy2(meta, dest_dir / "metadata.json")
        copied += 1
    return copied


def run_evaluator(python: str, v3_dir: Path, script: str, extra: list[str]) -> None:
    cmd = [python, str(v3_dir / script), *extra]
    print("+", " ".join(cmd), flush=True)
    subprocess.check_call(cmd, cwd=str(v3_dir))


def summarize(
    python: str,
    v3_dir: Path,
    pass_report: Path,
    tool_report: Path,
    output: Path,
    run_id: str,
    provider: str,
    expected: int,
    mode: str,
) -> None:
    cmd = [
        python,
        str(v3_dir / "summarize_evaluation.py"),
        "--pass-rate-report",
        str(pass_report),
        "--tool-calls-report",
        str(tool_report),
        "--output",
        str(output),
        "--run-id",
        run_id,
        "--provider",
        provider,
        "--expected-scenarios",
        str(expected),
        "--evaluation-mode",
        mode,
    ]
    print("+", " ".join(cmd), flush=True)
    subprocess.check_call(cmd, cwd=str(v3_dir))


def print_table(results_dir: Path) -> None:
    exact = results_dir / "summary_exact_match.json"
    llm = results_dir / "summary_llm_judge.json"
    rows = []
    for label, path in (("exact-match", exact), ("llm-judge (gpt-4o)", llm)):
        if not path.is_file():
            rows.append((label, "not run", "", "", "", ""))
            continue
        data = json.loads(path.read_text(encoding="utf-8"))
        n = data["scenarios"]["evaluated_by_pass_rate"]
        pr = data["strict_pass_rate"]
        rows.append(
            (
                label,
                f"{n}",
                f"{pr['passed']}/{pr['passed'] + pr['failed']} ({pr['rate'] * 100:.1f}%)",
                f"{data['mean_tool_selection_f1']:.3f}",
                f"{data['mean_argument_accuracy']:.3f}",
                f"{data['latency']['mean_seconds']:.3f}s",
            )
        )
    headers = (
        "Mode",
        "N",
        "Strict pass",
        "Tool F1",
        "Arg acc",
        "Mean latency",
    )
    widths = [max(len(h), *(len(r[i]) for r in rows)) for i, h in enumerate(headers)]
    def fmt(cols: tuple[str, ...]) -> str:
        return " | ".join(c.ljust(widths[i]) for i, c in enumerate(cols))

    line = "-+-".join("-" * w for w in widths)
    print("", flush=True)
    print("Side-by-side scores", flush=True)
    print(fmt(headers), flush=True)
    print(line, flush=True)
    for row in rows:
        print(fmt(row), flush=True)
    table_path = results_dir / "score_comparison_table.txt"
    table_path.write_text(
        fmt(headers) + "\n" + line + "\n" + "\n".join(fmt(r) for r in rows) + "\n",
        encoding="utf-8",
    )
    print(f"Wrote {table_path}", flush=True)


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--python", required=True)
    parser.add_argument("--v3-dir", type=Path, required=True)
    parser.add_argument("--data-dir", type=Path, required=True)
    parser.add_argument("--results-dir", type=Path, required=True)
    parser.add_argument("--provider", required=True)
    parser.add_argument("--run-id", required=True)
    parser.add_argument("--limit", type=int, default=None)
    parser.add_argument("--use-llm-judge", action="store_true")
    parser.add_argument("--table-only", action="store_true")
    args = parser.parse_args()

    results_dir = args.results_dir
    results_dir.mkdir(parents=True, exist_ok=True)

    if args.table_only:
        print_table(results_dir)
        return

    snapshot_dir = results_dir / "fdb_v3_data_released"
    copied = snapshot_results(args.data_dir, snapshot_dir, args.provider, args.limit)
    if copied == 0:
        raise SystemExit("No result_*.json files found to score.")
    print(f"Snapshot copied {copied} result file(s) into {snapshot_dir}", flush=True)

    bench = "benchmark_data_v2.json"
    snap = str(snapshot_dir)

    exact_tool = results_dir / "tool_calls_report_exact_match.json"
    exact_pass = results_dir / "pass_rate_report_exact_match.json"
    exact_sum = results_dir / "summary_exact_match.json"
    run_evaluator(
        args.python,
        args.v3_dir,
        "evaluate_tool_calls.py",
        [
            "--benchmark",
            bench,
            "--results-dir",
            snap,
            "--provider",
            args.provider,
            "--output",
            str(exact_tool),
        ],
    )
    run_evaluator(
        args.python,
        args.v3_dir,
        "evaluate_pass_rate.py",
        [
            "--benchmark",
            bench,
            "--results-dir",
            snap,
            "--provider",
            args.provider,
            "--output",
            str(exact_pass),
        ],
    )
    summarize(
        args.python,
        args.v3_dir,
        exact_pass,
        exact_tool,
        exact_sum,
        args.run_id,
        args.provider,
        copied,
        "exact-match (no LLM judge)",
    )

    if args.use_llm_judge:
        llm_tool = results_dir / "tool_calls_report_llm_judge.json"
        llm_pass = results_dir / "pass_rate_report_llm_judge.json"
        llm_sum = results_dir / "summary_llm_judge.json"
        run_evaluator(
            args.python,
            args.v3_dir,
            "evaluate_tool_calls.py",
            [
                "--benchmark",
                bench,
                "--results-dir",
                snap,
                "--provider",
                args.provider,
                "--output",
                str(llm_tool),
                "--use-llm",
            ],
        )
        run_evaluator(
            args.python,
            args.v3_dir,
            "evaluate_pass_rate.py",
            [
                "--benchmark",
                bench,
                "--results-dir",
                snap,
                "--provider",
                args.provider,
                "--output",
                str(llm_pass),
                "--use-llm",
            ],
        )
        summarize(
            args.python,
            args.v3_dir,
            llm_pass,
            llm_tool,
            llm_sum,
            args.run_id,
            args.provider,
            copied,
            "llm-judge (OpenAI gpt-4o, FDB-v3 --use-llm)",
        )

    print_table(results_dir)


if __name__ == "__main__":
    main()
