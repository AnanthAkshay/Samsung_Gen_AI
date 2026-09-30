"""
Extension demo: in-car voice assistant with mid-utterance destination correction.

Reuses the same stack as the benchmark agent (LiveKit Agents + Gemini native
realtime). Tools are MOCKS: they only log, no real navigation happens.
No FDB-v3 benchmark data, scenario text or IDs are used anywhere in this file.

Run (from the repo root, venv active, .env loaded):
    python extension_demo.py dev

Then open the LiveKit Agents Playground for your LiveKit Cloud project,
connect to a room, and speak. Tool calls are appended to
logs/extension_tool_calls.log (and printed to the terminal).

Do NOT run this while the benchmark worker is running: both register as
workers on the same LiveKit project and would compete for rooms.
"""
import json
import os
import time
from pathlib import Path

from dotenv import load_dotenv
from livekit.agents import (
    Agent,
    AgentSession,
    JobContext,
    RunContext,
    WorkerOptions,
    cli,
    function_tool,
)
from livekit.plugins import google

load_dotenv()

ROOT = Path(__file__).resolve().parent
LOG_PATH = ROOT / "logs" / "extension_tool_calls.log"
LOG_PATH.parent.mkdir(parents=True, exist_ok=True)


def log_event(event: str, **fields) -> None:
    """Print and persist one JSON line per tool call so the demo is auditable."""
    line = json.dumps({"t": round(time.time(), 2), "event": event, **fields})
    print(f"[EXTENSION] {line}", flush=True)
    with LOG_PATH.open("a", encoding="utf-8") as f:
        f.write(line + "\n")


INSTRUCTIONS = """You are a concise in-car voice assistant.

Rules:
- Wait until the driver has finished their full sentence before calling any tool.
  Do not act on partial input.
- If the driver corrects themselves mid-sentence ("no wait", "actually", "instead",
  "I mean", "I changed my mind"), use ONLY the final corrected destination and
  never the discarded one. Do not mention the discarded destination in your reply.
- If navigation is already active and the driver changes their mind, call
  cancel_navigation first, then navigate_to with the new destination.
- Ignore fillers and hesitations such as "um", "uh", "er", "hold on", and
  "let me think". These are pauses, not commands. Do not cancel navigation
  because the driver hesitated.
- Keep every spoken reply to one short sentence.
"""



class CarAssistant(Agent):
    def __init__(self) -> None:
        super().__init__(instructions=INSTRUCTIONS)
        self.active_destination: str | None = None

    @function_tool
    async def navigate_to(self, context: RunContext, destination: str):
        """Start turn-by-turn navigation to the given destination."""
        self.active_destination = destination
        log_event("navigate_to", destination=destination)
        return f"Navigation started to {destination}."

    @function_tool
    async def cancel_navigation(self, context: RunContext):
        """Cancel the currently active navigation."""
        log_event("cancel_navigation", was=self.active_destination)
        self.active_destination = None
        return "Navigation cancelled."

    @function_tool
    async def get_eta(self, context: RunContext):
        """Report the estimated time of arrival for the active navigation."""
        log_event("get_eta", destination=self.active_destination)
        if self.active_destination:
            return f"About 18 minutes to {self.active_destination}."
        return "There is no active navigation."


async def entrypoint(ctx: JobContext) -> None:
    await ctx.connect()

    # If lk_agent_tool.py configures the Gemini realtime model differently
    # (model name, voice, etc.), copy those settings here so the extension
    # matches the benchmark agent.
    model_kwargs = {"voice": os.getenv("EXT_VOICE", "Puck")}
    if os.getenv("EXT_GEMINI_MODEL"):
        model_kwargs["model"] = os.environ["EXT_GEMINI_MODEL"]

    session = AgentSession(llm=google.realtime.RealtimeModel(**model_kwargs))
    await session.start(room=ctx.room, agent=CarAssistant())
    log_event("session_started", room=ctx.room.name)
    await session.generate_reply(
        instructions="Greet the driver with one short sentence and ask where they want to go."
    )


if __name__ == "__main__":
    cli.run_app(WorkerOptions(entrypoint_fnc=entrypoint))