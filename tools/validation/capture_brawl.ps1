[CmdletBinding()]
param(
    [string]$Godot = 'D:\Game Engines\Godot\Godot_v4.7.2-stable_win64_console.exe',
    [string]$Ffmpeg = 'C:\Users\dayw9\.cache\codex-runtimes\codex-primary-runtime\dependencies\python\Lib\site-packages\imageio_ffmpeg\binaries\ffmpeg-win-x86_64-v7.1.exe',
    [ValidateRange(600,3600)][int]$Ticks = 900,
    [ValidateSet('rooftop_riot','lunar_reach','verdant_shrine','abyssal_observatory','ember_foundry')][string[]]$Arenas = @('rooftop_riot','lunar_reach'),
    [string]$Output = ''
)
$ErrorActionPreference = 'Stop'
$taskRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$taskProject = Join-Path $taskRoot 'Game File'
if (-not $Output) { $Output = Join-Path $taskRoot 'evidence/rebuild/brawl' }
foreach ($taskArena in $Arenas) {
    $taskOutput = Join-Path $Output $taskArena
    New-Item -ItemType Directory -Path $taskOutput -Force | Out-Null
    $taskAvi = Join-Path $taskOutput 'brawl.avi'
    $taskMp4 = Join-Path $taskOutput 'brawl.mp4'
    $taskLog = Join-Path $taskOutput 'capture.log'
    $taskStarted = [DateTime]::UtcNow
    $taskFreshPaths = @($taskAvi, $taskLog, (Join-Path $taskOutput 'smoke_runtime.json'), (Join-Path $taskOutput 'brawl.png'))
    $taskPreviousWrites = @{}
    foreach ($taskPath in $taskFreshPaths) {
        if (Test-Path -LiteralPath $taskPath) { $taskPreviousWrites[$taskPath] = (Get-Item -LiteralPath $taskPath).LastWriteTimeUtc }
    }
    # --profile selects reproducible in-memory High/1080p settings. Movie timing
    # includes readback and encoding and must never be used as a performance result.
    & $Godot --path $taskProject --resolution 1920x1080 --write-movie $taskAvi --fixed-fps 60 --log-file $taskLog -- --smoke --profile "--frames=$Ticks" "--arena=$taskArena" "--evidence-root=$taskOutput" --capture-tick=450 --screenshot=brawl.png
    if ($LASTEXITCODE -ne 0) { throw "Brawl recording failed: $taskArena" }
    foreach ($taskPath in $taskFreshPaths) {
        $taskFile = Get-Item -LiteralPath $taskPath
        if ($taskFile.Length -eq 0 -or $taskFile.LastWriteTimeUtc -lt $taskStarted -or ($taskPreviousWrites.ContainsKey($taskPath) -and $taskFile.LastWriteTimeUtc -le $taskPreviousWrites[$taskPath])) { throw "Brawl output not regenerated: $taskPath" }
    }
    if (Select-String -LiteralPath $taskLog -Pattern 'ERROR:|SCRIPT ERROR:|Parse Error|WARNING:') { throw "Brawl recording logged a problem: $taskArena" }
    $taskReport = Get-Content -LiteralPath (Join-Path $taskOutput 'smoke_runtime.json') -Raw | ConvertFrom-Json
    if ($taskReport.arena -ne $taskArena -or $taskReport.ticks -lt $Ticks -or $taskReport.fighters.Count -ne 4 -or $taskReport.contacts -lt 1) { throw "Incomplete four-player recording: $taskArena" }
    if (-not $taskReport.profile_mode -or $taskReport.settings.graphics -ne 'High' -or $taskReport.captured_pixel_size -ne '(1920, 1080)') { throw "Brawl did not render High at 1080p: $taskArena" }
    & $Ffmpeg -hide_banner -loglevel error -y -i $taskAvi -c:v libx264 -crf 19 -pix_fmt yuv420p -c:a aac -movflags +faststart $taskMp4
    if ($LASTEXITCODE -ne 0) { throw "Brawl encoding failed: $taskArena" }
    & $Ffmpeg -hide_banner -loglevel error -y -i $taskMp4 -vf 'setpts=2*PTS' -af 'atempo=0.5' -c:v libx264 -crf 19 -pix_fmt yuv420p -c:a aac -movflags +faststart (Join-Path $taskOutput 'brawl_half_speed.mp4')
    if ($LASTEXITCODE -ne 0) { throw "Brawl slow-motion encoding failed: $taskArena" }
    & $Ffmpeg -hide_banner -loglevel error -i $taskMp4 -f null -
    if ($LASTEXITCODE -ne 0) { throw "Brawl full decode failed: $taskArena" }
    & $Ffmpeg -hide_banner -loglevel error -i (Join-Path $taskOutput 'brawl_half_speed.mp4') -f null -
    if ($LASTEXITCODE -ne 0) { throw "Brawl slow-motion decode failed: $taskArena" }
    [ordered]@{started_utc=$taskStarted.ToString('o');finished_utc=[DateTime]::UtcNow.ToString('o');requested_arena=$taskArena;ticks=$taskReport.ticks;contacts=$taskReport.contacts;passed=$true;files=@('brawl.mp4','brawl_half_speed.mp4','brawl.png','smoke_runtime.json') | ForEach-Object { $taskFile = Get-Item -LiteralPath (Join-Path $taskOutput $_); [ordered]@{file=$taskFile.Name;bytes=$taskFile.Length;sha256=(Get-FileHash -LiteralPath $taskFile.FullName).Hash} };scope='Continuous four-CPU movie; screenshot arena requires visual inspection. Movie recording costs are not performance evidence.'} | ConvertTo-Json -Depth 6 | Set-Content -LiteralPath (Join-Path $taskOutput 'capture_validation.json')
    Write-Output $taskOutput
}
