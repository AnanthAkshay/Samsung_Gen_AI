"""
Offline unit tests for CarAssistant tool logic in extension_demo.py.

These tests call navigate_to, cancel_navigation and get_eta directly
(no LiveKit, no network) and verify:
  a) The correct sequence of JSON events is written to the log file.
  b) get_eta returns the no-active-navigation message after a cancel.

Run:
    python tests/test_extension_tools.py
"""
import asyncio
import json
import sys
from pathlib import Path
from unittest.mock import AsyncMock

# ── make the repo root importable ──────────────────────────────────────
ROOT = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(ROOT))

# ── redirect the log to a test-specific file ──────────────────────────
import extension_demo

TEST_LOG = ROOT / "logs" / "test_extension_tool_calls.log"
TEST_LOG.parent.mkdir(parents=True, exist_ok=True)
if TEST_LOG.exists():
    TEST_LOG.unlink()
extension_demo.LOG_PATH = TEST_LOG  # monkey-patch so log_event writes here


async def run_tests() -> bool:
    """Return True if all assertions pass."""
    ok = True

    # Build a fake RunContext (the tools accept it but don't use it)
    fake_ctx = AsyncMock()

    car = extension_demo.CarAssistant()

    # ── a) navigate A -> cancel -> navigate B ────────────────────────────
    r1 = await car.navigate_to(fake_ctx, destination="A")
    print(f"  navigate_to('A') -> {r1}")

    r2 = await car.cancel_navigation(fake_ctx)
    print(f"  cancel_navigation() -> {r2}")

    r3 = await car.navigate_to(fake_ctx, destination="B")
    print(f"  navigate_to('B') -> {r3}")

    # Read the log and check the event sequence
    lines = TEST_LOG.read_text(encoding="utf-8").strip().splitlines()
    events = [json.loads(l) for l in lines]

    expected_events = [
        ("navigate_to", {"destination": "A"}),
        ("cancel_navigation", {"was": "A"}),
        ("navigate_to", {"destination": "B"}),
    ]

    for i, (exp_name, exp_fields) in enumerate(expected_events):
        ev = events[i]
        if ev["event"] != exp_name:
            print(f"  ✗ Event {i}: expected event={exp_name}, got {ev['event']}")
            ok = False
        for k, v in exp_fields.items():
            if ev.get(k) != v:
                print(f"  ✗ Event {i}: expected {k}={v}, got {ev.get(k)}")
                ok = False

    if len(events) != len(expected_events):
        print(f"  ✗ Expected {len(expected_events)} log lines, got {len(events)}")
        ok = False

    if ok:
        print("  ✓ Log sequence: navigate_to A, cancel_navigation (was A), navigate_to B")

    # ── b) get_eta after cancel ─────────────────────────────────────────
    await car.cancel_navigation(fake_ctx)  # reset state
    r4 = await car.get_eta(fake_ctx)
    print(f"  get_eta() after cancel -> {r4}")
    if "no active navigation" not in r4.lower():
        print(f"  ✗ Expected 'no active navigation' message, got: {r4}")
        ok = False
    else:
        print("  ✓ get_eta returns no-active-navigation message after cancel")

    return ok


if __name__ == "__main__":
    print("=" * 60)
    print("TEST: extension_demo.py tool logic (offline, no LiveKit)")
    print("=" * 60)
    passed = asyncio.run(run_tests())
    print("=" * 60)
    if passed:
        print("ALL TESTS PASSED ✓")
    else:
        print("SOME TESTS FAILED ✗")
        sys.exit(1)
