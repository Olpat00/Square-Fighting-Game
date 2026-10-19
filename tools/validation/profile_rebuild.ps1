[CmdletBinding()]
param(
    [string]$Godot = 'D:\Game Engines\Godot\Godot_v4.7.2-stable_win64_console.exe',
    [ValidateRange(5, 180)][int]$Seconds = 60,
    [ValidateRange(0, 240)][int]$RenderCap = 0,
    [string]$Output = '',
    [string]$Project = '',
    [ValidateSet('rooftop_riot','lunar_reach','verdant_shrine','abyssal_observatory','ember_foundry')][string[]]$Arenas = @('rooftop_riot','lunar_reach'),
    [ValidateSet('High','Low')][string[]]$Qualities = @('High','Low'),
    [ValidateSet(2,4)][int[]]$Players = @(2,4)
)
$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'release_provenance.ps1')
$taskRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
if (-not $Project) { $Project = Join-Path $taskRoot 'Game File' }
$Project = [IO.Path]::GetFullPath($Project)
if (-not $Output) { $Output = Join-Path $taskRoot ('evidence/rebuild/performance/' + (Get-Date -Format 'yyyyMMdd-HHmmss')) }
$Output = [IO.Path]::GetFullPath($Output)
New-Item -ItemType Directory -Path $Output -Force | Out-Null
$taskRunStarted = [DateTime]::UtcNow
# Hashing runs before and after all engine processes, outside timing windows.
$taskSourceBefore = Get-ReleaseRuntimeInventory $Project
$taskArtBefore = Get-ReleaseProjectArt $Project
$taskHarness = Join-Path $PSScriptRoot 'rebuild_performance.gd'
$taskHarnessHash = (Get-FileHash -LiteralPath $taskHarness -Algorithm SHA256).Hash
$taskReports = @()
$taskCases = @()

function Invoke-BoundedProfileProcess([string]$CaseName, [string]$EngineLog, [DateTime]$Started) {
    $taskNativeLog = Join-Path $Output ($CaseName + '.native.log')
    $taskFailurePath = Join-Path $Output ($CaseName + '.process_failure.json')
    $taskPriorLogWrite = if (Test-Path -LiteralPath $EngineLog -PathType Leaf) { (Get-Item -LiteralPath $EngineLog).LastWriteTimeUtc } else { $null }
    $taskTimeoutSeconds = $Seconds + 90
    $taskInfo = [Diagnostics.ProcessStartInfo]::new()
    $taskInfo.FileName = $Godot
    $taskInfo.WorkingDirectory = $Project
    $taskInfo.UseShellExecute = $false
    $taskInfo.CreateNoWindow = $true
    $taskInfo.RedirectStandardOutput = $true
    $taskInfo.RedirectStandardError = $true
    # ArgumentList preserves spaces/literal characters without shell interpolation.
    foreach ($taskArgument in @('--path', $Project, '--script', $taskHarness, '--log-file', $EngineLog, '--', "--arena=$taskArena", "--quality=$taskQuality", "--players=$taskPlayers", "--seconds=$Seconds", "--render-cap=$RenderCap", "--output=$Output")) {
        $taskInfo.ArgumentList.Add($taskArgument)
    }
    $taskProcess = [Diagnostics.Process]::new()
    $taskProcess.StartInfo = $taskInfo
    $taskStartedProcess = $false
    $taskTimedOut = $false
    $taskExitCode = $null
    $taskNativeText = ''
    $taskStdout = $null
    $taskStderr = $null
    $taskFailure = $null
    try {
        if (-not $taskProcess.Start()) { throw "Profile process did not start: $CaseName" }
        $taskStartedProcess = $true
        $taskStdout = $taskProcess.StandardOutput.ReadToEndAsync()
        $taskStderr = $taskProcess.StandardError.ReadToEndAsync()
        if (-not $taskProcess.WaitForExit($taskTimeoutSeconds * 1000)) {
            $taskTimedOut = $true
            # Kill only this runner's process tree, including any crash-dialog helper.
            $taskProcess.Kill($true)
            if (-not $taskProcess.WaitForExit(5000)) { throw "Profile process tree did not exit after timeout termination: $CaseName" }
        }
        $taskExitCode = $taskProcess.ExitCode
        $taskDrain = [Threading.Tasks.Task]::WhenAll([Threading.Tasks.Task[]]@($taskStdout, $taskStderr))
        if (-not $taskDrain.Wait(5000)) { throw "Profile output streams did not close: $CaseName" }
        $taskNativeText = "STDOUT:`n" + $taskStdout.GetAwaiter().GetResult() + "`nSTDERR:`n" + $taskStderr.GetAwaiter().GetResult()
        [IO.File]::WriteAllText($taskNativeLog, $taskNativeText, [Text.UTF8Encoding]::new($false))
        if ($taskTimedOut) { throw "Profile timed out after $taskTimeoutSeconds seconds: $CaseName" }
        if ($taskExitCode -ne 0) { throw "Profile exited unsuccessfully with code ${taskExitCode}: $CaseName" }
        if (-not (Test-Path -LiteralPath $EngineLog -PathType Leaf)) { throw "Profile engine log missing: $EngineLog" }
        $taskLogItem = Get-Item -LiteralPath $EngineLog
        if ($taskLogItem.Length -eq 0 -or $taskLogItem.LastWriteTimeUtc -lt $Started.AddSeconds(-2) -or ($taskPriorLogWrite -and $taskLogItem.LastWriteTimeUtc -le $taskPriorLogWrite)) { throw "Profile engine log was not freshly generated: $EngineLog" }
        $taskAllOutput = $taskNativeText + "`nENGINE LOG:`n" + [IO.File]::ReadAllText($EngineLog)
        if ($taskAllOutput -match '(?im)\b(?:SCRIPT ERROR|Parse Error|ERROR)\s*:|^\s*WARNING\s*:|\b(?:VK_ERROR_DEVICE_LOST|GPU is lost|device (?:was )?lost|FATAL|CRASH)\b') { throw "Profile logged an engine/native problem: $EngineLog (see $taskNativeLog)" }
    } catch {
        $taskFailure = $_.Exception.Message
        throw
    } finally {
        if ($taskStartedProcess -and -not $taskProcess.HasExited) {
            try { $taskProcess.Kill($true); $null = $taskProcess.WaitForExit(5000) }
            catch { $taskNativeText += "`nOWNED PROCESS CLEANUP: " + $_.Exception.Message }
        }
        # Preserve available output even if a crashed child kept an output pipe open.
        if ([string]::IsNullOrEmpty($taskNativeText)) {
            if ($taskStdout -and $taskStdout.IsCompletedSuccessfully) { $taskNativeText += "STDOUT:`n" + $taskStdout.GetAwaiter().GetResult() }
            if ($taskStderr -and $taskStderr.IsCompletedSuccessfully) { $taskNativeText += "`nSTDERR:`n" + $taskStderr.GetAwaiter().GetResult() }
            if ([string]::IsNullOrEmpty($taskNativeText)) { $taskNativeText = 'Native streams did not produce completed output before the bounded process/stream timeout.' }
        }
        [IO.File]::WriteAllText($taskNativeLog, $taskNativeText, [Text.UTF8Encoding]::new($false))
        if ($taskFailure) {
            [ordered]@{
                passed=$false;case=$CaseName;arena=$taskArena;quality=$taskQuality;players=$taskPlayers
                started_utc=$Started.ToString('o');finished_utc=[DateTime]::UtcNow.ToString('o')
                executable=$Godot;arguments=@($taskInfo.ArgumentList);exit_code=$taskExitCode
                timed_out=$taskTimedOut;timeout_seconds=$taskTimeoutSeconds;problem=$taskFailure
                engine_log=$EngineLog;native_log=$taskNativeLog
                native_log_sha256=(Get-FileHash -LiteralPath $taskNativeLog -Algorithm SHA256).Hash
                scope='Failed or incomplete graphical process; no performance acceptance. Existing engine logs, reports and captures remain available for diagnosis.'
            } | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath $taskFailurePath
        }
        $taskProcess.Dispose()
    }
}

foreach ($taskArena in $Arenas) {
    foreach ($taskQuality in $Qualities) {
        foreach ($taskPlayers in $Players) {
            $taskName = '{0}_{1}_{2}p' -f $taskArena,$taskQuality.ToLower(),$taskPlayers
            $taskLog = Join-Path $Output ($taskName + '.log')
            $taskStarted = [DateTime]::UtcNow
            Write-Host "Profiling $taskName for $Seconds seconds..."
            Invoke-BoundedProfileProcess $taskName $taskLog $taskStarted
            $taskPath = Join-Path $Output ($taskName + '.json')
            if ((Get-Item -LiteralPath $taskPath).LastWriteTimeUtc -lt $taskStarted) { throw "Stale profile: $taskName" }
            $taskData = Get-Content -LiteralPath $taskPath -Raw | ConvertFrom-Json
            if ($taskData.arena -ne $taskArena -or $taskData.quality -ne $taskQuality -or $taskData.players -ne $taskPlayers) { throw "Profile case differs from requested case: $taskName" }
            if ($taskData.render_cap -ne $RenderCap -or $taskData.vsync -ne 'disabled') { throw "Profile render rate differs from requested rate: $taskName" }
            if ($taskData.duration_seconds -lt ($Seconds - 1) -or $taskData.readback_inside_sample_window -ne $false) { throw "Invalid profile sample window: $taskName" }
            if ($taskData.captured_pixels -ne '(1920, 1080)' -or $taskData.frame_intervals.count -lt 100 -or -not $taskData.viewport_render_gpu.available) { throw "Missing graphical timing evidence: $taskName" }
            if ($taskData.simulation_ticks_in_sample_window -lt $Seconds * 55) { throw "Combat did not advance throughout the profile: $taskName" }
            $taskReports += [pscustomobject]@{case=$taskName;file=$taskPath;frame_p95_ms=$taskData.frame_intervals.p95_ms;frame_p99_ms=$taskData.frame_intervals.p99_ms;gpu_p95_ms=$taskData.viewport_render_gpu.p95_ms;cpu_p95_ms=$taskData.viewport_render_cpu.p95_ms;peak_draws=$taskData.peak_draws}
            $taskCases += [ordered]@{case=$taskName;file=($taskName + '.json');sha256=(Get-FileHash -LiteralPath $taskPath -Algorithm SHA256).Hash;arena=$taskArena;quality=$taskQuality;players=$taskPlayers;requested_seconds=$Seconds;render_cap=$RenderCap;vsync='disabled';started_utc=$taskStarted.ToString('o')}
        }
    }
}
$taskSourceAfter = Get-ReleaseRuntimeInventory $Project
$taskArtAfter = Get-ReleaseProjectArt $Project
if ($taskSourceBefore.sha256 -ne $taskSourceAfter.sha256) { throw 'Runtime source changed during profiling.' }
if ($taskArtBefore.present -ne $taskArtAfter.present -or $taskArtBefore.sha256 -ne $taskArtAfter.sha256) { throw 'Project art report changed during profiling.' }
if ((Get-FileHash -LiteralPath $taskHarness -Algorithm SHA256).Hash -ne $taskHarnessHash) { throw 'Performance harness changed during profiling.' }
foreach ($taskCase in $taskCases) {
    if ((Get-FileHash -LiteralPath (Join-Path $Output $taskCase.file) -Algorithm SHA256).Hash -ne $taskCase.sha256) { throw "Profile report changed during run: $($taskCase.file)" }
}
$taskProvenance = [ordered]@{passed=$true;started_utc=$taskRunStarted.ToString('o');finished_utc=[DateTime]::UtcNow.ToString('o');runtime=$taskSourceBefore;art=$taskArtBefore;harness_sha256=$taskHarnessHash;render_cap=$RenderCap;vsync='disabled';unchanged_during_profiling=$true;cases=$taskCases}
$taskProvenance | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath (Join-Path $Output 'profile_provenance.json')
$taskReports | ConvertTo-Json -Depth 4 | Set-Content -LiteralPath (Join-Path $Output 'summary.json')
$taskReports | Format-Table -AutoSize
