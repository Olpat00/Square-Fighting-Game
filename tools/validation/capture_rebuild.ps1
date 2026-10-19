[CmdletBinding()]
param(
    [string]$Godot = 'D:\Game Engines\Godot\Godot_v4.7.2-stable_win64_console.exe',
    [string]$Ffmpeg = 'C:\Users\dayw9\.cache\codex-runtimes\codex-primary-runtime\dependencies\python\Lib\site-packages\imageio_ffmpeg\binaries\ffmpeg-win-x86_64-v7.1.exe',
    [string]$Project = '',
    [string]$Output = '',
    [string[]]$Fighters = @('f01_clutch','f03_heavy_duty'),
    [ValidateSet('rooftop_riot','lunar_reach')][string]$Arena = 'rooftop_riot',
    [switch]$Mirror,
    [switch]$SlowMotion
)
$ErrorActionPreference = 'Stop'
$taskRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
if (-not $Project) { $Project = Join-Path $taskRoot 'Game File' }
if (-not $Output) { $Output = Join-Path $taskRoot 'evidence/rebuild/motion' }
$Output = [IO.Path]::GetFullPath($Output)
foreach ($taskFighter in $Fighters) {
    if ($taskFighter -notmatch '^f0[1-8]_[a-z_]+$') { throw "Invalid fighter ID: $taskFighter" }
    $taskCase = $taskFighter + $(if ($Mirror) { '_left' } else { '_right' })
    $taskFolder = Join-Path $Output $taskCase
    New-Item -ItemType Directory -Path $taskFolder -Force | Out-Null
    $taskAvi = Join-Path $taskFolder 'motion.avi'
    $taskLog = Join-Path $taskFolder 'capture.log'
    $taskArgs = @('--path', $Project, '--script', (Join-Path $PSScriptRoot 'rebuild_motion_review.gd'), '--write-movie', $taskAvi, '--fixed-fps', '60', '--log-file', $taskLog, '--', "--fighter=$taskFighter", "--arena=$Arena", "--output=$taskFolder")
    if ($Mirror) { $taskArgs += '--mirror' }
    & $Godot @taskArgs
    if ($LASTEXITCODE -ne 0) { throw "Movie capture failed: $taskCase" }
    if (Select-String -LiteralPath $taskLog -Pattern 'ERROR:|SCRIPT ERROR:|Parse Error|WARNING:') { throw "Movie capture logged a problem: $taskLog" }
    & $Ffmpeg -hide_banner -loglevel warning -y -i $taskAvi -c:v libx264 -crf 19 -pix_fmt yuv420p -c:a aac -b:a 192k -movflags +faststart (Join-Path $taskFolder 'motion.mp4')
    if ($LASTEXITCODE -ne 0) { throw "Movie conversion failed: $taskCase" }
    if ($SlowMotion) {
        & $Ffmpeg -hide_banner -loglevel warning -y -i $taskAvi -vf 'setpts=2.0*PTS' -af 'atempo=0.5' -c:v libx264 -crf 19 -pix_fmt yuv420p -c:a aac -movflags +faststart (Join-Path $taskFolder 'motion_half_speed.mp4')
        if ($LASTEXITCODE -ne 0) { throw "Slow-motion conversion failed: $taskCase" }
    }
    & $Ffmpeg -hide_banner -loglevel error -i (Join-Path $taskFolder 'motion.mp4') -f null -
    if ($LASTEXITCODE -ne 0) { throw "Full movie decode failed: $taskCase" }
    Write-Output $taskFolder
}
