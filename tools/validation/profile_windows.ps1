param(
    [string]$Godot = 'D:\Game Engines\Godot\Godot_v4.7.2-stable_win64_console.exe',
    [int]$Ticks = 3600,
    [ValidateSet('forward','mobile')][string[]]$Profiles = @('forward','mobile')
)
$ErrorActionPreference = 'Stop'
$TaskRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$TaskProject = Join-Path $TaskRoot 'Game File'
$TaskEvidence = Join-Path $TaskRoot 'evidence'
foreach ($TaskProfile in @(@{Id='forward'; Renderer='forward_plus'}, @{Id='mobile'; Renderer='mobile'})) {
    if ($TaskProfile.Id -notin $Profiles) { continue }
    $TaskLog = Join-Path $TaskEvidence ('performance_' + $TaskProfile.Id + '.log')
    $TaskReport = Join-Path $TaskEvidence ('performance_' + $TaskProfile.Id + '.json')
    # Request readback at the start of warmup. Spikes caused by a capture are
    # explicitly tagged if unusually slow loading moves it into measurement.
    $TaskStartTime = (Get-Date).ToUniversalTime()
    & $Godot --path $TaskProject --rendering-method $TaskProfile.Renderer --disable-vsync --max-fps 0 --log-file $TaskLog -- --smoke --profile "--frames=$Ticks" '--capture-tick=1' ("--screenshot=integration/performance_" + $TaskProfile.Id + '.png')
    if ($LASTEXITCODE -ne 0) { throw "Profile process failed: $($TaskProfile.Id)" }
    $TaskErrors = Select-String -LiteralPath $TaskLog -Pattern 'ERROR:|SCRIPT ERROR:|Parse Error|WARNING:'
    if ($TaskErrors) { throw "Profile logged errors/warnings: $($TaskProfile.Id). See $TaskLog" }
    if (-not (Select-String -LiteralPath $TaskLog -SimpleMatch 'SMOKE_REPORT') -or (Get-Item -LiteralPath (Join-Path $TaskEvidence 'smoke_runtime.json')).LastWriteTimeUtc -lt $TaskStartTime) { throw "Profile exited without a fresh complete report: $($TaskProfile.Id)" }
    Copy-Item -LiteralPath (Join-Path $TaskEvidence 'smoke_runtime.json') -Destination $TaskReport
    $TaskData = Get-Content -LiteralPath $TaskReport -Raw | ConvertFrom-Json
    if (-not $TaskData.profile_mode -or $TaskData.captured_pixel_size -ne '(1920, 1080)' -or $TaskData.renderer -ne $TaskProfile.Renderer -or $TaskData.sample_count -lt 3000 -or $TaskData.sample_clock -notlike 'Time.get_ticks_usec*') {
        throw "Unexpected profile conditions in $TaskReport"
    }
    if ([math]::Abs($TaskData.sample_sum_ms - $TaskData.sample_window_ms) -gt 0.1) { throw "Frame samples do not cover their recorded wall interval: $TaskReport" }
    $TaskData | Add-Member -NotePropertyName measured_started_utc -NotePropertyValue $TaskStartTime.ToString('o') -Force
    $TaskData | Add-Member -NotePropertyName measured_finished_utc -NotePropertyValue (Get-Date).ToUniversalTime().ToString('o') -Force
    $TaskData | ConvertTo-Json -Depth 12 | Set-Content -LiteralPath $TaskReport
    Write-Output ("{0}: {1}ms mean, {2}ms p95, {3}ms p99; {4} frames over 16.667ms out of {5}" -f $TaskProfile.Id, $TaskData.mean_frame_ms, $TaskData.p95_frame_ms, $TaskData.p99_frame_ms, $TaskData.frames_over_16_667ms, $TaskData.sample_count)
}
