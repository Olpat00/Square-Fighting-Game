param([string]$Godot = 'D:\Game Engines\Godot\Godot_v4.7.2-stable_win64_console.exe', [int]$Ticks = 1200)
$ErrorActionPreference = 'Stop'
$TaskRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$TaskEvidence = Join-Path $TaskRoot 'evidence'
$TaskStates = @()
foreach ($TaskRate in @(30, 144)) {
    $TaskLog = Join-Path $TaskEvidence "render_rate_$TaskRate.log"
    & $Godot --headless --path (Join-Path $TaskRoot 'Game File') --fixed-fps $TaskRate --log-file $TaskLog -- --smoke "--frames=$Ticks"
    if ($LASTEXITCODE -ne 0) { throw "Render-rate run failed: $TaskRate" }
    if (Select-String -LiteralPath $TaskLog -Pattern 'ERROR:|SCRIPT ERROR:|Parse Error|WARNING:') { throw "Unexpected log message: $TaskLog" }
    $TaskReport = Join-Path $TaskEvidence "render_rate_$TaskRate.json"
    Copy-Item -LiteralPath (Join-Path $TaskEvidence 'smoke_runtime.json') -Destination $TaskReport
    $TaskData = Get-Content -LiteralPath $TaskReport -Raw | ConvertFrom-Json
    if ($TaskData.ticks -ne $Ticks) { throw "Unexpected simulation length at $TaskRate" }
    $TaskStates += ($TaskData | Select-Object ticks, contacts, kos, fighters | ConvertTo-Json -Depth 20 -Compress)
}
$TaskPassed = $TaskStates[0] -ceq $TaskStates[1]
[ordered]@{passed=$TaskPassed; measured_at=(Get-Date).ToString('o'); render_rates=@(30,144); ticks=$Ticks; compared=@('fighters damage/stocks/positions/states','contact count','KO log'); scope='Single machine, seeded four-CPU Party match. Headless fixed render deltas; no cross-platform determinism claim.'} | ConvertTo-Json -Depth 10 | Set-Content -LiteralPath (Join-Path $TaskEvidence 'render_rate_comparison.json')
if (-not $TaskPassed) { throw 'Authoritative state differed between fixed render deltas.' }
Write-Output "Render-rate comparison passed at $Ticks ticks."
