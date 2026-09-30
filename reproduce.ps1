# ==============================================================================
# Full-Duplex-Bench v3: End-to-End Reproduction Script (PowerShell / Windows)
# ==============================================================================
$ErrorActionPreference = "Stop"

Write-Host "======================================================================" -ForegroundColor Cyan
Write-Host "Starting Full-Duplex-Bench v3 Reproduction Pipeline (Gemini Native)" -ForegroundColor Cyan
Write-Host "======================================================================" -ForegroundColor Cyan

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$V3Dir = Join-Path $ScriptDir "Full-Duplex-Bench\v3"
$VenvPython = Join-Path $ScriptDir "venv\Scripts\python.exe"

# 1. Environment validation
$EnvLocalPath = Join-Path $V3Dir ".env.local"
$EnvPath = Join-Path $ScriptDir ".env"

if (Test-Path $EnvPath -and -not (Test-Path $EnvLocalPath)) {
    Copy-Item $EnvPath $EnvLocalPath
}

if (Test-Path $EnvLocalPath) {
    Get-Content $EnvLocalPath | ForEach-Object {
        $line = $_.Trim()
        if ($line -and -not $line.StartsWith("#") -and $line.Contains("=")) {
            $parts = $line.Split("=", 2)
            [Environment]::SetEnvironmentVariable($parts[0].Trim(), $parts[1].Trim(), "Process")
        }
    }
}

if (-not $env:GOOGLE_API_KEY) {
    Write-Host "❌ Error: GOOGLE_API_KEY is not set. Get one for free at https://aistudio.google.com/" -ForegroundColor Red
    exit 1
}

if (-not $env:LIVEKIT_URL -or -not $env:LIVEKIT_API_KEY -or -not $env:LIVEKIT_API_SECRET) {
    Write-Host "❌ Error: LiveKit credentials missing." -ForegroundColor Red
    exit 1
}

$Provider = if ($env:LK_PROVIDER) { $env:LK_PROVIDER } else { "gemini2_5" }
$env:LK_PROVIDER = $Provider
Write-Host " Model Provider: $Provider" -ForegroundColor Green

# 2. Check benchmark audio dataset
$DataDir = Join-Path $V3Dir "fdb_v3_data_released"
if (-not (Test-Path $DataDir)) {
    Write-Host "📥 Extracting benchmark data..." -ForegroundColor Yellow
    $zipPath = Join-Path $V3Dir "fdb_v3_data.zip"
    & $VenvPython -c "import zipfile; zipfile.ZipFile(r'$zipPath', 'r').extractall(r'$V3Dir')"
}

# 3. Start Gemini Live agent worker in the background
Write-Host " Starting Gemini Live agent worker..." -ForegroundColor Yellow
$AgentProcess = Start-Process -FilePath $VenvPython -ArgumentList "lk_agent_tool.py start" -WorkingDirectory $V3Dir -PassThru
Start-Sleep -Seconds 5

try {
    # 4. Run streaming benchmark inference
    Write-Host " Running benchmark inference for provider: $Provider..." -ForegroundColor Cyan
    Push-Location $V3Dir
    & $VenvPython run_tool_benchmark_all_released.py --provider $Provider
    Pop-Location

    # 5. Run evaluation
    $Timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
    $EvalReport = Join-Path $ScriptDir "logs\${Provider}_eval_${Timestamp}.json"
    $PassReport = Join-Path $ScriptDir "logs\${Provider}_pass_rate_${Timestamp}.json"

    $useLlmArgs = @()
    if ($env:OPENAI_API_KEY) {
        $useLlmArgs = @("--use-llm")
        Write-Host " OPENAI_API_KEY detected: Running LLM Judge (GPT-4o)." -ForegroundColor Green
    } else {
        Write-Host "ℹ️ Running evaluation in exact-match mode (no paid OpenAI key required)." -ForegroundColor Yellow
    }

    Push-Location $V3Dir
    & $VenvPython evaluate_tool_calls.py --benchmark benchmark_data_v2.json --results-dir fdb_v3_data_released --provider $Provider --output $EvalReport @useLlmArgs
    & $VenvPython evaluate_pass_rate.py --benchmark benchmark_data_v2.json --results-dir fdb_v3_data_released --provider $Provider --output $PassReport @useLlmArgs
    Pop-Location

    Write-Host " Evaluation complete! Reports saved to logs\" -ForegroundColor Green
}
finally {
    Write-Host " Stopping agent worker process..." -ForegroundColor Yellow
    Stop-Process -Id $AgentProcess.Id -Force -ErrorAction SilentlyContinue
}
