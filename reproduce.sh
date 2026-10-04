#!/usr/bin/env bash
# Full-Duplex-Bench v3 one-command reproduction (Linux / macOS).
# Requires bash (Ubuntu /bin/sh is dash; invoke this file directly).
set -eu

LIMIT=100
USE_LLM_JUDGE=1
FORCE=0

usage() {
    echo "Usage: ./reproduce.sh [--limit N] [--no-llm-judge] [--force]"
    echo "  --limit N         Score the first N scenarios (default: 100)"
    echo "  --no-llm-judge    Exact-match scoring only (offline smoke test)"
    echo "  --force           Re-run inference even if result JSON already exists"
}

while [ $# -gt 0 ]; do
    case "$1" in
        --limit|-l)
            LIMIT="$2"
            shift 2
            ;;
        --no-llm-judge)
            USE_LLM_JUDGE=0
            shift
            ;;
        --force)
            FORCE=1
            shift
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        *)
            echo "Unknown argument: $1"
            usage
            exit 1
            ;;
    esac
done

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
export PYTHONUTF8=1
export PYTHONIOENCODING=utf-8

echo "======================================================================"
echo " Samsung Gen AI Hackathon 3.0 (Theme 05: Interruptible Real-Time Agents)"
echo " Reproduction Pipeline: Google Gemini Native Realtime + LiveKit Agents"
echo " Benchmark: Full-Duplex-Bench v3 (arXiv:2604.04847) [Limit: ${LIMIT}]"
if [ "$USE_LLM_JUDGE" -eq 1 ]; then
    echo " Judge: ENABLED (OpenAI gpt-4o via FDB-v3 --use-llm)"
else
    echo " Judge: DISABLED (exact-match only)"
fi
echo "======================================================================"

echo ""
echo "[1/7] Verifying Python 3.10–3.12 and system packages..."

is_supported_python() {
    case "$1" in
        3.10|3.11|3.12) return 0 ;;
        *) return 1 ;;
    esac
}

PYTHON_BIN=""
for candidate in python3.12 python3.11 python3.10 python3 python; do
    if command -v "$candidate" >/dev/null 2>&1; then
        ver="$("$candidate" -c "import sys; print('%d.%d' % (sys.version_info.major, sys.version_info.minor))" 2>/dev/null || true)"
        if is_supported_python "$ver"; then
            PYTHON_BIN="$candidate"
            echo "  Using $PYTHON_BIN ($ver)"
            break
        fi
    fi
done

if [ -z "$PYTHON_BIN" ]; then
    echo "Error: Python 3.10, 3.11, or 3.12 is required (found none on PATH)."
    echo "On Ubuntu: sudo apt-get install -y python3.11 python3.11-venv python3-pip"
    exit 1
fi

MISSING_PKGS=""
if ! command -v git >/dev/null 2>&1; then
    MISSING_PKGS="$MISSING_PKGS git"
fi
if ! command -v ffmpeg >/dev/null 2>&1; then
    MISSING_PKGS="$MISSING_PKGS ffmpeg"
fi
if ! "$PYTHON_BIN" -c "import venv" >/dev/null 2>&1; then
    MISSING_PKGS="$MISSING_PKGS python3-venv"
fi

# libsndfile is required by the soundfile wheel at import time.
if ! "$PYTHON_BIN" -c "import ctypes.util, sys; sys.exit(0 if ctypes.util.find_library('sndfile') else 1)" >/dev/null 2>&1; then
    if [ -e /usr/lib/x86_64-linux-gnu/libsndfile.so.1 ] || [ -e /usr/lib/aarch64-linux-gnu/libsndfile.so.1 ]; then
        :
    else
        MISSING_PKGS="$MISSING_PKGS libsndfile1"
    fi
fi

if [ -n "$MISSING_PKGS" ]; then
    echo "Error: missing system packages:$MISSING_PKGS"
    echo "Install on Ubuntu 22.04/24.04:"
    echo "  sudo apt-get update && sudo apt-get install -y git ffmpeg libsndfile1 python3-venv python3-pip"
    exit 1
fi
echo "  System packages present (git, ffmpeg, libsndfile)."

VENV_DIR="${SCRIPT_DIR}/.venv"
if [ ! -d "$VENV_DIR" ] && [ -d "${SCRIPT_DIR}/venv" ]; then
    VENV_DIR="${SCRIPT_DIR}/venv"
fi

if [ ! -f "${VENV_DIR}/bin/python" ] && [ ! -f "${VENV_DIR}/Scripts/python.exe" ]; then
    echo "  Creating virtual environment at ${VENV_DIR}..."
    "$PYTHON_BIN" -m venv "$VENV_DIR"
fi

if [ -f "${VENV_DIR}/bin/python" ]; then
    VENV_PYTHON="${VENV_DIR}/bin/python"
else
    VENV_PYTHON="${VENV_DIR}/Scripts/python.exe"
fi

echo "  Installing torch (CUDA or CPU), then pinned requirements, then NeMo..."
"$VENV_PYTHON" "${SCRIPT_DIR}/scripts/install_deps.py"
echo "  Dependencies installed."

echo ""
echo "[2/7] Validating credentials and configuration..."

V3_DIR="${SCRIPT_DIR}/Full-Duplex-Bench/v3"
ENV_FILE="${SCRIPT_DIR}/.env"
ENV_LOCAL="${V3_DIR}/.env.local"

if [ ! -f "$ENV_FILE" ] && [ ! -f "$ENV_LOCAL" ]; then
    echo "Error: Neither .env nor Full-Duplex-Bench/v3/.env.local was found."
    echo "Copy .env.example to .env and set LIVEKIT_*, GOOGLE_API_KEY, and OPENAI_API_KEY:"
    echo "  cp .env.example .env"
    exit 1
fi

if [ -f "$ENV_FILE" ]; then
    cp "$ENV_FILE" "$ENV_LOCAL"
    ENV_TO_LOAD="$ENV_FILE"
else
    ENV_TO_LOAD="$ENV_LOCAL"
fi

# Load KEY=VALUE lines into the environment without printing secrets.
# Avoid process substitution so this works under bash without extra fds.
while IFS= read -r line || [ -n "$line" ]; do
    line="${line%$'\r'}"
    case "$line" in
        ''|\#*) continue ;;
    esac
    case "$line" in
        *=*)
            key="${line%%=*}"
            value="${line#*=}"
            key="${key%"${key##*[![:space:]]}"}"
            export "$key=$value"
            ;;
    esac
done < "$ENV_TO_LOAD"

MISSING_KEYS=""
for k in LIVEKIT_URL LIVEKIT_API_KEY LIVEKIT_API_SECRET GOOGLE_API_KEY; do
    eval "val=\${$k-}"
    case "$val" in
        ''|your_*) MISSING_KEYS="$MISSING_KEYS $k" ;;
    esac
done

if [ "$USE_LLM_JUDGE" -eq 1 ]; then
    case "${OPENAI_API_KEY-}" in
        ''|your_*) MISSING_KEYS="$MISSING_KEYS OPENAI_API_KEY" ;;
    esac
fi

if [ -n "$MISSING_KEYS" ]; then
    echo "Error: missing required credentials in .env:$MISSING_KEYS"
    echo "LiveKit (free): https://cloud.livekit.io"
    echo "Google AI Studio (Gemini Live): https://aistudio.google.com"
    if [ "$USE_LLM_JUDGE" -eq 1 ]; then
        echo "OpenAI (FDB-v3 gpt-4o judge, same as organizers): https://platform.openai.com"
        echo "For an offline smoke test without OpenAI: ./reproduce.sh --limit 3 --no-llm-judge"
    fi
    exit 1
fi

export LK_PROVIDER="${LK_PROVIDER:-gemini2_5}"
echo "  Credentials validated. Model provider: ${LK_PROVIDER}"
if [ "$USE_LLM_JUDGE" -eq 1 ]; then
    echo "  LLM judge: OpenAI gpt-4o (OPENAI_API_KEY present; value not printed)."
fi

echo ""
echo "[3/7] Verifying benchmark audio dataset..."
echo "  FDB-v3 source is vendored in Full-Duplex-Bench/v3 (pinned commit in agent_config.json)."
echo "  Audio is NOT in git; it is downloaded per the v3 README."

DATA_DIR="${V3_DIR}/fdb_v3_data_released"
ZIP_PATH="${V3_DIR}/fdb_v3_data.zip"
DRIVE_ID="1SO_4MTazWQ_jvCx0dtmpQ-t40bdd07yz"

need_data=0
if [ ! -d "$DATA_DIR" ]; then
    need_data=1
else
    _any="$(find "$DATA_DIR" -mindepth 1 -maxdepth 1 -type d 2>/dev/null | head -n 1 || true)"
    if [ -z "$_any" ]; then
        need_data=1
    fi
fi

if [ "$need_data" -eq 1 ]; then
    if [ -f "$ZIP_PATH" ]; then
        echo "  Extracting ${ZIP_PATH}..."
        "$VENV_PYTHON" -c "import zipfile; zipfile.ZipFile(r'''${ZIP_PATH}''').extractall(r'''${V3_DIR}''')"
    else
        echo "  Downloading benchmark dataset via gdown..."
        if ! "$VENV_PYTHON" -m gdown "$DRIVE_ID" -O "$ZIP_PATH"; then
            echo "Automated dataset download failed (Google Drive quota or network)."
            echo "Manual download:"
            echo "  1. Open https://drive.google.com/file/d/${DRIVE_ID}/view?usp=sharing"
            echo "  2. Save as fdb_v3_data.zip"
            echo "  3. Place it at: ${ZIP_PATH}"
            echo "  4. Extract so this exists: ${DATA_DIR}/<scenario_id>/input.wav"
            echo "See Full-Duplex-Bench/v3/README.md (Data section)."
            exit 1
        fi
        "$VENV_PYTHON" -c "import zipfile; zipfile.ZipFile(r'''${ZIP_PATH}''').extractall(r'''${V3_DIR}''')"
    fi
fi

ITEM_COUNT="$(find "$DATA_DIR" -mindepth 1 -maxdepth 1 -type d 2>/dev/null | wc -l | tr -d ' ')"
echo "  Benchmark audio ready (${ITEM_COUNT} scenario directories)."

echo ""
echo "[4/7] Launching Gemini Native Realtime agent worker (lk_agent_tool.py)..."

mkdir -p "${SCRIPT_DIR}/logs"
AGENT_STDOUT="${SCRIPT_DIR}/logs/gemini2_5_agent.stdout.log"
AGENT_STDERR="${SCRIPT_DIR}/logs/gemini2_5_agent.stderr.log"

cd "${V3_DIR}"
"$VENV_PYTHON" lk_agent_tool.py start > "$AGENT_STDOUT" 2> "$AGENT_STDERR" &
AGENT_PID=$!

cleanup() {
    echo ""
    echo "Stopping background agent worker (PID: ${AGENT_PID})..."
    kill "${AGENT_PID}" 2>/dev/null || true
    wait "${AGENT_PID}" 2>/dev/null || true
}
trap cleanup EXIT INT TERM

sleep 6

if ! kill -0 "${AGENT_PID}" 2>/dev/null; then
    echo "Agent worker failed to start. Last log lines:"
    tail -n 20 "$AGENT_STDERR" 2>/dev/null || true
    exit 1
fi
echo "  Agent worker running (PID: ${AGENT_PID})."

echo ""
echo "[5/7] Executing streaming benchmark inference (Limit: ${LIMIT})..."
echo "  Resume: existing completed result_*.json files are skipped unless --force."
BENCH_ARGS="run_tool_benchmark_all_released.py --provider ${LK_PROVIDER} --limit ${LIMIT}"
if [ "$FORCE" -eq 1 ]; then
    BENCH_ARGS="$BENCH_ARGS --force"
fi
# shellcheck disable=SC2086
"$VENV_PYTHON" $BENCH_ARGS
echo "  Streaming inference completed."

echo ""
echo "[6/7] Evaluating tool selection, pass rate, and latency..."
TIMESTAMP="$(date +"%Y%m%d_%H%M%S")"
RUN_ID="baseline_${TIMESTAMP}"
RESULTS_DIR="${SCRIPT_DIR}/results/${RUN_ID}"
mkdir -p "$RESULTS_DIR"

SCORE_ARGS="${VENV_PYTHON} ${SCRIPT_DIR}/scripts/run_scoring.py --python ${VENV_PYTHON} --v3-dir ${V3_DIR} --data-dir ${DATA_DIR} --results-dir ${RESULTS_DIR} --provider ${LK_PROVIDER} --run-id ${RUN_ID} --limit ${LIMIT}"
if [ "$USE_LLM_JUDGE" -eq 1 ]; then
    SCORE_ARGS="$SCORE_ARGS --use-llm-judge"
fi
# shellcheck disable=SC2086
$SCORE_ARGS

if [ -f "${SCRIPT_DIR}/agent_config.json" ]; then
    cp "${SCRIPT_DIR}/agent_config.json" "${RESULTS_DIR}/agent_config.json"
fi
cp "$AGENT_STDOUT" "${RESULTS_DIR}/agent.stdout.log"
cp "$AGENT_STDERR" "${RESULTS_DIR}/agent.stderr.log"

LATEST_DIR="${SCRIPT_DIR}/results/latest"
rm -rf "$LATEST_DIR"
mkdir -p "$LATEST_DIR"
cp -R "${RESULTS_DIR}/." "$LATEST_DIR/"

echo ""
echo "[7/7] Reproduction completed."
echo "======================================================================"
echo " Artifacts: ${RESULTS_DIR}"
echo " Exact-match summary:"
if [ -f "${RESULTS_DIR}/summary_exact_match.json" ]; then
    cat "${RESULTS_DIR}/summary_exact_match.json"
fi
if [ -f "${RESULTS_DIR}/summary_llm_judge.json" ]; then
    echo " LLM-judge (gpt-4o) summary:"
    cat "${RESULTS_DIR}/summary_llm_judge.json"
fi
echo "======================================================================"
