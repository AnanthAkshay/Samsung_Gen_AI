Add-Type -AssemblyName System.Speech

$phrases = [ordered]@{
    "clip1" = "Navigate to Koramangala. No wait, take me to Indiranagar instead."
    "clip2" = "Take me to the airport. Actually, cancel that."
    "clip3" = "Navigate to M G Road. Um, hold on. Yes, M G Road."
}

foreach ($name in $phrases.Keys) {
    $rawPath = "a:\Samsung_2\demo\clips\${name}_raw.wav"
    $outPath = "a:\Samsung_2\demo\clips\${name}.wav"
    Write-Host "Synthesizing $name : $($phrases[$name])"
    $synth = New-Object System.Speech.Synthesis.SpeechSynthesizer
    $synth.SetOutputToWaveFile($rawPath)
    $synth.Speak($phrases[$name])
    $synth.Dispose()
    
    # Resample to 48kHz mono 16-bit PCM WAV
    & ffmpeg -y -i $rawPath -ar 48000 -ac 1 -c:a pcm_s16le $outPath
    Remove-Item $rawPath -Force
}

Get-ChildItem "a:\Samsung_2\demo\clips\*.wav" | Select-Object Name, Length
