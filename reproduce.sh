#!/usr/bin/env bash
# ==============================================================================
# Full-Duplex-Bench v3: End-to-End Reproduction Script (Gemini Live Native)
# ==============================================================================
set -euo pipefail

echo "======================================================================"
echo "Starting Full-Duplex-Bench v3 Reproduction Pipeline (Gemini Native)"
echo "======================================================================"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
V3_DIR="${SCRIPT_DIR}/Full-Duplex-Bench/v3"
VENV_DIR="${SCRIPT_DIR}/venv"

# 1. Activate or create Python 3.10 virtual environment
if [ -d "${VENV_DIR}" ]; then
    echo " Activating existing virtual environment..."
    # shellcheck disable=SC1091
    source "${VENV_DIR}/bin/activate" 2>/dev/null || source "${VENV_DIR}/Scripts/activate" 2>/dev/null || true
else
    echo " Creating Python 3.10 virtual environment..."
    python3.10 -m venv "${VENV_DIR}" || py -3.10 -m venv "${VENV_DIR}"
    source "${VENV_DIR}/bin/activate" 2>/dev/null || source "${VENV_DIR}/Scripts/activate" 2>/dev/null || true
fi

# 2. Install pinned dependencies
echo " Installing pinned dependencies..."
pip install --upgrade pip
pip install "livekit-agents[google]~=1.3" \
            "livekit-plugins-google==1.8.3" \
            "livekit[crypto]~=1.0" \
            "pydub==0.25.1" \
            "ffmpeg-python==0.2.0" \
            "python-dotenv==1.2.3" \
            "gdown==6.4.0" \
            "numpy==2.2.6" \
            "nemo_toolkit[asr]==3.0.0"

# 3. Environment validation
if [ -f "${V3_DIR}/.env.local" ]; then
    echo " Loading environment from ${V3_DIR}/.env.local"
    # shellcheck disable=SC1091
    source "${V3_DIR}/.env.local" || true
elif [ -f "${SCRIPT_DIR}/.env" ]; then
    echo " Copying ${SCRIPT_DIR}/.env to ${V3_DIR}/.env.local"
    cp "${SCRIPT_DIR}/.env" "${V3_DIR}/.env.local"
    # shellcheck disable=SC1091
    source "${V3_DIR}/.env.local" || true
else
    echo "❌ Error: Neither .env nor Full-Duplex-Bench/v3/.env.local found."
    echo "Please copy .env.example to .env and configure LIVEKIT_* and GOOGLE_API_KEY."
    exit 1
fi

if [ -z "${GOOGLE_API_KEY:-}" ]; then
    echo "❌ Error: GOOGLE_API_KEY is not set."
    exit 1
fi

if [ -z "${LIVEKIT_URL:-}" ] || [ -z "${LIVEKIT_API_KEY:-}" ] || [ -z "${LIVEKIT_API_SECRET:-}" ]; then
    echo "❌ Error: LiveKit credentials (LIVEKIT_URL, LIVEKIT_API_KEY, LIVEKIT_API_SECRET) missing."
    exit 1
fi

export LK_PROVIDER="${LK_PROVIDER:-gemini2_5}"
echo " Model Provider: ${LK_PROVIDER}"

# 4. Check benchmark audio dataset
DATA_DIR="${V3_DIR}/fdb_v3_data_released"
if [ ! -d "${DATA_DIR}" ]; then
    echo "📥 Downloading benchmark audio dataset from Google Drive..."
    gdown 1SO_4MTazWQ_jvCx0dtmpQ-t40bdd07yz -O "${V3_DIR}/fdb_v3_data.zip"
    python -c "import zipfile; zipfile.ZipFile('${V3_DIR}/fdb_v3_data.zip', 'r').extractall('${V3_DIR}')"
fi

# 5. Start Gemini Live agent worker in the background
echo " Starting Gemini Live agent worker (lk_agent_tool.py)..."
cd "${V3_DIR}"
python lk_agent_tool.py start > "${SCRIPT_DIR}/logs/gemini_agent.log" 2>&1 &
AGENT_PID=$!
echo " Agent worker running (PID: ${AGENT_PID})"

# Ensure agent is stopped on exit
cleanup() {
    echo " Shutting down agent worker (PID: ${AGENT_PID})..."
    kill "${AGENT_PID}" 2>/dev/null || true
}
trap cleanup EXIT

# Brief warm-up sleep
sleep 5

# 6. Run streaming benchmark inference
echo " Running benchmark inference for provider ${LK_PROVIDER}..."
python run_tool_benchmark_all_released.py --provider "${LK_PROVIDER}"

# 7. Run evaluation
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
echo " Running evaluation..."

USE_LLM_FLAG=""
if [ -n "${OPENAI_API_KEY:-}" ]; then
    USE_LLM_FLAG="--use-llm"
    echo " OPENAI_API_KEY detected: running LLM Judge (GPT-4o) evaluation."
else
    echo "ℹ️ Running evaluation in exact-match mode (no paid OpenAI key needed)."
fi

python evaluate_tool_calls.py \
    --benchmark benchmark_data_v2.json \
    --results-dir fdb_v3_data_released \
    --provider "${LK_PROVIDER}" \
    --output "${SCRIPT_DIR}/logs/${LK_PROVIDER}_eval_${TIMESTAMP}.json" \
    ${USE_LLM_FLAG}

python evaluate_pass_rate.py \
    --benchmark benchmark_data_v2.json \
    --results-dir fdb_v3_data_released \
    --provider "${LK_PROVIDER}" \
    --output "${SCRIPT_DIR}/logs/${LK_PROVIDER}_pass_rate_${TIMESTAMP}.json" \
    ${USE_LLM_FLAG}

echo "======================================================================"
echo " Evaluation complete! Results saved in ${SCRIPT_DIR}/logs/"
echo "======================================================================"
