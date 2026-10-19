[CmdletBinding()]
param([string]$Ffmpeg = 'C:\Users\dayw9\.cache\codex-runtimes\codex-primary-runtime\dependencies\python\Lib\site-packages\imageio_ffmpeg\binaries\ffmpeg-win-x86_64-v7.1.exe')
$ErrorActionPreference = 'Stop'
$taskRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$taskOutput = Join-Path $taskRoot 'evidence/rebuild/comparison'
New-Item -ItemType Directory -Path $taskOutput -Force | Out-Null
$taskCases = @(
    @{ id='f01_clutch'; baseline='evidence/rebuild/baseline/clutch_motion/motion.mp4' },
    @{ id='f03_heavy_duty'; baseline='evidence/rebuild/baseline/motion/f03_heavy_duty_right/motion.mp4' }
)
$taskGraph = @'
[0:v]trim=duration=12,setpts=PTS-STARTPTS,scale=960:540,drawbox=x=0:y=0:w=iw:h=42:color=black@0.7:t=fill,drawtext=fontfile='C\:/Windows/Fonts/arial.ttf':text='BEFORE':x=20:y=10:fontsize=24:fontcolor=white[before];
[1:v]trim=duration=12,setpts=PTS-STARTPTS,scale=960:540,drawbox=x=0:y=0:w=iw:h=42:color=black@0.7:t=fill,drawtext=fontfile='C\:/Windows/Fonts/arial.ttf':text='REBUILD':x=20:y=10:fontsize=24:fontcolor=white[after];
[before][after]hstack=inputs=2[v]
'@
$taskFilter = Join-Path $taskOutput 'comparison.ffmpeg'
[IO.File]::WriteAllText($taskFilter, $taskGraph, [Text.UTF8Encoding]::new($false))
foreach ($taskCase in $taskCases) {
    $taskBefore = Join-Path $taskRoot $taskCase.baseline
    $taskAfter = Join-Path $taskRoot ('evidence/rebuild/motion/' + $taskCase.id + '_right/motion.mp4')
    $taskNormal = Join-Path $taskOutput ($taskCase.id + '.mp4')
    & $Ffmpeg -hide_banner -loglevel error -y -i $taskBefore -i $taskAfter -filter_complex_script $taskFilter -map '[v]' -map '1:a?' -t 12 -c:v libx264 -crf 19 -pix_fmt yuv420p -c:a aac -movflags +faststart $taskNormal
    if ($LASTEXITCODE -ne 0) { throw "Comparison failed: $($taskCase.id)" }
    & $Ffmpeg -hide_banner -loglevel error -y -i $taskNormal -vf 'setpts=2*PTS' -af 'atempo=0.5' -c:v libx264 -crf 19 -pix_fmt yuv420p -c:a aac -movflags +faststart (Join-Path $taskOutput ($taskCase.id + '_half_speed.mp4'))
    if ($LASTEXITCODE -ne 0) { throw "Slow comparison failed: $($taskCase.id)" }
    & $Ffmpeg -hide_banner -loglevel error -i $taskNormal -f null -
    if ($LASTEXITCODE -ne 0) { throw "Comparison full-decode failed: $($taskCase.id)" }
}
Write-Output $taskOutput
