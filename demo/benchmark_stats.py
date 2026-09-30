import os
import json
from pathlib import Path

def get_stats(run_dir):
    run_path = Path(run_dir)
    files = list(run_path.rglob("result_gemini2_5.json"))
    total = len(files)
    completed = 0
    silent = 0
    failed = 0
    with_tools = 0
    total_tools = 0
    latencies = []

    for f in sorted(files):
        try:
            with open(f, "r", encoding="utf-8") as fp:
                data = json.load(fp)
            status = data.get("status")
            transcript = str(data.get("transcript") or "").strip()
            tools = data.get("actual_tool_calls") or []
            
            if status == "completed":
                completed += 1
                if not transcript:
                    silent += 1
                if tools:
                    with_tools += 1
                    total_tools += len(tools)
                lat = data.get("latency", {}).get("first_speech_s")
                if lat:
                    latencies.append(lat)
            else:
                failed += 1
        except Exception as e:
            failed += 1

    avg_lat = sum(latencies) / len(latencies) if latencies else 0.0

    print("=" * 60)
    print(f"Benchmark Run Directory: {run_dir}")
    print(f"Total Processed Cases:   {total}")
    print(f"Completed Cases:         {completed}")
    print(f"Silent (No Response):    {silent}")
    print(f"Failed / Incomplete:     {failed}")
    print(f"Cases with Tool Calls:   {with_tools}")
    print(f"Total Tool Invocations:  {total_tools}")
    print(f"Average First-Speech Latency: {avg_lat:.2f}s")
    print("=" * 60)
    return {
        "total": total,
        "completed": completed,
        "silent": silent,
        "failed": failed,
        "with_tools": with_tools,
        "avg_lat": avg_lat,
    }

if __name__ == "__main__":
    import sys
    target = sys.argv[1] if len(sys.argv) > 1 else r"A:\Samsung_2\logs\baseline_final_20261001_000607"
    get_stats(target)
