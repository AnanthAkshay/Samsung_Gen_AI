#!/usr/bin/env python3
"""Combine exact-match evaluator reports into a compact, validated summary."""

import argparse
import json
from datetime import datetime, timezone
from pathlib import Path

MODELS = {
    "gemini2_5": "gemini-2.5-flash-native-audio-preview-12-2025",
    "gemini3_1": "gemini-3.1-flash-live-preview",
}


def load_report(path: Path) -> dict:
    with path.open(encoding="utf-8") as report_file:
        return json.load(report_file)


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--pass-rate-report", type=Path, required=True)
    parser.add_argument("--tool-calls-report", type=Path, required=True)
    parser.add_argument("--output", type=Path, required=True)
    parser.add_argument("--run-id", required=True)
    parser.add_argument("--provider", default="gemini2_5")
    parser.add_argument("--expected-scenarios", type=int, default=100)
    parser.add_argument(
        "--evaluation-mode",
        default="exact-match (no LLM judge)",
        help="Label stored in summary_metrics.json (exact-match vs llm-judge).",
    )
    args = parser.parse_args()

    pass_report = load_report(args.pass_rate_report)
    tool_report = load_report(args.tool_calls_report)
    pass_count = pass_report["total_scenarios"]
    tool_count = tool_report["total_scenarios"]
    if pass_count != args.expected_scenarios or tool_count != args.expected_scenarios:
        raise SystemExit(
            "Refusing to write a complete-run summary: "
            f"pass-rate evaluator found {pass_count}/{args.expected_scenarios}; "
            f"tool-call evaluator found {tool_count}/{args.expected_scenarios}."
        )

    metrics = tool_report["by_metric"]
    latency = tool_report["latency"]
    summary = {
        "run_id": args.run_id,
        "generated_at": datetime.now(timezone.utc).isoformat(),
        "benchmark": "In-the-Wild Speech & Multi-Step Tool Calling (FDB-v3)",
        "provider": args.provider,
        "model": MODELS.get(args.provider),
        "evaluation_mode": args.evaluation_mode,
        "scenarios": {
            "expected": args.expected_scenarios,
            "evaluated_by_pass_rate": pass_count,
            "evaluated_by_tool_calls": tool_count,
        },
        "result_snapshot": "fdb_v3_data_released/",
        "strict_pass_rate": {
            "passed": pass_report["passed"],
            "failed": pass_report["failed"],
            "rate": pass_report["overall_pass_rate"],
        },
        "failure_breakdown": pass_report["failure_breakdown"],
        "mean_tool_selection_f1": metrics["tool_selection_acc"],
        "mean_argument_accuracy": metrics["argument_acc"],
        "latency": {
            "mean_seconds": latency["avg_response_latency_s"],
            "samples_including_interruptions": latency["total_samples"],
            "interruption_count": latency["interruption_count"],
            "note": "Mean excludes interruption samples, per evaluate_tool_calls.py.",
        },
        "turn_taking": tool_report["turn_taking"],
        "pass_rate_by_domain": pass_report["by_domain"],
        "pass_rate_by_difficulty": pass_report["by_difficulty"],
        "reports": {
            "pass_rate": args.pass_rate_report.name,
            "tool_calls": args.tool_calls_report.name,
        },
    }

    args.output.parent.mkdir(parents=True, exist_ok=True)
    with args.output.open("w", encoding="utf-8") as output_file:
        json.dump(summary, output_file, indent=2, ensure_ascii=False)
        output_file.write("\n")
    print(json.dumps(summary, indent=2, ensure_ascii=False))
    print(f"Summary saved: {args.output}")


if __name__ == "__main__":
    main()
