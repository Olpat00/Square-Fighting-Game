# Validate the exported PCK with the matching editor engine, then the actual release
# EXE through its default main scene. Release templates cannot run external scripts.
[CmdletBinding()]
param(
    [string]$BuildDirectory = '',
    [string]$Godot = 'D:\Game Engines\Godot\Godot_v4.7.2-stable_win64_console.exe',
    [ValidateRange(30, 1800)][int]$TimeoutSeconds = 180
)
$ErrorActionPreference = 'Stop'
$TaskRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$TaskProject = Join-Path $TaskRoot 'Game File'
if ([string]::IsNullOrWhiteSpace($BuildDirectory)) { $BuildDirectory = Join-Path $TaskRoot 'builds/windows' }
$TaskBuild = [IO.Path]::GetFullPath($BuildDirectory)
$TaskExe = Join-Path $TaskBuild 'RooftopRiot.exe'
$TaskPck = Join-Path $TaskBuild 'RooftopRiot.pck'
$TaskManifestPath = Join-Path $TaskBuild 'build_manifest.json'
$TaskHarness = Join-Path $PSScriptRoot 'ui_flow.gd'
$TaskEvidence = Join-Path $TaskRoot 'evidence/windows_release_flow'
$TaskSmokeEvidence = Join-Path $TaskEvidence 'release_smoke'
$TaskReportPath = Join-Path $TaskEvidence 'validation.json'
$TaskHistoricalPath = Join-Path $TaskEvidence 'historical_unsupported_override.json'
$TaskStarted = [DateTime]::UtcNow
$TaskUtf8 = [Text.UTF8Encoding]::new($false)
$TaskProblems = [Collections.Generic.List[string]]::new()
$TaskReport = [ordered]@{
    started_utc = $TaskStarted.ToString('o'); passed = $false
    build_unchanged_during_validation = $false
    runtime_source_hashes_verified_before = 0; runtime_source_hashes_verified_after = 0
    executable = $TaskExe; pck = $TaskPck
    pck_ui_harness = $null; release_executable_smoke = $null
}
New-Item -ItemType Directory -Path $TaskEvidence, $TaskSmokeEvidence -Force | Out-Null
function Get-LastWriteOrNull([string]$Path) {
    if (Test-Path -LiteralPath $Path -PathType Leaf) { return (Get-Item -LiteralPath $Path).LastWriteTimeUtc }
    return $null
}
function Assert-FreshFile([string]$Path, $PreviousWrite) {
    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) { throw "Missing output: $Path" }
    $TaskFile = Get-Item -LiteralPath $Path
    if ($TaskFile.Length -eq 0) { throw "Empty output: $Path" }
    if ($TaskFile.LastWriteTimeUtc -lt $TaskStarted.AddSeconds(-2)) { throw "Output predates this run: $Path" }
    if ($PreviousWrite -and $TaskFile.LastWriteTimeUtc -le $PreviousWrite) { throw "Output was not regenerated: $Path" }
}
function Get-PngEvidence([string]$Path, [string]$RelativePath, $PreviousWrite) {
    Assert-FreshFile $Path $PreviousWrite
    $TaskBytes = [IO.File]::ReadAllBytes($Path)
    if ($TaskBytes.Length -lt 24 -or [BitConverter]::ToString($TaskBytes, 0, 8) -ne '89-50-4E-47-0D-0A-1A-0A') { throw "Not a PNG header: $RelativePath" }
    $TaskWidth = [int]$TaskBytes[16] * 16777216 + [int]$TaskBytes[17] * 65536 + [int]$TaskBytes[18] * 256 + [int]$TaskBytes[19]
    $TaskHeight = [int]$TaskBytes[20] * 16777216 + [int]$TaskBytes[21] * 65536 + [int]$TaskBytes[22] * 256 + [int]$TaskBytes[23]
    if ($TaskWidth -lt 640 -or $TaskHeight -lt 360) { throw "Unexpected capture dimensions: $TaskWidth x $TaskHeight ($RelativePath)" }
    return [ordered]@{ path = $RelativePath; width = $TaskWidth; height = $TaskHeight; bytes = $TaskBytes.Length; sha256 = (Get-FileHash -LiteralPath $Path -Algorithm SHA256).Hash }
}
function Assert-SourceManifest {
    $TaskPrefix = [IO.Path]::GetFullPath($TaskProject).TrimEnd([char[]]@('\', '/')) + [IO.Path]::DirectorySeparatorChar
    $TaskSeen = [Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
    foreach ($TaskRecord in $TaskManifest.runtime_source_files) {
        $TaskPath = [IO.Path]::GetFullPath((Join-Path $TaskProject ([string]$TaskRecord.path)))
        if (-not $TaskPath.StartsWith($TaskPrefix, [StringComparison]::OrdinalIgnoreCase)) { throw "Manifest path leaves project: $($TaskRecord.path)" }
        if (-not $TaskSeen.Add($TaskPath)) { throw "Duplicate manifest path: $($TaskRecord.path)" }
        if ((Get-Item -LiteralPath $TaskPath).Length -ne $TaskRecord.bytes -or (Get-FileHash -LiteralPath $TaskPath -Algorithm SHA256).Hash -ne $TaskRecord.sha256) { throw "Source changed since export: $($TaskRecord.path)" }
    }
    # Same inventory rules as export_windows.ps1, including newly added files.
    $TaskCurrent = @(Get-ChildItem -LiteralPath $TaskProject -Recurse -File | Where-Object {
        $_.FullName -notmatch '[\\/]\.godot[\\/]' -and $_.Extension -in @('.gd','.gdshader','.godot','.tscn','.tres','.glb','.png','.jpg','.jpeg','.svg','.wav','.ogg','.json','.import','.uid','.cfg') -and $_.Name -notlike 'source_*' -and $_.Name -notin @('validate_input.gd','engine.png')
    })
    if ($TaskCurrent.Count -ne $TaskSeen.Count) { throw 'Runtime inventory differs from the exported manifest.' }
    foreach ($TaskFile in $TaskCurrent) { if (-not $TaskSeen.Contains($TaskFile.FullName)) { throw "Runtime source absent from manifest: $($TaskFile.FullName)" } }
    return $TaskSeen.Count
}
function Invoke-ValidationProcess([string]$Executable, [string]$Arguments, [string]$EngineLog, [string]$LogPath, [string]$Label) {
    $TaskPriorLog = Get-LastWriteOrNull $EngineLog
    $TaskInfo = [Diagnostics.ProcessStartInfo]::new()
    $TaskInfo.FileName = $Executable; $TaskInfo.Arguments = $Arguments
    $TaskInfo.WorkingDirectory = $TaskBuild; $TaskInfo.UseShellExecute = $false
    $TaskInfo.CreateNoWindow = $true; $TaskInfo.RedirectStandardOutput = $true; $TaskInfo.RedirectStandardError = $true
    $TaskProcess = [Diagnostics.Process]::new(); $TaskProcess.StartInfo = $TaskInfo
    $TaskStageStarted = [DateTime]::UtcNow; $TaskExit = -1; $TaskText = ''; $TaskTimedOut = $false
    try {
        if (-not $TaskProcess.Start()) { throw "$Label did not start." }
        $TaskStdout = $TaskProcess.StandardOutput.ReadToEndAsync()
        $TaskStderr = $TaskProcess.StandardError.ReadToEndAsync()
        if (-not $TaskProcess.WaitForExit($TimeoutSeconds * 1000)) {
            $TaskTimedOut = $true; $TaskProcess.Kill(); $TaskProcess.WaitForExit()
            $TaskProblems.Add("$Label timed out after $TimeoutSeconds seconds.")
        }
        $TaskText = $TaskStdout.GetAwaiter().GetResult() + [Environment]::NewLine + $TaskStderr.GetAwaiter().GetResult()
        $TaskExit = $TaskProcess.ExitCode
        if ($TaskExit -ne 0) { $TaskProblems.Add("$Label exited with code $TaskExit.") }
    } finally { $TaskProcess.Dispose() }
    try {
        Assert-FreshFile $EngineLog $TaskPriorLog
        $TaskText += [Environment]::NewLine + 'ENGINE LOG:' + [Environment]::NewLine + [IO.File]::ReadAllText($EngineLog)
    } catch { $TaskProblems.Add($_.Exception.Message) }
    [IO.File]::WriteAllText($LogPath, $TaskText, $TaskUtf8)
    $TaskLines = @($TaskText -split '\r?\n')
    $TaskErrors = @($TaskLines | Where-Object { $_ -match '(?i)\b(?:SCRIPT ERROR|Parse Error|ERROR)\s*:|^\s*UI_FAIL\b' } | Select-Object -Unique)
    $TaskWarnings = @($TaskLines | Where-Object { $_ -match '(?i)^\s*WARNING\s*:' } | Select-Object -Unique)
    foreach ($TaskLine in $TaskErrors + $TaskWarnings) { $TaskProblems.Add($Label + ': ' + $TaskLine.Trim()) }
    return [ordered]@{
        executable = $Executable; command = ('"{0}" {1}' -f $Executable, $Arguments)
        started_utc = $TaskStageStarted.ToString('o'); finished_utc = [DateTime]::UtcNow.ToString('o')
        exit_code = $TaskExit; timed_out = $TaskTimedOut; errors = $TaskErrors; warnings = $TaskWarnings
        engine_log = $EngineLog; log = $LogPath; text = $TaskText
    }
}
try {
    # Retain the failed unsupported release-template command unchanged as history.
    if ((Test-Path -LiteralPath $TaskReportPath) -and -not (Test-Path -LiteralPath $TaskHistoricalPath)) {
        if ((Get-Content -LiteralPath $TaskReportPath -Raw) -match 'compiled without support for path overrides') {
            Copy-Item -LiteralPath $TaskReportPath -Destination $TaskHistoricalPath
            foreach ($TaskName in 'engine.log', 'ui_flow.log') {
                $TaskOldLog = Join-Path $TaskEvidence $TaskName
                if (Test-Path -LiteralPath $TaskOldLog) { Copy-Item -LiteralPath $TaskOldLog -Destination (Join-Path $TaskEvidence "historical_unsupported_override_$TaskName") }
            }
        }
    }
    foreach ($TaskPath in $TaskExe, $TaskPck, $Godot, $TaskManifestPath, $TaskHarness) {
        if (-not (Test-Path -LiteralPath $TaskPath -PathType Leaf)) { throw "Required file missing: $TaskPath" }
        if ((Get-Item -LiteralPath $TaskPath).Length -eq 0) { throw "Required file empty: $TaskPath" }
        if ($TaskPath.Contains('"')) { throw 'Quoted paths cannot be passed safely to this process runner.' }
    }
    if (Test-Path -LiteralPath (Join-Path $TaskBuild 'project.godot')) { throw 'Build directory must not contain project.godot; the UI harness must load the explicit PCK.' }
    $TaskExeHash = (Get-FileHash -LiteralPath $TaskExe -Algorithm SHA256).Hash
    $TaskPckHash = (Get-FileHash -LiteralPath $TaskPck -Algorithm SHA256).Hash
    $TaskManifestHash = (Get-FileHash -LiteralPath $TaskManifestPath -Algorithm SHA256).Hash
    $TaskReport['executable_sha256'] = $TaskExeHash; $TaskReport['pck_sha256'] = $TaskPckHash; $TaskReport['build_manifest_sha256'] = $TaskManifestHash
    $TaskManifest = Get-Content -LiteralPath $TaskManifestPath -Raw | ConvertFrom-Json
    if (-not $TaskManifest.PSObject.Properties['build_timestamp_utc']) { throw 'Manifest omits build_timestamp_utc.' }
    # New PowerShell versions deserialize ISO strings to DateTime: preserve UTC kind.
    if ($TaskManifest.build_timestamp_utc -is [DateTime]) { $TaskTimestamp = $TaskManifest.build_timestamp_utc.ToUniversalTime().ToString('o') }
    elseif ($TaskManifest.build_timestamp_utc -is [DateTimeOffset]) { $TaskTimestamp = $TaskManifest.build_timestamp_utc.UtcDateTime.ToString('o') }
    else { $TaskTimestamp = [DateTimeOffset]::Parse([string]$TaskManifest.build_timestamp_utc).UtcDateTime.ToString('o') }
    $TaskReport['source_build_timestamp_utc'] = $TaskTimestamp
    $TaskReport['source_build_timestamp_origin'] = 'build_manifest.json build_timestamp_utc (UTC kind preserved)'
    if ($TaskManifest.exe_sha256 -ne $TaskExeHash -or $TaskManifest.pck_sha256 -ne $TaskPckHash) { throw 'Manifest hashes differ from EXE/PCK under test.' }
    if (-not $TaskManifest.PSObject.Properties['runtime_source_files'] -or @($TaskManifest.runtime_source_files).Count -eq 0) { throw 'Manifest omits runtime source hashes.' }
    $TaskGodotVersion = (& $Godot --version | Out-String).Trim()
    if ($LASTEXITCODE -ne 0 -or $TaskGodotVersion -ne $TaskManifest.engine_version) { throw 'Harness engine version differs from the export manifest.' }
    $TaskReport.runtime_source_hashes_verified_before = Assert-SourceManifest

    $TaskProblemStart = $TaskProblems.Count
    $TaskFlowPath = Join-Path $TaskEvidence 'ui_flow.json'
    $TaskPreviousFlow = Get-LastWriteOrNull $TaskFlowPath
    $TaskCaptureNames = @('title','selection','settings','training','training_tips_scale125','training_recording','training_replay','pause','results','title_scale125','selection_scale125','settings_scale125','four_player_scale125','results_scale125')
    $TaskFighterIds = @('f01_clutch','f02_sunstruck','f03_heavy_duty','f04_deadfall','f05_fine_print','f06_rugged_explorer','f07_urban_sentinel','f08_midnight_gentleman')
    $TaskArenaIds = @('rooftop_riot','lunar_reach','verdant_shrine','abyssal_observatory','ember_foundry')
    $TaskExpectedChecks = 38 + 5 * $TaskFighterIds.Count + 6 * $TaskArenaIds.Count
    foreach ($TaskFighter in $TaskFighterIds) { $TaskCaptureNames += ('roster_{0}_selection' -f $TaskFighter), ('roster_{0}_match' -f $TaskFighter) }
    foreach ($TaskArena in $TaskArenaIds) { $TaskCaptureNames += ('arena_{0}_selection' -f $TaskArena), ('arena_{0}_match' -f $TaskArena) }
    $TaskPreviousCaptures = @{}
    foreach ($TaskName in $TaskCaptureNames) { $TaskPreviousCaptures[$TaskName] = Get-LastWriteOrNull (Join-Path $TaskEvidence "integration/$TaskName.png") }
    $TaskEngineLog = Join-Path $TaskEvidence 'engine.log'
    $TaskArguments = '--path "{0}" --main-pack "{1}" --script "{2}" --rendering-method forward_plus --log-file "{3}" -- "--evidence-root={4}"' -f $TaskBuild, $TaskPck, $TaskHarness, $TaskEngineLog, $TaskEvidence.Replace('\','/')
    $TaskUi = Invoke-ValidationProcess $Godot $TaskArguments $TaskEngineLog (Join-Path $TaskEvidence 'ui_flow.log') 'Exported-PCK UI harness'
    $TaskReport.pck_ui_harness = $TaskUi
    if ($TaskUi.text -notmatch "UI_FLOW $TaskExpectedChecks checks; 0 failures") { $TaskProblems.Add("PCK UI log does not report $TaskExpectedChecks successful checks.") }
    $TaskUi.Remove('text')
    try {
        Assert-FreshFile $TaskFlowPath $TaskPreviousFlow
        $TaskFlow = Get-Content -LiteralPath $TaskFlowPath -Raw | ConvertFrom-Json
        if ($TaskFlow.checks -ne $TaskExpectedChecks -or $TaskFlow.failures -ne 0 -or $TaskFlow.graphical -ne $true) { throw "Expected $TaskExpectedChecks checks, zero failures, graphical=true in fresh PCK UI report." }
        if (@($TaskFlow.results).Count -ne $TaskExpectedChecks -or @($TaskFlow.results | Where-Object { $_.passed -ne $true }).Count -ne 0) { throw "Expected $TaskExpectedChecks passing detailed UI results." }
        $TaskUi['checks'] = $TaskFlow.checks
    } catch { $TaskProblems.Add($_.Exception.Message) }
    $TaskCaptures = [Collections.Generic.List[object]]::new()
    foreach ($TaskName in $TaskCaptureNames) {
        try { $TaskCaptures.Add((Get-PngEvidence (Join-Path $TaskEvidence "integration/$TaskName.png") "integration/$TaskName.png" $TaskPreviousCaptures[$TaskName])) }
        catch { $TaskProblems.Add($_.Exception.Message) }
    }
    $TaskUi['passed'] = $TaskProblems.Count -eq $TaskProblemStart
    $TaskUi['scope'] = 'Matching editor engine loads the explicit exported PCK and runs the external UI harness. This is not execution by the release EXE.'
    $TaskUi['engine_sha256'] = (Get-FileHash -LiteralPath $Godot -Algorithm SHA256).Hash
    $TaskUi['engine_version'] = $TaskGodotVersion; $TaskUi['expected_checks'] = $TaskExpectedChecks
    $TaskUi['captured_images'] = @($TaskCaptures.ToArray()); $TaskUi['report'] = 'ui_flow.json'
    $TaskUi['harness'] = $TaskHarness; $TaskUi['harness_sha256'] = (Get-FileHash -LiteralPath $TaskHarness -Algorithm SHA256).Hash

    $TaskProblemStart = $TaskProblems.Count
    $TaskSmokePath = Join-Path $TaskSmokeEvidence 'smoke_runtime.json'
    $TaskCapturePath = Join-Path $TaskSmokeEvidence 'release_gameplay.png'
    $TaskPreviousSmoke = Get-LastWriteOrNull $TaskSmokePath
    $TaskPreviousCapture = Get-LastWriteOrNull $TaskCapturePath
    $TaskEngineLog = Join-Path $TaskSmokeEvidence 'engine.log'
    $TaskArguments = '--rendering-method forward_plus --log-file "{0}" -- --smoke --profile --frames=600 "--evidence-root={1}" --capture-tick=300 --screenshot=release_gameplay.png' -f $TaskEngineLog, $TaskSmokeEvidence.Replace('\','/')
    $TaskRelease = Invoke-ValidationProcess $TaskExe $TaskArguments $TaskEngineLog (Join-Path $TaskSmokeEvidence 'smoke.log') 'Release EXE default-scene smoke'
    $TaskReport.release_executable_smoke = $TaskRelease
    if ($TaskRelease.text -notmatch 'SMOKE_REPORT ') { $TaskProblems.Add('Release EXE log omits SMOKE_REPORT.') }
    $TaskRelease.Remove('text')
    try {
        Assert-FreshFile $TaskSmokePath $TaskPreviousSmoke
        $TaskSmoke = Get-Content -LiteralPath $TaskSmokePath -Raw | ConvertFrom-Json
        if ($TaskSmoke.ticks -ne 600 -or @($TaskSmoke.fighters).Count -ne 4 -or $TaskSmoke.contacts -le 0) { throw 'Release smoke must complete 600 ticks, four fighters and actual combat contacts.' }
        if ($TaskSmoke.renderer -ne 'forward_plus' -or $TaskSmoke.settings.graphics -ne 'High' -or $TaskSmoke.profile_mode -ne $true) { throw 'Release smoke did not apply Forward+ and in-memory High profile.' }
        # CLI --version includes the commit hash; Engine.get_version_info().string
        # uses a readable version/status/build form and omits that hash.
        $TaskVersionParts = $TaskGodotVersion.Split('.')
        $TaskReadableVersion = ($TaskVersionParts[0..2] -join '.') + '-' + $TaskVersionParts[3] + ' (' + $TaskVersionParts[4] + ')'
        if ($TaskSmoke.engine -ne $TaskReadableVersion) { throw 'Release engine version differs from export manifest.' }
        $TaskRelease['reported_engine_version'] = $TaskSmoke.engine
        if ($TaskSmoke.window_pixels -ne '(1920, 1080)' -or $TaskSmoke.captured_pixel_size -ne '(1920, 1080)') { throw 'Release smoke did not render at requested 1920x1080.' }
        $TaskRelease['ticks'] = $TaskSmoke.ticks; $TaskRelease['fighters'] = @($TaskSmoke.fighters).Count; $TaskRelease['contacts'] = $TaskSmoke.contacts
    } catch { $TaskProblems.Add($_.Exception.Message) }
    try { $TaskRelease['capture'] = Get-PngEvidence $TaskCapturePath 'release_smoke/release_gameplay.png' $TaskPreviousCapture }
    catch { $TaskProblems.Add($_.Exception.Message) }
    $TaskRelease['passed'] = $TaskProblems.Count -eq $TaskProblemStart
    $TaskRelease['report'] = 'release_smoke/smoke_runtime.json'
    $TaskRelease['scope'] = 'Actual release EXE starts its default main scene from its adjacent PCK, runs four CPU fighters for 600 fixed ticks, captures gameplay, and exits. User smoke arguments automate play; native keyboard flow is a separate check. Screenshot readback and concurrent validation make this unsuitable for performance acceptance.'

    $TaskReport.runtime_source_hashes_verified_after = Assert-SourceManifest
    if ((Get-FileHash -LiteralPath $TaskExe -Algorithm SHA256).Hash -ne $TaskExeHash -or (Get-FileHash -LiteralPath $TaskPck -Algorithm SHA256).Hash -ne $TaskPckHash -or (Get-FileHash -LiteralPath $TaskManifestPath -Algorithm SHA256).Hash -ne $TaskManifestHash) { throw 'EXE, PCK or manifest changed during validation.' }
    $TaskReport.build_unchanged_during_validation = $true
} catch { $TaskProblems.Add($_.Exception.Message) }
finally {
    $TaskReport['finished_utc'] = [DateTime]::UtcNow.ToString('o')
    $TaskReport.passed = $TaskProblems.Count -eq 0
    $TaskReport['problems'] = @($TaskProblems.ToArray())
    $TaskReport['historical_runner_failure'] = [ordered]@{
        report = if (Test-Path -LiteralPath $TaskHistoricalPath) { 'historical_unsupported_override.json' } else { $null }
        reason = 'Original runner passed --path/--main-pack/--script to the release template. Godot 4.7.2 release templates reject path overrides and do not expose external script execution. The repaired runner separates the matching-engine PCK harness from actual release default-scene execution.'
        timestamp_correction = 'Original failed report reparsed an already-deserialized UTC DateTime as local time, shifting its displayed build timestamp by four hours. This report preserves the manifest UTC instant and precision.'
    }
    $TaskReport['scope'] = 'Exported-PCK graphical UI harness on the matching editor engine, plus actual release EXE default-scene CPU gameplay smoke. Source inventory and EXE/PCK/manifest hashes verified before and after. No physical-controller, subjective-audio, native keyboard-flow or performance acceptance claim. Images require visual inspection.'
    [IO.File]::WriteAllText($TaskReportPath, ($TaskReport | ConvertTo-Json -Depth 14), $TaskUtf8)
}
if ($TaskProblems.Count -gt 0) {
    Write-Error ('Windows build validation failed: ' + ($TaskProblems -join ' | ')) -ErrorAction Continue
    exit 1
}
Write-Output "WINDOWS_BUILD PASS: exported-PCK UI $TaskExpectedChecks checks / $($TaskCaptureNames.Count) fresh captures; release EXE 600 ticks / four fighters / gameplay capture; zero errors or warnings. Evidence: $TaskEvidence"
exit 0
