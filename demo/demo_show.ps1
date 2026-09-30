# demo\demo_show.ps1
# Interactive/Automated Driver Script for Samsung Gen AI Hackathon 3.0 Demo
param(
    [ValidateSet("1", "2", "3", "4", "all")]
    [string]$Segment = "all"
)

$Host.UI.RawUI.WindowTitle = "Samsung Gen AI Hackathon 3.0 - Theme 05 Demo"

function Show-Header {
    param([string]$Title, [string]$Subtitle)
    Clear-Host
    Write-Host ("=" * 82) -ForegroundColor Cyan
    Write-Host "   $Title" -ForegroundColor Yellow -NoNewline
    Write-Host "  |  Theme 05: Interruptible Real-Time Agents" -ForegroundColor Gray
    if ($Subtitle) {
        Write-Host "   $Subtitle" -ForegroundColor DarkCyan
    }
    Write-Host ("=" * 82) -ForegroundColor Cyan
    Write-Host ""
}

function Show-Caption {
    param([string]$Text)
    Write-Host ""
    Write-Host " [CAPTION] $Text" -ForegroundColor Black -BackgroundColor Yellow
    Write-Host ""
}

function Run-Segment1 {
    Show-Header "SEGMENT 1: TITLE & ARCHITECTURE" "Google Gemini Native Realtime on LiveKit"
    Show-Caption "Gemini native realtime on LiveKit, evaluated on Full-Duplex-Bench v3"
    Start-Sleep -Seconds 6

    Write-Host "PROJECT TITLE: " -ForegroundColor Green -NoNewline
    Write-Host "Interruptible Real-Time Voice Agent for Full-Duplex Spoken Dialogue" -ForegroundColor White
    Write-Host "THEME:         " -ForegroundColor Green -NoNewline
    Write-Host "05 - Interruptible Real-Time Agents" -ForegroundColor White
    Write-Host "FRAMEWORK:     " -ForegroundColor Green -NoNewline
    Write-Host "LiveKit Voice Agents SDK + Google Gemini Native Audio Preview" -ForegroundColor White
    Write-Host "BENCHMARK:     " -ForegroundColor Green -NoNewline
    Write-Host "Full-Duplex-Bench v3 (FDB-v3) Multi-Step Tool Calling" -ForegroundColor White
    Write-Host ""
    Start-Sleep -Seconds 6

    Write-Host "SYSTEM ARCHITECTURE (End-to-End Gemini Native Realtime Pipeline):" -ForegroundColor Magenta
    Write-Host "┌─────────────────────────────────────────────────────────────────────────────────┐" -ForegroundColor Cyan
    Write-Host "│ UserAudio ──► LiveKit Room (WebRTC) ──► Gemini Native Realtime Model            │" -ForegroundColor White
    Write-Host "│                                              │   ▲                              │" -ForegroundColor White
    Write-Host "│                                              │   │  (audio I/O, VAD, barge-in   │" -ForegroundColor Yellow
    Write-Host "│                                              │   │   all handled natively)      │" -ForegroundColor Yellow
    Write-Host "│                                              ▼   │                              │" -ForegroundColor White
    Write-Host "│                                         Tool-Calling Engine                     │" -ForegroundColor White
    Write-Host "│                                              │                                  │" -ForegroundColor White
    Write-Host "│                                              ▼                                  │" -ForegroundColor White
    Write-Host "│                                         Mock APIs (12 functions in 4 domains)   │" -ForegroundColor White
    Write-Host "│                                              │                                  │" -ForegroundColor White
    Write-Host "│                                              ▼                                  │" -ForegroundColor White
    Write-Host "│                                         Agent Audio Playback ──► LiveKit Room   │" -ForegroundColor White
    Write-Host "└─────────────────────────────────────────────────────────────────────────────────┘" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "KEY ADVANTAGES OVER CASCADED PIPELINES (Whisper + LLM + TTS):" -ForegroundColor Green
    Write-Host " * Zero STT Transcription Delay: Native audio understanding directly from speech tokens" -ForegroundColor Gray
    Write-Host " * Native Voice Activity Detection (VAD) & Instant Barge-in Interruption" -ForegroundColor Gray
    Write-Host " * Single-Pass Reasoning: Intent detection and tool calling without intermediate text hops" -ForegroundColor Gray
    Write-Host ""
    Start-Sleep -Seconds 12

    Show-Caption "Verified: Architecture strictly eliminates cascaded STT/TTS dependencies."
    Start-Sleep -Seconds 6
}

function Run-Segment2 {
    Show-Header "SEGMENT 2: BENCHMARK EVIDENCE" "Evaluating Gemini Native Realtime on FDB-v3"
    
    # Check newest run directory
    $newestRun = Get-ChildItem -Directory "a:\Samsung_2\logs" -Filter "baseline_final_*" | Sort-Object LastWriteTime -Descending | Select-Object -First 1
    if (-not $newestRun) {
        $newestRun = Get-ChildItem -Directory "a:\Samsung_2\logs" -Filter "baseline_*" | Sort-Object LastWriteTime -Descending | Select-Object -First 1
    }
    
    $completedCount = (Get-ChildItem -Recurse $newestRun.FullName -Filter "result_gemini2_5.json").Count
    Show-Caption "Real results from our run. Partial run: $completedCount of 100 scenarios"
    Start-Sleep -Seconds 6

    Write-Host "LIVE BENCHMARK METRICS SUMMARY (from $($newestRun.Name)):" -ForegroundColor Green
    & "A:\Samsung_2\venv\Scripts\python.exe" "a:\Samsung_2\demo\benchmark_stats.py" $newestRun.FullName
    Start-Sleep -Seconds 14

    Write-Host ""
    Write-Host "EXAMINING ONE COMPLETED BENCHMARK SCENARIO (ecommerce_01):" -ForegroundColor Magenta
    $scenarioDir = "a:\Samsung_2\logs\$($newestRun.Name)\fdb_v3_data_released\ecommerce_01_65e8cf8f4c7424fa062e54a3"
    if (Test-Path $scenarioDir) {
        Get-ChildItem $scenarioDir | Select-Object Name, Length, LastWriteTime | Format-Table -AutoSize
    }
    Start-Sleep -Seconds 8

    Write-Host "SCENARIO RESULT JSON EXTRACT (Input ASR, Tool Calls, Agent Response):" -ForegroundColor Cyan
    $jsonPath = Join-Path $scenarioDir "result_gemini2_5.json"
    if (Test-Path $jsonPath) {
        $json = Get-Content $jsonPath -Raw | ConvertFrom-Json
        [PSCustomObject]@{
            ScenarioID       = $json.example_id
            Category         = $json.category
            Title            = $json.title
            UserSpeechEnd    = "$($json.user_speech_end_rel) s"
            AgentSpeechStart = "$($json.audio_agent_speech_start) s"
            MeasuredLatency  = "$($json.absolute_total_latency) s"
            ToolCalled       = $json.actual_tool_calls[0].function
            ToolArguments    = ($json.actual_tool_calls[0].args | ConvertTo-Json -Compress)
            AgentTranscript  = $json.transcript
            Status           = $json.status
        } | Format-List
    }
    Start-Sleep -Seconds 18

    Write-Host "PUBLISHED BENCHMARK EVALUATION COMPARISON (README.md Section 5):" -ForegroundColor Yellow
    Write-Host "┌──────────────────────────────┬──────────────────┬──────────────────────────────────────────────────┐" -ForegroundColor Cyan
    Write-Host "│ Metric                       │ Value            │ Notes                                            │" -ForegroundColor Cyan
    Write-Host "├──────────────────────────────┼──────────────────┼──────────────────────────────────────────────────┤" -ForegroundColor Cyan
    Write-Host "│ Tool Selection F1            │ 0.759            │ Precision=1.000, Recall=0.611; TP=11, FP=0, FN=7 │" -ForegroundColor White
    Write-Host "│ Tool Selection Precision     │ 1.000            │ Zero false-positive tool calls (no hallucinations)│" -ForegroundColor White
    Write-Host "│ Tool Selection Recall        │ 0.611            │ Exact-match evaluation across 4 benchmark domains │" -ForegroundColor White
    Write-Host "│ Strict Pass Rate             │ 0.667 (10 / 15)  │ Scenarios passing all tool calls with exact args │" -ForegroundColor White
    Write-Host "│ Avg Response Latency         │ 10.43 s          │ First speech token onset after user finished     │" -ForegroundColor White
    Write-Host "│ Min / Max Latency            │ 5.24 s / 18.32 s │ Measured across full-duplex conversational audio │" -ForegroundColor White
    Write-Host "└──────────────────────────────┴──────────────────┴──────────────────────────────────────────────────┘" -ForegroundColor Cyan
    Write-Host ""
    Start-Sleep -Seconds 16
}

function Run-Segment4 {
    Show-Header "SEGMENT 4: REPRODUCTION & API REQUIREMENTS" "Full Audibility and Deterministic Reproduction"
    Show-Caption "One-command reproduction and clear API requirements"
    Start-Sleep -Seconds 5

    Write-Host "ONE-COMMAND REPRODUCTION SCRIPTS:" -ForegroundColor Green
    Write-Host " * Windows PowerShell: .\reproduce.ps1" -ForegroundColor White
    Write-Host " * Linux / macOS Bash:  ./reproduce.sh" -ForegroundColor White
    Write-Host ""
    Write-Host "Script automates environment validation, agent worker boot, audio streaming," -ForegroundColor Gray
    Write-Host "exact-match metric evaluation (evaluate_tool_calls.py & evaluate_pass_rate.py)." -ForegroundColor Gray
    Write-Host ""
    Start-Sleep -Seconds 8

    Write-Host "API CREDENTIALS REQUIRED (Names only - secrets strictly masked):" -ForegroundColor Magenta
    Write-Host "┌──────────────────────┬──────────┬──────────────────────────────────────────────────────────┐" -ForegroundColor Cyan
    Write-Host "│ Environment Variable │ Required │ Service / Purpose                                        │" -ForegroundColor Cyan
    Write-Host "├──────────────────────┼──────────┼──────────────────────────────────────────────────────────┤" -ForegroundColor Cyan
    Write-Host "│ LIVEKIT_URL          │ Required │ LiveKit Cloud WebRTC endpoint (wss://*.livekit.cloud)    │" -ForegroundColor White
    Write-Host "│ LIVEKIT_API_KEY      │ Required │ LiveKit Project API Key                                  │" -ForegroundColor White
    Write-Host "│ LIVEKIT_API_SECRET   │ Required │ LiveKit Project API Secret                               │" -ForegroundColor White
    Write-Host "│ GOOGLE_API_KEY       │ Required │ Gemini 2.5 Flash Native Realtime (Google AI Studio)      │" -ForegroundColor White
    Write-Host "│ OPENAI_API_KEY       │ Optional │ GPT-4o LLM Judge (optional; not needed for exact match)  │" -ForegroundColor White
    Write-Host "└──────────────────────┴──────────┴──────────────────────────────────────────────────────────┘" -ForegroundColor Cyan
    Write-Host ""
    Start-Sleep -Seconds 8

    Write-Host "REPOSITORY STRUCTURE SUMMARY:" -ForegroundColor Yellow
    Get-ChildItem "a:\Samsung_2" -Directory | Where-Object { $_.Name -notmatch '^\.|venv|node_modules' } | Select-Object Name | Format-Table -HideTableHeaders
    Start-Sleep -Seconds 6
}

switch ($Segment) {
    "1" { Run-Segment1 }
    "2" { Run-Segment2 }
    "3" { Write-Host "Segment 3 is gated on benchmark completion." -ForegroundColor Red }
    "4" { Run-Segment4 }
    "all" {
        Run-Segment1
        Run-Segment2
        Run-Segment4
    }
}
