# Exercise each new arena through the real Windows release EXE's default scene.
# No --path, --main-pack or external --script override is sent to the template.
[CmdletBinding()]
param(
    [string]$BuildDirectory = '',
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
$TaskEvidence = Join-Path $TaskRoot 'evidence/map_expansion/release'
$TaskReportPath = Join-Path (Split-Path -Parent $TaskEvidence) 'release_validation.json'
$TaskArenas = @('verdant_shrine', 'abyssal_observatory', 'ember_foundry')
$TaskExpectedFighters = @('f06_rugged_explorer', 'f07_urban_sentinel', 'f08_midnight_gentleman', 'f01_clutch')
$TaskStarted = [DateTime]::UtcNow
$TaskRunId = $TaskStarted.ToString('yyyyMMddTHHmmssfffZ') + '-' + [Guid]::NewGuid().ToString('N').Substring(0, 8)
$TaskArchive = Join-Path $TaskEvidence "history/$TaskRunId"
$TaskUtf8 = [Text.UTF8Encoding]::new($false)
$TaskProblems = [Collections.Generic.List[string]]::new()
$TaskCases = [Collections.Generic.List[object]]::new()
$TaskManifest = $null
$TaskBefore = $null
$TaskReport = [ordered]@{
    run_id = $TaskRunId; started_utc = $TaskStarted.ToString('o'); passed = $false
    harness = $PSCommandPath; harness_sha256 = (Get-FileHash -LiteralPath $PSCommandPath -Algorithm SHA256).Hash
    executable = $TaskExe; pck = $TaskPck; build_manifest = $TaskManifestPath
    requested_arenas = $TaskArenas; expected_ticks_per_arena = 600; expected_fighters = $TaskExpectedFighters
    runtime_source_hashes_verified_before = 0; runtime_source_hashes_verified_after = 0
    build_unchanged_during_validation = $false
    scope = 'Actual Windows release EXE default-main-scene smoke on all three new arenas, using the adjacent PCK and in-memory High/1080p profile. Each case requires 600 fixed ticks, the four expected CPU-smoke fighters, actual combat contacts, fresh native output and PNG, and clean native exit.'
    limitations = @('This is automated CPU gameplay, not physical-controller or human playtesting.', 'PNG captures require visual inspection; metadata checks cannot establish visual quality.', 'Screenshot readback, short duration and validation overhead make these runs unsuitable for performance acceptance.')
}
New-Item -ItemType Directory -Path $TaskEvidence -Force | Out-Null
. (Join-Path $PSScriptRoot 'release_provenance.ps1')

function Get-MapFileEvidence([string]$Path) {
    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) { throw "Missing file: $Path" }
    $TaskItem = Get-Item -LiteralPath $Path
    if ($TaskItem.Length -le 0) { throw "Empty file: $Path" }
    return [ordered]@{ path = $TaskItem.FullName; bytes = $TaskItem.Length; sha256 = (Get-FileHash -LiteralPath $Path -Algorithm SHA256).Hash }
}

function Get-MapBuildHashes {
    return [ordered]@{
        executable = Get-MapFileEvidence $TaskExe
        pck = Get-MapFileEvidence $TaskPck
        manifest = Get-MapFileEvidence $TaskManifestPath
    }
}

function Assert-MapBuildHashes($Snapshot) {
    $TaskNow = Get-MapBuildHashes
    foreach ($TaskKey in 'executable', 'pck', 'manifest') {
        if ($TaskNow[$TaskKey].sha256 -ne $Snapshot[$TaskKey].sha256 -or $TaskNow[$TaskKey].bytes -ne $Snapshot[$TaskKey].bytes) {
            throw "Release $TaskKey changed during validation."
        }
    }
    if ($TaskNow.executable.sha256 -ne $TaskManifest.exe_sha256 -or $TaskNow.pck.sha256 -ne $TaskManifest.pck_sha256) { throw 'EXE/PCK hashes differ from the build manifest.' }
    return $TaskNow
}

function Assert-MapRuntimeInventory {
    if (-not $TaskManifest.PSObject.Properties['runtime_source_files'] -or @($TaskManifest.runtime_source_files).Count -eq 0) { throw 'Build manifest omits runtime_source_files.' }
    $TaskPrefix = [IO.Path]::GetFullPath($TaskProject).TrimEnd([char[]]@('\', '/')) + [IO.Path]::DirectorySeparatorChar
    $TaskSeen = [Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
    foreach ($TaskRecord in $TaskManifest.runtime_source_files) {
        $TaskRecordPath = [IO.Path]::GetFullPath((Join-Path $TaskProject ([string]$TaskRecord.path)))
        if (-not $TaskRecordPath.StartsWith($TaskPrefix, [StringComparison]::OrdinalIgnoreCase)) { throw "Manifest path leaves project: $($TaskRecord.path)" }
        if (-not $TaskSeen.Add($TaskRecordPath)) { throw "Duplicate runtime manifest path: $($TaskRecord.path)" }
    }
    $TaskCurrent = Get-ReleaseRuntimeInventory $TaskProject
    $TaskManifestInventoryHash = Get-ReleaseInventoryHash @($TaskManifest.runtime_source_files)
    if (@($TaskCurrent.files).Count -ne $TaskSeen.Count -or $TaskCurrent.sha256 -ne $TaskManifestInventoryHash) { throw 'Current runtime source inventory does not match the exported manifest. Re-export before release validation.' }
    return [ordered]@{ files = @($TaskCurrent.files).Count; sha256 = $TaskCurrent.sha256; manifest_inventory_sha256 = $TaskManifestInventoryHash }
}

function Assert-MapFresh([string]$Path, [DateTime]$Started, $PriorWrite) {
    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) { throw "Missing fresh output: $Path" }
    $TaskItem = Get-Item -LiteralPath $Path
    if ($TaskItem.Length -le 0) { throw "Empty output: $Path" }
    if ($TaskItem.LastWriteTimeUtc -lt $Started.AddSeconds(-2)) { throw "Output predates its release run: $Path" }
    if ($PriorWrite -and $TaskItem.LastWriteTimeUtc -le $PriorWrite) { throw "Output was not regenerated: $Path" }
}

function Get-MapPng([string]$Path, [DateTime]$Started, $PriorWrite) {
    Assert-MapFresh $Path $Started $PriorWrite
    $TaskBytes = [IO.File]::ReadAllBytes($Path)
    if ($TaskBytes.Length -lt 33 -or [BitConverter]::ToString($TaskBytes, 0, 8) -ne '89-50-4E-47-0D-0A-1A-0A' -or [Text.Encoding]::ASCII.GetString($TaskBytes, 12, 4) -ne 'IHDR') { throw "Invalid PNG signature/IHDR: $Path" }
    $TaskWidth = [int]$TaskBytes[16] * 16777216 + [int]$TaskBytes[17] * 65536 + [int]$TaskBytes[18] * 256 + [int]$TaskBytes[19]
    $TaskHeight = [int]$TaskBytes[20] * 16777216 + [int]$TaskBytes[21] * 65536 + [int]$TaskBytes[22] * 256 + [int]$TaskBytes[23]
    if ($TaskWidth -ne 1920 -or $TaskHeight -ne 1080) { throw "Expected actual 1920x1080 PNG, got ${TaskWidth}x${TaskHeight}: $Path" }
    $TaskResult = Get-MapFileEvidence $Path
    $TaskResult['width'] = $TaskWidth; $TaskResult['height'] = $TaskHeight
    return $TaskResult
}

try {
    # Preserve complete earlier case outputs before reusing their stable paths.
    $TaskOldPaths = @($TaskReportPath) + @($TaskArenas | ForEach-Object { Join-Path $TaskEvidence $_ })
    foreach ($TaskOldPath in $TaskOldPaths) {
        if (Test-Path -LiteralPath $TaskOldPath) {
            New-Item -ItemType Directory -Path $TaskArchive -Force | Out-Null
            Copy-Item -LiteralPath $TaskOldPath -Destination $TaskArchive -Recurse
        }
    }
    if (Test-Path -LiteralPath $TaskArchive) { $TaskReport['preserved_previous_outputs'] = $TaskArchive }
    foreach ($TaskPath in $TaskExe, $TaskPck, $TaskManifestPath, $TaskEvidence) {
        if ($TaskPath.Contains('"')) { throw 'Quoted paths cannot be safely passed to the native process runner.' }
    }
    if (Test-Path -LiteralPath (Join-Path $TaskBuild 'project.godot')) { throw 'Build directory contains project.godot; cannot prove the release EXE used only its adjacent PCK.' }
    $TaskBefore = Get-MapBuildHashes
    $TaskReport['build_hashes_before'] = $TaskBefore
    $TaskManifest = Get-Content -LiteralPath $TaskManifestPath -Raw | ConvertFrom-Json
    $null = Assert-MapBuildHashes $TaskBefore
    if (-not $TaskManifest.PSObject.Properties['build_timestamp_utc'] -or -not $TaskManifest.PSObject.Properties['engine_version']) { throw 'Manifest omits build timestamp or engine version.' }
    $TaskReport['source_build_timestamp_utc'] = $TaskManifest.build_timestamp_utc
    $TaskReport['manifest_engine_version'] = $TaskManifest.engine_version
    $TaskVersionParts = ([string]$TaskManifest.engine_version).Split('.')
    if ($TaskVersionParts.Count -lt 5) { throw 'Unrecognized manifest engine version format.' }
    $TaskReadableVersion = ($TaskVersionParts[0..2] -join '.') + '-' + $TaskVersionParts[3] + ' (' + $TaskVersionParts[4] + ')'
    $TaskInventoryBefore = Assert-MapRuntimeInventory
    $TaskReport.runtime_source_hashes_verified_before = $TaskInventoryBefore.files
    $TaskReport['runtime_inventory_before'] = $TaskInventoryBefore

    foreach ($TaskArena in $TaskArenas) {
        $TaskCaseProblems = [Collections.Generic.List[string]]::new()
        $TaskCasePath = Join-Path $TaskEvidence $TaskArena
        New-Item -ItemType Directory -Path $TaskCasePath -Force | Out-Null
        $TaskEngineLog = Join-Path $TaskCasePath 'engine.log'
        $TaskNativeLog = Join-Path $TaskCasePath 'release_smoke.log'
        $TaskSmokePath = Join-Path $TaskCasePath 'smoke_runtime.json'
        $TaskPngPath = Join-Path $TaskCasePath 'release_gameplay.png'
        $TaskPriorWrites = @{}
        foreach ($TaskPath in $TaskEngineLog, $TaskSmokePath, $TaskPngPath) {
            if (Test-Path -LiteralPath $TaskPath) { $TaskPriorWrites[$TaskPath] = (Get-Item -LiteralPath $TaskPath).LastWriteTimeUtc }
        }
        $TaskCaseStarted = [DateTime]::UtcNow
        $TaskArguments = '--rendering-method forward_plus --log-file "{0}" -- --smoke --profile --frames=600 "--arena={1}" "--evidence-root={2}" --capture-tick=300 --screenshot=release_gameplay.png' -f $TaskEngineLog, $TaskArena, $TaskCasePath.Replace('\', '/')
        $TaskCase = [ordered]@{
            requested_arena = $TaskArena; started_utc = $TaskCaseStarted.ToString('o'); passed = $false
            command = ('"{0}" {1}' -f $TaskExe, $TaskArguments); working_directory = $TaskBuild
            exit_code = $null; timed_out = $false; timeout_seconds = $TimeoutSeconds
            smoke_report = $TaskSmokePath; engine_log = $TaskEngineLog; native_log = $TaskNativeLog
        }
        $TaskNativeText = ''
        try {
            $TaskCase['build_hashes_before'] = Assert-MapBuildHashes $TaskBefore
            $TaskInfo = [Diagnostics.ProcessStartInfo]::new()
            $TaskInfo.FileName = $TaskExe; $TaskInfo.Arguments = $TaskArguments
            $TaskInfo.WorkingDirectory = $TaskBuild; $TaskInfo.UseShellExecute = $false
            $TaskInfo.CreateNoWindow = $true; $TaskInfo.RedirectStandardOutput = $true; $TaskInfo.RedirectStandardError = $true
            $TaskProcess = [Diagnostics.Process]::new(); $TaskProcess.StartInfo = $TaskInfo
            try {
                if (-not $TaskProcess.Start()) { throw "Release EXE did not start for $TaskArena." }
                $TaskCase['process_id'] = $TaskProcess.Id
                $TaskStdout = $TaskProcess.StandardOutput.ReadToEndAsync()
                $TaskStderr = $TaskProcess.StandardError.ReadToEndAsync()
                if (-not $TaskProcess.WaitForExit($TimeoutSeconds * 1000)) {
                    $TaskCase.timed_out = $true
                    $TaskProcess.Kill(); $TaskProcess.WaitForExit()
                    $TaskCaseProblems.Add("Timed out after $TimeoutSeconds seconds.")
                }
                $TaskNativeText = $TaskStdout.GetAwaiter().GetResult() + [Environment]::NewLine + $TaskStderr.GetAwaiter().GetResult()
                $TaskCase.exit_code = $TaskProcess.ExitCode
                if ($TaskProcess.ExitCode -ne 0) { $TaskCaseProblems.Add("Release EXE exited with code $($TaskProcess.ExitCode).") }
            } finally { $TaskProcess.Dispose() }
            [IO.File]::WriteAllText($TaskNativeLog, $TaskNativeText, $TaskUtf8)
            Assert-MapFresh $TaskEngineLog $TaskCaseStarted $TaskPriorWrites[$TaskEngineLog]
            $TaskCombinedText = $TaskNativeText + [Environment]::NewLine + [IO.File]::ReadAllText($TaskEngineLog)
            $TaskErrorLines = @($TaskCombinedText -split '\r?\n' | Where-Object { $_ -match '(?i)\b(?:SCRIPT ERROR|Parse Error|ERROR)\s*:|\b(?:CRASH|FATAL)\b' } | Select-Object -Unique)
            $TaskWarningLines = @($TaskCombinedText -split '\r?\n' | Where-Object { $_ -match '(?i)^\s*WARNING\s*:' } | Select-Object -Unique)
            $TaskCase['errors'] = $TaskErrorLines; $TaskCase['warnings'] = $TaskWarningLines
            foreach ($TaskLine in $TaskErrorLines + $TaskWarningLines) { $TaskCaseProblems.Add($TaskLine.Trim()) }
            if ($TaskCombinedText -notmatch 'ROOFTOP_READY renderer=forward_plus' -or $TaskCombinedText -notmatch 'SMOKE_REPORT ') { throw 'Native logs omit expected default-main-scene startup or completed smoke report.' }
            Assert-MapFresh $TaskSmokePath $TaskCaseStarted $TaskPriorWrites[$TaskSmokePath]
            $TaskSmoke = Get-Content -LiteralPath $TaskSmokePath -Raw | ConvertFrom-Json
            if ($TaskSmoke.arena -ne $TaskArena) { throw "Requested $TaskArena, release reported $($TaskSmoke.arena)." }
            if ($TaskSmoke.ticks -ne 600 -or @($TaskSmoke.fighters).Count -ne 4 -or $TaskSmoke.contacts -le 0) { throw 'Release must finish 600 ticks with four fighters and actual combat contacts.' }
            $TaskActualIds = @($TaskSmoke.fighters | ForEach-Object { [string]$_.id })
            if (($TaskActualIds -join ',') -ne ($TaskExpectedFighters -join ',')) { throw 'Release fighter roster differs from the four-CPU smoke setup.' }
            $TaskProviderRows = @($TaskSmoke.fighters | Where-Object { $_.PSObject.Properties['input_provider'] })
            if ($TaskProviderRows.Count -ne 4 -or @($TaskProviderRows | Where-Object { $_.input_provider -cne 'res://input/cpu_input_provider.gd' }).Count -gt 0) { throw 'Runtime input-provider evidence does not identify exactly four CPU fighters.' }
            $TaskCase['reported_input_providers'] = @($TaskProviderRows | ForEach-Object { $_.input_provider })
            if ($TaskSmoke.renderer -ne 'forward_plus' -or $TaskSmoke.profile_mode -ne $true -or $TaskSmoke.settings.graphics -ne 'High' -or $TaskSmoke.settings.resolution -ne '1920x1080') { throw 'Release did not apply Forward+ and in-memory High/1080p profile.' }
            if ($TaskSmoke.engine -ne $TaskReadableVersion) { throw 'Release engine differs from the exported manifest version.' }
            # ViewportTexture.get_size() reports (2304.0, 1296.0) under the
            # project's 1600x900 canvas stretch at a 1920x1080 window, including
            # in the prior accepted build. Check the actual image readback and
            # decoded PNG dimensions; retain texture metadata without treating
            # it as the pixel buffer size.
            foreach ($TaskSizeKey in 'window_pixels', 'captured_pixel_size') {
                if ($TaskSmoke.$TaskSizeKey -ne '(1920, 1080)') { throw "Release $TaskSizeKey does not confirm actual 1920x1080." }
            }
            $TaskCase['reported_pixel_sizes'] = [ordered]@{
                window = $TaskSmoke.window_pixels
                texture_metadata = $TaskSmoke.render_texture_pixels
                image_readback = $TaskSmoke.captured_pixel_size
            }
            $TaskCase['capture'] = Get-MapPng $TaskPngPath $TaskCaseStarted $TaskPriorWrites[$TaskPngPath]
            $TaskCase['runtime_report_file'] = Get-MapFileEvidence $TaskSmokePath
            $TaskCase['reported_arena'] = $TaskSmoke.arena; $TaskCase['ticks'] = $TaskSmoke.ticks
            $TaskCase['fighter_ids'] = $TaskActualIds; $TaskCase['contacts'] = $TaskSmoke.contacts
            $TaskCase['renderer'] = $TaskSmoke.renderer; $TaskCase['engine'] = $TaskSmoke.engine; $TaskCase['gpu'] = $TaskSmoke.gpu
            $TaskCase['settings'] = $TaskSmoke.settings
        } catch { $TaskCaseProblems.Add($_.Exception.Message) }
        finally {
            # Even failures retain stdout, engine output and any partial capture.
            if (-not (Test-Path -LiteralPath $TaskNativeLog) -or (Get-Item -LiteralPath $TaskNativeLog).LastWriteTimeUtc -lt $TaskCaseStarted) { [IO.File]::WriteAllText($TaskNativeLog, $TaskNativeText, $TaskUtf8) }
            try { $TaskCase['build_hashes_after'] = Assert-MapBuildHashes $TaskBefore }
            catch { $TaskCaseProblems.Add($_.Exception.Message) }
            try {
                $TaskCase['log_files'] = [ordered]@{ engine = Get-MapFileEvidence $TaskEngineLog; native = Get-MapFileEvidence $TaskNativeLog }
            } catch { $TaskCaseProblems.Add($_.Exception.Message) }
            $TaskCase['finished_utc'] = [DateTime]::UtcNow.ToString('o')
            $TaskCase['wall_seconds'] = ([DateTime]::UtcNow - $TaskCaseStarted).TotalSeconds
            $TaskCase['problems'] = @($TaskCaseProblems.ToArray())
            $TaskCase.passed = $TaskCaseProblems.Count -eq 0
            $TaskCases.Add($TaskCase)
            foreach ($TaskProblem in $TaskCaseProblems) { $TaskProblems.Add($TaskArena + ': ' + $TaskProblem) }
            [IO.File]::WriteAllText((Join-Path $TaskCasePath 'case_validation.json'), ($TaskCase | ConvertTo-Json -Depth 12), $TaskUtf8)
        }
        Write-Output ("MAP_RELEASE {0}: {1}" -f $TaskArena, $(if ($TaskCase.passed) { 'PASS' } else { 'FAIL' }))
    }
    $TaskInventoryAfter = Assert-MapRuntimeInventory
    $TaskReport.runtime_source_hashes_verified_after = $TaskInventoryAfter.files
    $TaskReport['runtime_inventory_after'] = $TaskInventoryAfter
    $TaskReport['build_hashes_after'] = Assert-MapBuildHashes $TaskBefore
    $TaskReport.build_unchanged_during_validation = $true
    if ($TaskCases.Count -ne 3) { throw 'Expected exactly three release arena cases.' }
} catch { $TaskProblems.Add($_.Exception.Message) }
finally {
    $TaskReport['finished_utc'] = [DateTime]::UtcNow.ToString('o')
    $TaskReport['cases'] = @($TaskCases.ToArray())
    $TaskReport['problems'] = @($TaskProblems.ToArray())
    $TaskReport.passed = $TaskProblems.Count -eq 0 -and $TaskCases.Count -eq 3 -and $TaskReport.build_unchanged_during_validation
    [IO.File]::WriteAllText($TaskReportPath, ($TaskReport | ConvertTo-Json -Depth 15), $TaskUtf8)
}
if (-not $TaskReport.passed) {
    Write-Error ('Map release validation failed: ' + ($TaskProblems -join ' | ')) -ErrorAction Continue
    exit 1
}
Write-Output "MAP_RELEASE PASS: all three actual Windows EXE arena runs, 600 ticks each, four CPU-smoke fighters, combat contacts, 1920x1080 PNGs, clean native exits and matching source/build hashes. Evidence: $TaskReportPath"
exit 0
