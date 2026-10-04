# Backward compatibility redirect to repo root reproduce.ps1
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
& (Join-Path $ScriptDir "..\reproduce.ps1") @args
