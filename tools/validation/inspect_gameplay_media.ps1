param(
    [string]$Ffmpeg = 'C:\Users\dayw9\.cache\codex-runtimes\codex-primary-runtime\dependencies\python\Lib\site-packages\imageio_ffmpeg\binaries\ffmpeg-win-x86_64-v7.1.exe',
    [int]$Ticks = 600
)
$ErrorActionPreference = 'Stop'
$TaskRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$TaskEvidence = Join-Path $TaskRoot 'evidence'
$TaskMp4 = Join-Path $TaskEvidence 'integration/gameplay.mp4'
$TaskProbe = & $Ffmpeg -hide_banner -i $TaskMp4 -af volumedetect -vn -sn -f null NUL 2>&1
if ($LASTEXITCODE -ne 0) { throw 'Captured media decoding failed.' }
$TaskProbeText = ($TaskProbe | ForEach-Object { $_.ToString() }) -join "`n"
$TaskProbeText | Set-Content -LiteralPath (Join-Path $TaskEvidence 'gameplay_media.log')
$TaskVideo = [regex]::Match($TaskProbeText, 'Video:[^\r\n]*? ([1-9]\d{2,4})x([1-9]\d{2,4})[ ,][^\r\n]*? ([\d.]+) fps')
$TaskMean = [regex]::Match($TaskProbeText, 'mean_volume: (-?[\d.]+) dB')
$TaskPeak = [regex]::Match($TaskProbeText, 'max_volume: (-?[\d.]+) dB')
if (-not $TaskVideo.Success -or -not $TaskMean.Success -or -not $TaskPeak.Success) { throw 'Missing video dimensions or finite audio levels.' }
$TaskMeanDb = [double]::Parse($TaskMean.Groups[1].Value, [cultureinfo]::InvariantCulture)
$TaskPeakDb = [double]::Parse($TaskPeak.Groups[1].Value, [cultureinfo]::InvariantCulture)
if ($TaskPeakDb -ge 0 -or $TaskMeanDb -lt -65) { throw "Mixed recording is clipped or near-silent: mean=$TaskMeanDb peak=$TaskPeakDb dBFS" }
[ordered]@{
    verified_at_utc = [DateTime]::UtcNow.ToString('o')
    file = $TaskMp4
    sha256 = (Get-FileHash -LiteralPath $TaskMp4 -Algorithm SHA256).Hash
    bytes = (Get-Item -LiteralPath $TaskMp4).Length
    simulation_ticks = $Ticks
    encoded_width = [int]$TaskVideo.Groups[1].Value
    encoded_height = [int]$TaskVideo.Groups[2].Value
    capture_fps = [double]$TaskVideo.Groups[3].Value
    renderer = 'Forward+'
    audio_mean_dbfs = $TaskMeanDb
    audio_peak_dbfs = $TaskPeakDb
    passed = $true
    conditions = 'Actual seeded four-CPU Party gameplay, High, original mixed game audio. Movie writer initializes at the logical 1600x900 viewport before the game window becomes 1920x1080. Encoded dimensions are measured above. Offline movie capture is not a performance benchmark.'
    scope = 'Decoded complete video/audio; non-silent and below full scale in this capture. No subjective listening-quality claim.'
    media_probe = 'gameplay_media.log'
} | ConvertTo-Json | Set-Content -LiteralPath (Join-Path $TaskEvidence 'gameplay_capture.json')
Write-Output "MEDIA PASS: $($TaskVideo.Groups[1].Value)x$($TaskVideo.Groups[2].Value) at $($TaskVideo.Groups[3].Value) fps, mean $TaskMeanDb / peak $TaskPeakDb dBFS."
