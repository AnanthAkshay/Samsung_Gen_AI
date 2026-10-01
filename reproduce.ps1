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

# 1. Create the Python 3.10 environment and install pinned dependencies
if (-not (Test-Path $VenvPython)) {
    py -3.10 -m venv (Join-Path $ScriptDir "venv")
    if ($LASTEXITCODE -ne 0) { throw "Could not create the Python 3.10 virtual environment." }
}
& $VenvPython -m pip install --upgrade pip
if ($LASTEXITCODE -ne 0) { throw "Could not upgrade pip." }
& $VenvPython -m pip install "livekit-agents[google]~=1.3" "livekit-plugins-google==1.8.3" "livekit[crypto]~=1.0" "pydub==0.25.1" "ffmpeg-python==0.2.0" "python-dotenv==1.2.3" "gdown==6.4.0" "numpy==2.2.6" "nemo_toolkit[asr]==3.0.0"
if ($LASTEXITCODE -ne 0) { throw "Could not install reproduction dependencies." }

# 2. Environment validation
$EnvLocalPath = Join-Path $V3Dir ".env.local"
$EnvPath = Join-Path $ScriptDir ".env"

if ((Test-Path $EnvPath) -and -not (Test-Path $EnvLocalPath)) {
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
    Write-Host "Error: GOOGLE_API_KEY is not set. Get one for free at https://aistudio.google.com/" -ForegroundColor Red
    exit 1
}

if (-not $env:LIVEKIT_URL -or -not $env:LIVEKIT_API_KEY -or -not $env:LIVEKIT_API_SECRET) {
    Write-Host "Error: LiveKit credentials missing." -ForegroundColor Red
    exit 1
}

$Provider = if ($env:LK_PROVIDER) { $env:LK_PROVIDER } else { "gemini2_5" }
$env:LK_PROVIDER = $Provider
Write-Host " Model Provider: $Provider" -ForegroundColor Green

# 3. Check benchmark audio dataset
$DataDir = Join-Path $V3Dir "fdb_v3_data_released"
if (-not (Test-Path $DataDir)) {
    Write-Host "Downloading benchmark data..." -ForegroundColor Yellow
    $zipPath = Join-Path $V3Dir "fdb_v3_data.zip"
    & $VenvPython -m gdown 1SO_4MTazWQ_jvCx0dtmpQ-t40bdd07yz -O $zipPath
    if ($LASTEXITCODE -ne 0) { throw "Could not download benchmark audio." }
    Expand-Archive -Path $zipPath -DestinationPath $V3Dir -Force
}

# 4. Start Gemini Live agent worker in the background
Write-Host " Starting Gemini Live agent worker..." -ForegroundColor Yellow
$AgentProcess = Start-Process -FilePath $VenvPython -ArgumentList "lk_agent_tool.py start" -WorkingDirectory $V3Dir -PassThru
Start-Sleep -Seconds 5

try {
    # 5. Run streaming benchmark inference
    Write-Host " Running benchmark inference for provider: $Provider..." -ForegroundColor Cyan
    Push-Location $V3Dir
    try {
        & $VenvPython run_tool_benchmark_all_released.py --provider $Provider --force
        if ($LASTEXITCODE -ne 0) { throw "Benchmark inference failed." }
    }
    finally { Pop-Location }

    # 6. Save exact-match evaluator reports and the combined run summary
    $Timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
    $RunId = "baseline_$Timestamp"
    $RunDir = Join-Path $ScriptDir "logs\$RunId"
    New-Item -ItemType Directory -Force -Path $RunDir | Out-Null
    $SnapshotDir = Join-Path $RunDir "fdb_v3_data_released"
    Get-ChildItem $DataDir -Recurse -File -Filter "result_${Provider}.json" | ForEach-Object {
        $relativePath = $_.FullName.Substring($DataDir.Length + 1)
        $snapshotFile = Join-Path $SnapshotDir $relativePath
        New-Item -ItemType Directory -Force -Path (Split-Path -Parent $snapshotFile) | Out-Null
        Copy-Item $_.FullName $snapshotFile -Force
    }
    $EvalReport = Join-Path $RunDir "tool_calls_report.json"
    $PassReport = Join-Path $RunDir "pass_rate_report.json"
    $SummaryReport = Join-Path $RunDir "summary_metrics.json"

    Push-Location $V3Dir
    try {
        & $VenvPython evaluate_tool_calls.py --benchmark benchmark_data_v2.json --results-dir $SnapshotDir --provider $Provider --output $EvalReport
        if ($LASTEXITCODE -ne 0) { throw "Tool-call evaluation failed." }
        & $VenvPython evaluate_pass_rate.py --benchmark benchmark_data_v2.json --results-dir $SnapshotDir --provider $Provider --output $PassReport
        if ($LASTEXITCODE -ne 0) { throw "Pass-rate evaluation failed." }
        & $VenvPython summarize_evaluation.py --pass-rate-report $PassReport --tool-calls-report $EvalReport --output $SummaryReport --run-id $RunId --provider $Provider
        if ($LASTEXITCODE -ne 0) { throw "Summary generation failed; the run may be incomplete." }
    }
    finally { Pop-Location }

    Write-Host " Evaluation complete! Reports and summary saved to $RunDir" -ForegroundColor Green
}
finally {
    Write-Host " Stopping agent worker process..." -ForegroundColor Yellow
    Stop-Process -Id $AgentProcess.Id -Force -ErrorAction SilentlyContinue
}
