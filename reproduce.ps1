<#
.SYNOPSIS
    End-to-end FDB-v3 reproduction for Windows PowerShell (Team Cache_Me).

.PARAMETER Limit
    First N scenarios (default 100).

.PARAMETER NoLlmJudge
    Exact-match scoring only (skip OpenAI gpt-4o judge).

.PARAMETER Force
    Re-run inference even when result JSON already exists.
#>
[CmdletBinding()]
param (
    [Parameter(Mandatory=$false)]
    [Alias("l", "n")]
    [int]$Limit = 100,

    [Parameter(Mandatory=$false)]
    [switch]$NoLlmJudge,

    [Parameter(Mandatory=$false)]
    [switch]$Force
)

$ErrorActionPreference = "Stop"
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$UseLlmJudge = -not $NoLlmJudge

$env:PYTHONUTF8 = "1"
$env:PYTHONIOENCODING = "utf-8"

Write-Host "======================================================================" -ForegroundColor Cyan
Write-Host " Samsung Gen AI Hackathon 3.0 (Theme 05: Interruptible Real-Time Agents)" -ForegroundColor Cyan
Write-Host " Reproduction Pipeline: Google Gemini Native Realtime + LiveKit Agents" -ForegroundColor Cyan
Write-Host " Benchmark: Full-Duplex-Bench v3 (arXiv:2604.04847) [Limit: $Limit]" -ForegroundColor Cyan
if ($UseLlmJudge) {
    Write-Host " Judge: ENABLED (OpenAI gpt-4o via FDB-v3 --use-llm)" -ForegroundColor Cyan
} else {
    Write-Host " Judge: DISABLED (exact-match only)" -ForegroundColor Cyan
}
Write-Host "======================================================================" -ForegroundColor Cyan

function Get-PythonMinor([string]$Exe, [string[]]$PrefixArgs) {
    try {
        if ($PrefixArgs.Count -gt 0) {
            $out = & $Exe @PrefixArgs -c "import sys; print(f'{sys.version_info.major}.{sys.version_info.minor}')" 2>$null
        } else {
            $out = & $Exe -c "import sys; print(f'{sys.version_info.major}.{sys.version_info.minor}')" 2>$null
        }
        return "$out".Trim()
    } catch {
        return ""
    }
}

Write-Host "`n[1/7] Verifying Python 3.10-3.12 environment..." -ForegroundColor Yellow

$PythonLaunch = $null
$supported = @("3.12", "3.11", "3.10")

if (Get-Command py -ErrorAction SilentlyContinue) {
    foreach ($ver in $supported) {
        $got = Get-PythonMinor "py" @("-$ver")
        if ($supported -contains $got) {
            $PythonLaunch = @{ Exe = "py"; Args = @("-$ver") }
            Write-Host "  Using py -$ver ($got)"
            break
        }
    }
}

if (-not $PythonLaunch) {
    foreach ($name in @("python3.12", "python3.11", "python3.10", "python3", "python")) {
        if (Get-Command $name -ErrorAction SilentlyContinue) {
            $got = Get-PythonMinor $name @()
            if ($supported -contains $got) {
                $PythonLaunch = @{ Exe = $name; Args = @() }
                Write-Host "  Using $name ($got)"
                break
            }
        }
    }
}

if (-not $PythonLaunch) {
    Write-Host "Error: Python 3.10, 3.11, or 3.12 is required." -ForegroundColor Red
    Write-Host "Install 64-bit Python and ensure 'py -3.12' or 'python' is on PATH." -ForegroundColor Red
    exit 1
}

if (-not (Get-Command ffmpeg -ErrorAction SilentlyContinue)) {
    Write-Host "Error: ffmpeg is not on PATH." -ForegroundColor Red
    Write-Host "Install: winget install Gyan.FFmpeg   then reopen the terminal." -ForegroundColor Yellow
    exit 1
}

$VenvDir = Join-Path $ScriptDir ".venv"
if (-not (Test-Path $VenvDir) -and (Test-Path (Join-Path $ScriptDir "venv"))) {
    $VenvDir = Join-Path $ScriptDir "venv"
}
$VenvPython = Join-Path $VenvDir "Scripts\python.exe"

if (-not (Test-Path $VenvPython)) {
    Write-Host "  Creating isolated virtual environment at $VenvDir..." -ForegroundColor Yellow
    if ($PythonLaunch.Args.Count -gt 0) {
        & $PythonLaunch.Exe @($PythonLaunch.Args + @("-m", "venv", $VenvDir))
    } else {
        & $PythonLaunch.Exe -m venv $VenvDir
    }
    if ($LASTEXITCODE -ne 0) {
        Write-Host "Failed to create virtual environment." -ForegroundColor Red
        exit 1
    }
}

Write-Host "  Installing torch (CUDA or CPU), then pinned requirements, then NeMo..." -ForegroundColor Yellow
& $VenvPython (Join-Path $ScriptDir "scripts\install_deps.py")
if ($LASTEXITCODE -ne 0) {
    Write-Host "Failed to install dependencies." -ForegroundColor Red
    exit 1
}
Write-Host "  Dependencies installed." -ForegroundColor Green

Write-Host "`n[2/7] Validating credentials and configuration..." -ForegroundColor Yellow

$EnvPath = Join-Path $ScriptDir ".env"
$V3Dir = Join-Path $ScriptDir "Full-Duplex-Bench\v3"
$EnvLocalPath = Join-Path $V3Dir ".env.local"

if (-not (Test-Path $EnvPath) -and -not (Test-Path $EnvLocalPath)) {
    Write-Host "Error: Neither .env nor Full-Duplex-Bench/v3/.env.local was found." -ForegroundColor Red
    Write-Host "Copy .env.example to .env and set LIVEKIT_*, GOOGLE_API_KEY, and OPENAI_API_KEY." -ForegroundColor Red
    exit 1
}

$ActiveEnvFile = if (Test-Path $EnvPath) { $EnvPath } else { $EnvLocalPath }
Get-Content $ActiveEnvFile | ForEach-Object {
    $line = $_.Trim()
    if ($line -and -not $line.StartsWith("#") -and $line.Contains("=")) {
        $parts = $line.Split("=", 2)
        $k = $parts[0].Trim()
        $v = $parts[1].Trim()
        if ($k) {
            [Environment]::SetEnvironmentVariable($k, $v, "Process")
        }
    }
}

if (Test-Path $EnvPath) {
    Copy-Item $EnvPath $EnvLocalPath -Force
}

$MissingKeys = @()
foreach ($key in @("LIVEKIT_URL", "LIVEKIT_API_KEY", "LIVEKIT_API_SECRET", "GOOGLE_API_KEY")) {
    $val = [Environment]::GetEnvironmentVariable($key, "Process")
    if (-not $val -or $val.Trim() -eq "" -or $val.StartsWith("your_")) {
        $MissingKeys += $key
    }
}
if ($UseLlmJudge) {
    $oai = [Environment]::GetEnvironmentVariable("OPENAI_API_KEY", "Process")
    if (-not $oai -or $oai.Trim() -eq "" -or $oai.StartsWith("your_")) {
        $MissingKeys += "OPENAI_API_KEY"
    }
}

if ($MissingKeys.Count -gt 0) {
    Write-Host "Error: Missing required credentials in .env:" -ForegroundColor Red
    foreach ($m in $MissingKeys) {
        Write-Host "  - $m" -ForegroundColor Red
    }
    Write-Host "LiveKit: https://cloud.livekit.io" -ForegroundColor Yellow
    Write-Host "Google AI Studio: https://aistudio.google.com" -ForegroundColor Yellow
    if ($UseLlmJudge) {
        Write-Host "OpenAI (FDB-v3 gpt-4o judge): https://platform.openai.com" -ForegroundColor Yellow
        Write-Host "Offline smoke test: .\reproduce.ps1 -Limit 3 -NoLlmJudge" -ForegroundColor Yellow
    }
    exit 1
}

$Provider = if ($env:LK_PROVIDER) { $env:LK_PROVIDER } else { "gemini2_5" }
$env:LK_PROVIDER = $Provider
Write-Host "  Required credentials present. Provider: $Provider" -ForegroundColor Green

Write-Host "`n[3/7] Verifying benchmark audio dataset..." -ForegroundColor Yellow
$DataDir = Join-Path $V3Dir "fdb_v3_data_released"
$ZipPath = Join-Path $V3Dir "fdb_v3_data.zip"
$DriveId = "1SO_4MTazWQ_jvCx0dtmpQ-t40bdd07yz"

$needData = -not (Test-Path $DataDir) -or ((Get-ChildItem $DataDir -Directory -ErrorAction SilentlyContinue | Measure-Object).Count -eq 0)
if ($needData) {
    if (Test-Path $ZipPath) {
        Write-Host "  Extracting $ZipPath..." -ForegroundColor Yellow
        Expand-Archive -Path $ZipPath -DestinationPath $V3Dir -Force
    } else {
        Write-Host "  Downloading benchmark dataset via gdown..." -ForegroundColor Yellow
        & $VenvPython -m gdown $DriveId -O $ZipPath
        if ($LASTEXITCODE -ne 0 -or -not (Test-Path $ZipPath)) {
            Write-Host "Automated dataset download failed." -ForegroundColor Red
            Write-Host "Manual download:" -ForegroundColor Yellow
            Write-Host "  1. https://drive.google.com/file/d/$DriveId/view?usp=sharing" -ForegroundColor Cyan
            Write-Host "  2. Save as fdb_v3_data.zip and place at: $ZipPath" -ForegroundColor Yellow
            Write-Host "  3. Extract so $DataDir contains per-scenario folders with input.wav" -ForegroundColor Yellow
            Write-Host "See Full-Duplex-Bench/v3/README.md (Data section)." -ForegroundColor Yellow
            exit 1
        }
        Expand-Archive -Path $ZipPath -DestinationPath $V3Dir -Force
    }
}

$DatasetItemCount = (Get-ChildItem $DataDir -Directory).Count
Write-Host "  Benchmark audio ready ($DatasetItemCount scenario directories)." -ForegroundColor Green

Write-Host "`n[4/7] Launching Gemini Native Realtime agent worker (lk_agent_tool.py)..." -ForegroundColor Yellow

$AgentLogPath = Join-Path $ScriptDir "logs"
New-Item -ItemType Directory -Force -Path $AgentLogPath | Out-Null
$AgentStdout = Join-Path $AgentLogPath "gemini2_5_agent.stdout.log"
$AgentStderr = Join-Path $AgentLogPath "gemini2_5_agent.stderr.log"

try {
    New-Item -ItemType Directory -Force -Path "C:\tmp" | Out-Null
} catch {}

$AgentProcess = Start-Process -FilePath $VenvPython `
    -ArgumentList "lk_agent_tool.py start" `
    -WorkingDirectory $V3Dir `
    -RedirectStandardOutput $AgentStdout `
    -RedirectStandardError $AgentStderr `
    -PassThru

Start-Sleep -Seconds 6

if ($AgentProcess.HasExited) {
    Write-Host "Agent worker failed to start. Error log:" -ForegroundColor Red
    if (Test-Path $AgentStderr) { Get-Content $AgentStderr -Tail 20 }
    exit 1
}

Write-Host "  Agent worker running with PID $($AgentProcess.Id)." -ForegroundColor Green

try {
    Write-Host "`n[5/7] Executing streaming benchmark inference with Limit $Limit..." -ForegroundColor Yellow
    Write-Host "  Resume: existing completed result files are skipped unless -Force." -ForegroundColor Yellow
    Push-Location $V3Dir
    try {
        $benchmarkArgs = @("run_tool_benchmark_all_released.py", "--provider", $Provider, "--limit", "$Limit")
        if ($Force) { $benchmarkArgs += "--force" }
        & $VenvPython $benchmarkArgs
        if ($LASTEXITCODE -ne 0) {
            throw "Benchmark batch inference exited with code $LASTEXITCODE."
        }
    } finally {
        Pop-Location
    }
    Write-Host "  Streaming inference completed." -ForegroundColor Green

    Write-Host "`n[6/7] Evaluating tool selection, pass rate, and latency..." -ForegroundColor Yellow
    $Timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
    $RunId = "baseline_$Timestamp"
    $ResultsDir = Join-Path $ScriptDir "results\$RunId"
    New-Item -ItemType Directory -Force -Path $ResultsDir | Out-Null

    $scoreArgs = @(
        (Join-Path $ScriptDir "scripts\run_scoring.py"),
        "--python", $VenvPython,
        "--v3-dir", $V3Dir,
        "--data-dir", $DataDir,
        "--results-dir", $ResultsDir,
        "--provider", $Provider,
        "--run-id", $RunId,
        "--limit", "$Limit"
    )
    if ($UseLlmJudge) { $scoreArgs += "--use-llm-judge" }
    & $VenvPython $scoreArgs
    if ($LASTEXITCODE -ne 0) { throw "Scoring failed." }

    $ConfigSrc = Join-Path $ScriptDir "agent_config.json"
    if (Test-Path $ConfigSrc) {
        Copy-Item $ConfigSrc (Join-Path $ResultsDir "agent_config.json") -Force
    }
    Copy-Item $AgentStdout (Join-Path $ResultsDir "agent.stdout.log") -Force
    Copy-Item $AgentStderr (Join-Path $ResultsDir "agent.stderr.log") -Force

    $LatestDir = Join-Path $ScriptDir "results\latest"
    if (Test-Path $LatestDir) { Remove-Item -Recurse -Force $LatestDir }
    New-Item -ItemType Directory -Force -Path $LatestDir | Out-Null
    Copy-Item "$ResultsDir\*" $LatestDir -Recurse -Force

    Write-Host "`n[7/7] Reproduction completed." -ForegroundColor Green
    Write-Host "======================================================================" -ForegroundColor Cyan
    Write-Host " Artifacts: $ResultsDir" -ForegroundColor Green
    $exact = Join-Path $ResultsDir "summary_exact_match.json"
    if (Test-Path $exact) {
        Write-Host " Exact-match summary:" -ForegroundColor Yellow
        Get-Content $exact | Write-Host
    }
    $llm = Join-Path $ResultsDir "summary_llm_judge.json"
    if (Test-Path $llm) {
        Write-Host " LLM-judge (gpt-4o) summary:" -ForegroundColor Yellow
        Get-Content $llm | Write-Host
    }
    Write-Host "======================================================================" -ForegroundColor Cyan
} finally {
    Write-Host "`nStopping background agent worker with PID $($AgentProcess.Id)..." -ForegroundColor Yellow
    Stop-Process -Id $AgentProcess.Id -Force -ErrorAction SilentlyContinue
}
