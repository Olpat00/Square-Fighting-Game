param(
    [string]$Godot = 'D:\Game Engines\Godot\Godot_v4.7.2-stable_win64_console.exe',
    [string]$Ffmpeg = 'C:\Users\dayw9\.cache\codex-runtimes\codex-primary-runtime\dependencies\python\Lib\site-packages\imageio_ffmpeg\binaries\ffmpeg-win-x86_64-v7.1.exe',
    [int]$Ticks = 600
)
$ErrorActionPreference = 'Stop'
$TaskRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$TaskEvidence = Join-Path $TaskRoot 'evidence'
$TaskCapture = Join-Path $TaskEvidence 'integration'
New-Item -ItemType Directory -Path $TaskCapture -Force | Out-Null
$TaskAvi = Join-Path $TaskCapture 'gameplay.avi'
$TaskMp4 = Join-Path $TaskCapture 'gameplay.mp4'
$TaskLog = Join-Path $TaskEvidence 'gameplay_capture.log'
& $Godot --path (Join-Path $TaskRoot 'Game File') --write-movie $TaskAvi --fixed-fps 60 --log-file $TaskLog -- --smoke --profile "--frames=$Ticks"
if ($LASTEXITCODE -ne 0) { throw 'Godot movie capture failed.' }
if (Select-String -LiteralPath $TaskLog -Pattern 'ERROR:|SCRIPT ERROR:|Parse Error|WARNING:') { throw "Unexpected log message: $TaskLog" }
& $Ffmpeg -hide_banner -loglevel warning -y -i $TaskAvi -c:v libx264 -crf 21 -pix_fmt yuv420p -c:a aac -b:a 192k -movflags +faststart $TaskMp4
if ($LASTEXITCODE -ne 0) { throw 'MP4 conversion failed.' }
& (Join-Path $PSScriptRoot 'inspect_gameplay_media.ps1') -Ffmpeg $Ffmpeg -Ticks $Ticks
Write-Output $TaskMp4
