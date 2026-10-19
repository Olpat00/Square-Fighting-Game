# Run from any directory: pwsh -NoProfile -File tools/validation/validate_all.ps1
# Headless logic validation only; graphical, audio, and physical-controller QA are separate.
[CmdletBinding()]
param(
    [string]$Godot = 'D:\Game Engines\Godot\Godot_v4.7.2-stable_win64_console.exe',
    [ValidateRange(30, 3600)][int]$SuiteTimeoutSeconds = 600
)

$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'release_provenance.ps1')
$TaskRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$TaskProject = Join-Path $TaskRoot 'Game File'
$TaskEvidence = Join-Path $TaskRoot 'evidence'
$TaskSummaryPath = Join-Path $TaskEvidence 'validation_all.json'
$TaskStarted = [DateTime]::UtcNow
$TaskResults = [System.Collections.Generic.List[object]]::new()
$TaskUtf8 = [System.Text.UTF8Encoding]::new($false)
New-Item -ItemType Directory -Path $TaskEvidence -Force | Out-Null
if (-not (Test-Path -LiteralPath $Godot -PathType Leaf)) { throw "Godot executable not found: $Godot" }
if (-not (Test-Path -LiteralPath (Join-Path $TaskProject 'project.godot'))) { throw "Godot project not found: $TaskProject" }

function Test-ConfirmedRoster {
    $TaskProblems = [System.Collections.Generic.List[string]]::new()
    $TaskModels = [System.Collections.Generic.List[object]]::new()
    $TaskOriginals = [System.Collections.Generic.List[object]]::new()
    $TaskExpected = [ordered]@{ f01_clutch = 'Wes'; f02_sunstruck = 'Will'; f03_heavy_duty = 'Damion'; f04_deadfall = 'Jaydon'; f05_fine_print = 'Josh'; f06_rugged_explorer = 'Rugged Explorer'; f07_urban_sentinel = 'Urban Sentinel'; f08_midnight_gentleman = 'Midnight Gentleman' }
    $TaskMappingPath = Join-Path $TaskRoot 'docs/confirmed_character_mapping.json'
    $TaskMappingAccepted = $false
    $TaskMappingHash = $null
    try {
        $TaskMapping = Get-Content -LiteralPath $TaskMappingPath -Raw | ConvertFrom-Json
        $TaskMappingHash = (Get-FileHash -LiteralPath $TaskMappingPath -Algorithm SHA256).Hash
        $TaskMappingAccepted = $TaskMapping.f02_sunstruck -ceq 'Will' -and $TaskMapping.f03_heavy_duty -ceq 'Damion'
        if (-not $TaskMappingAccepted) { throw 'Mapping record does not match the user-confirmed Will/Sunstruck and Damion/Heavy Duty assignments.' }
    } catch { $TaskProblems.Add($_.Exception.Message) }
    $TaskSources = @()
    try {
        $TaskSources = @(Get-Content -LiteralPath (Join-Path $TaskRoot 'evidence/preflight/source_hashes.json') -Raw | ConvertFrom-Json)
        if ($TaskSources.Count -ne $TaskExpected.Count) { throw "Expected exactly $($TaskExpected.Count) immutable original-source hash records." }
    } catch { $TaskProblems.Add($_.Exception.Message) }
    foreach ($TaskEntry in $TaskExpected.GetEnumerator()) {
        $TaskModelRelative = 'Game File/assets/characters/' + $TaskEntry.Key + '.glb'
        $TaskModelPath = Join-Path $TaskRoot $TaskModelRelative
        $TaskPresent = (Test-Path -LiteralPath $TaskModelPath -PathType Leaf) -and (Get-Item -LiteralPath $TaskModelPath).Length -gt 0
        if (-not $TaskPresent) { $TaskProblems.Add("Required canonical model is absent or empty: $TaskModelRelative") }
        $TaskModels.Add([ordered]@{ fighter_id = $TaskEntry.Key; confirmed_source_folder = $TaskEntry.Value; path = $TaskModelRelative; present = $TaskPresent; sha256 = if ($TaskPresent) { (Get-FileHash -LiteralPath $TaskModelPath -Algorithm SHA256).Hash } else { $null } })
        try {
            $TaskSourcePattern = '/Assets/' + [regex]::Escape($TaskEntry.Value) + '/[^/]+\.glb$'
            $TaskMatches = @($TaskSources | Where-Object { ($_.Path -replace '\\', '/') -match $TaskSourcePattern })
            if ($TaskMatches.Count -ne 1) { throw "Missing or ambiguous original-source record for $($TaskEntry.Value)." }
            $TaskRecord = $TaskMatches[0]
            # Resolve preserved originals inside this checkout, including when copied
            # to another machine; the recorded absolute path is historical provenance.
            $TaskSourceName = (($TaskRecord.Path -replace '\\', '/') -split '/')[-1]
            $TaskSourceRelative = 'Assets/' + $TaskEntry.Value + '/' + $TaskSourceName
            $TaskCurrentHash = (Get-FileHash -LiteralPath (Join-Path $TaskRoot $TaskSourceRelative) -Algorithm SHA256).Hash
            $TaskPreserved = $TaskCurrentHash -eq $TaskRecord.Hash
            if (-not $TaskPreserved) { $TaskProblems.Add("Original source SHA-256 changed: $TaskSourceRelative") }
            $TaskOriginals.Add([ordered]@{ path = $TaskSourceRelative; recorded_path = $TaskRecord.Path; expected_sha256 = $TaskRecord.Hash; actual_sha256 = $TaskCurrentHash; preserved = $TaskPreserved })
        } catch { $TaskProblems.Add($_.Exception.Message) }
    }
    return [ordered]@{
        passed = $TaskProblems.Count -eq 0
        mapping_provenance_accepted = $TaskMappingAccepted
        mapping_record = 'docs/confirmed_character_mapping.json'
        mapping_record_sha256 = $TaskMappingHash
        mapping_confirmation_date = '2026-09-22'
        full_roster_required = $true
        canonical_models = @($TaskModels.ToArray())
        originals_preserved = $TaskOriginals.Count -eq $TaskExpected.Count -and @($TaskOriginals | Where-Object { -not $_.preserved }).Count -eq 0
        original_sources = @($TaskOriginals.ToArray())
        problems = @($TaskProblems.ToArray())
    }
}

function Invoke-HeadlessSuite {
    param([hashtable]$Suite)
    $TaskLogPath = Join-Path $TaskEvidence $Suite.Log
    $TaskSuiteStart = [DateTime]::UtcNow
    $TaskProblems = [System.Collections.Generic.List[string]]::new()
    $TaskData = $null
    $TaskOldWrite = $null
    $TaskReportPath = $null
    if ($Suite.Report) {
        $TaskReportPath = Join-Path $TaskRoot $Suite.Report
        if (Test-Path -LiteralPath $TaskReportPath) { $TaskOldWrite = (Get-Item -LiteralPath $TaskReportPath).LastWriteTimeUtc }
    }
    $TaskScriptPath = if ($Suite.Script) { Join-Path $TaskRoot $Suite.Script } else { $null }
    $TaskArguments = '--headless --path "{0}"' -f $TaskProject
    if ($TaskScriptPath) { $TaskArguments += ' --script "{0}"' -f $TaskScriptPath }
    else { $TaskArguments += ' --editor --import --quit' }
    Write-Host ("Running {0}..." -f $Suite.Name)
    $TaskStartInfo = [System.Diagnostics.ProcessStartInfo]::new()
    $TaskStartInfo.FileName = $Godot
    $TaskStartInfo.Arguments = $TaskArguments
    $TaskStartInfo.WorkingDirectory = $TaskRoot
    $TaskStartInfo.UseShellExecute = $false
    $TaskStartInfo.CreateNoWindow = $true
    $TaskStartInfo.RedirectStandardOutput = $true
    $TaskStartInfo.RedirectStandardError = $true
    $TaskProcess = [System.Diagnostics.Process]::new()
    $TaskProcess.StartInfo = $TaskStartInfo
    $TaskExitCode = -1
    $TaskLogText = ''
    try {
        if (-not $TaskProcess.Start()) { throw 'Godot process did not start.' }
        # Drain both streams asynchronously to avoid deadlocking on warning backtraces.
        $TaskStdout = $TaskProcess.StandardOutput.ReadToEndAsync()
        $TaskStderr = $TaskProcess.StandardError.ReadToEndAsync()
        if (-not $TaskProcess.WaitForExit($SuiteTimeoutSeconds * 1000)) {
            $TaskProcess.Kill()
            $TaskProcess.WaitForExit()
            $TaskProblems.Add("Timed out after $SuiteTimeoutSeconds seconds.")
        }
        $TaskLogText = $TaskStdout.GetAwaiter().GetResult() + "`n" + $TaskStderr.GetAwaiter().GetResult()
        $TaskExitCode = $TaskProcess.ExitCode
        if ($TaskExitCode -ne 0) { $TaskProblems.Add("Godot exited with code $TaskExitCode.") }
    } catch {
        $TaskProblems.Add($_.Exception.Message)
        $TaskLogText += "`nRUNNER ERROR: " + $_.Exception.Message
    } finally {
        $TaskProcess.Dispose()
        [System.IO.File]::WriteAllText($TaskLogPath, $TaskLogText, $TaskUtf8)
    }
    $TaskLines = @($TaskLogText -split '\r?\n')
    $TaskMissingModelWarnings = @($TaskLines | Where-Object { $_ -match '^\s*WARNING: Runtime model still pending:' })
    # Missing runtime model warnings are failures for the whole roster.
    $TaskErrors = @($TaskLines | Where-Object { $_ -match '(?i)\b(?:SCRIPT ERROR|Parse Error|ERROR)\s*:' })
    foreach ($TaskLine in $TaskErrors) { $TaskProblems.Add($TaskLine.Trim()) }
    $TaskOtherWarnings = @($TaskLines | Where-Object { $_ -match '^\s*WARNING:' })
    foreach ($TaskLine in $TaskOtherWarnings) { $TaskProblems.Add("Unexpected " + $TaskLine.Trim()) }
    if ($TaskReportPath) {
        try {
            if (-not (Test-Path -LiteralPath $TaskReportPath)) { throw "Missing suite report: $($Suite.Report)" }
            $TaskNewWrite = (Get-Item -LiteralPath $TaskReportPath).LastWriteTimeUtc
            if ($TaskOldWrite -and $TaskNewWrite -le $TaskOldWrite) { throw "Suite report was not regenerated: $($Suite.Report)" }
            $TaskData = Get-Content -LiteralPath $TaskReportPath -Raw | ConvertFrom-Json
            if ($TaskData.PSObject.Properties['missing_visual_assets'] -and @($TaskData.missing_visual_assets).Count -gt 0) { throw 'The suite reports missing canonical fighter visuals.' }
            switch ($Suite.Name) {
                { $_ -in 'input', 'content', 'core', 'gameplay_rebuild', 'rebuild_animation', 'stages', 'abilities', 'new_fighters', 'presentation_state' } {
                    if (-not $TaskData.PSObject.Properties['checks']) { throw 'Missing check count.' }
                    $TaskCheckCount = if ($TaskData.checks -is [array]) { @($TaskData.checks).Count } else { [int]$TaskData.checks }
                    if ($TaskCheckCount -lt 1) { throw 'Empty check count.' }
                    if ($TaskData.checks -is [array] -and @($TaskData.checks | Where-Object { $_.passed -ne $true }).Count -gt 0) { throw 'A detailed check failed.' }
                    if (-not $TaskData.PSObject.Properties['failures']) { throw 'Missing failure field.' }
                    if ($TaskData.failures -is [array]) { $TaskFailureCount = @($TaskData.failures).Count }
                    else { $TaskFailureCount = [int]$TaskData.failures }
                    if ($TaskFailureCount -ne 0) { throw "Suite reports $TaskFailureCount failed checks." }
                    if ($TaskData.PSObject.Properties['results'] -and @($TaskData.results | Where-Object { $_.passed -ne $true }).Count -gt 0) { throw 'A detailed check result failed.' }
                }
                'settings' {
                    foreach ($TaskField in 'roundtrip', 'invalid_values_sanitized', 'corrupt_file_defaults', 'user_settings_preserved') {
                        if ($TaskData.$TaskField -ne $true) { throw "Settings assertion failed or absent: $TaskField" }
                    }
                }
                'pairing_soak' {
                    if (-not $TaskData.PSObject.Properties['failures'] -or @($TaskData.failures).Count -ne 0) { throw 'Pairing soak reports failures or omits its failure field.' }
                    $TaskPairs = @($TaskData.pairings | Where-Object { $_.pair })
                    $TaskRosterSize = @($TaskRoster.canonical_models).Count
                    $TaskExpectedPairs = [int]($TaskRosterSize * ($TaskRosterSize + 1) / 2)
                    if ($TaskPairs.Count -ne $TaskExpectedPairs) { throw "Expected $TaskExpectedPairs distinct/mirror pairings; received $($TaskPairs.Count)." }
                    if (@($TaskPairs | Where-Object { $_.contacts -lt 1 }).Count -gt 0) { throw 'A pairing produced no combat contacts.' }
                    $TaskStress = @($TaskData.pairings | Where-Object { $_.four_cpu -eq $true })
                    if ($TaskStress.Count -ne 1) { throw 'Expected one four-CPU result.' }
                    $TaskMatchResult = $TaskStress[0].result
                    if (-not $TaskMatchResult -or -not $TaskMatchResult.PSObject.Properties['winner'] -or [string]::IsNullOrWhiteSpace($TaskMatchResult.reason)) { throw 'Four-CPU result was missing or cleared after match cleanup.' }
                    if ($TaskMatchResult.winner -lt 0 -or $TaskMatchResult.winner -gt 3 -or $TaskMatchResult.ticks -ne $TaskStress[0].ticks) { throw 'Four-CPU winner or final tick is invalid.' }
                    if ($TaskData.rematches -ne 20 -or $TaskData.node_final -gt $TaskData.node_baseline + 5) { throw 'Repeated-rematch cleanup assertion failed.' }
                }
            }
        } catch { $TaskProblems.Add($_.Exception.Message) }
    }
    $TaskRow = [ordered]@{
        name = $Suite.Name
        passed = $TaskProblems.Count -eq 0
        exit_code = $TaskExitCode
        duration_seconds = [Math]::Round(([DateTime]::UtcNow - $TaskSuiteStart).TotalSeconds, 3)
        command = ('"{0}" {1}' -f $Godot, $TaskArguments)
        script_sha256 = if ($TaskScriptPath) { (Get-FileHash -LiteralPath $TaskScriptPath -Algorithm SHA256).Hash } else { $null }
        log = ('evidence/' + $Suite.Log)
        report = $Suite.Report
        checks = if ($TaskData -and $TaskData.PSObject.Properties['checks']) { $TaskData.checks } else { $null }
        missing_model_warning_count = $TaskMissingModelWarnings.Count
        unexpected_error_lines = $TaskErrors
        unexpected_warning_lines = $TaskOtherWarnings
        problems = @($TaskProblems.ToArray())
    }
    $TaskResults.Add($TaskRow)
    Write-Host ("{0}: {1} ({2}s)" -f $Suite.Name, $(if ($TaskRow.passed) { 'PASS' } else { 'FAIL' }), $TaskRow.duration_seconds)
    foreach ($TaskProblem in $TaskProblems) { Write-Host ("  " + $TaskProblem) }
}

# Rebuild the import/class cache so a fresh checkout follows the same workflow.
$TaskRoster = Test-ConfirmedRoster
foreach ($TaskProblem in $TaskRoster.problems) { Write-Host ("ROSTER PREFLIGHT FAIL: " + $TaskProblem) }
if ($TaskRoster.passed) { Invoke-HeadlessSuite @{ Name = 'headless_import'; Log = 'validation_import.log' } }
$TaskRuntimeBefore = Get-ReleaseRuntimeInventory $TaskProject
$TaskSuites = @(
        @{ Name = 'input'; Script = 'Game File/input/validate_input.gd'; Report = 'docs/moves/input-validation.json'; Log = 'input_validation.log' },
        @{ Name = 'content'; Script = 'docs/moves/validate_content.gd'; Report = 'docs/moves/content-validation.json'; Log = 'content_validation.log' },
        @{ Name = 'core'; Script = 'tools/validation/combat_scenarios.gd'; Report = 'evidence/combat_scenarios.json'; Log = 'combat_scenarios.log' },
        @{ Name = 'gameplay_rebuild'; Script = 'tools/validation/gameplay_rebuild_scenarios.gd'; Report = 'evidence/gameplay_rebuild_scenarios.json'; Log = 'gameplay_rebuild_scenarios.log' },
        @{ Name = 'rebuild_animation'; Script = 'tools/validation/rebuild_animation_scenarios.gd'; Report = 'evidence/rebuild/animation_scenarios.json'; Log = 'rebuild_animation_scenarios.log' },
        @{ Name = 'stages'; Script = 'tools/validation/stage_scenarios.gd'; Report = 'evidence/lunar_upgrade/stage_scenarios.json'; Log = 'stage_scenarios.log' },
        @{ Name = 'abilities'; Script = 'tools/validation/ability_scenarios.gd'; Report = 'evidence/ability_scenarios.json'; Log = 'ability_scenarios.log' },
        @{ Name = 'new_fighters'; Script = 'tools/validation/new_fighter_scenarios.gd'; Report = 'evidence/new_fighter_scenarios.json'; Log = 'new_fighter_scenarios.log' },
        @{ Name = 'presentation_state'; Script = 'tools/validation/presentation_state.gd'; Report = 'evidence/presentation_state.json'; Log = 'presentation_state.log' },
        @{ Name = 'settings'; Script = 'tools/validation/settings_scenarios.gd'; Report = 'evidence/settings_scenarios.json'; Log = 'settings_scenarios.log' },
        @{ Name = 'pairing_soak'; Script = 'tools/validation/pairing_soak.gd'; Report = 'evidence/pairing_soak.json'; Log = 'pairing_soak.log' }
    )
if ($TaskRoster.passed -and $TaskResults[0].passed) {
    foreach ($TaskSuite in $TaskSuites) { Invoke-HeadlessSuite $TaskSuite }
}
$TaskFailed = @($TaskResults | Where-Object { -not $_.passed }).Count
$TaskRuntimeAfter = Get-ReleaseRuntimeInventory $TaskProject
$TaskRuntimeUnchanged = $TaskRuntimeBefore.sha256 -eq $TaskRuntimeAfter.sha256
$TaskSummary = [ordered]@{
    started_utc = $TaskStarted.ToString('o')
    finished_utc = [DateTime]::UtcNow.ToString('o')
    godot = $Godot
    passed = $TaskRoster.passed -and $TaskFailed -eq 0 -and $TaskResults.Count -eq (1 + $TaskSuites.Count) -and $TaskRuntimeUnchanged
    runtime = $TaskRuntimeBefore
    runtime_unchanged_during_validation = $TaskRuntimeUnchanged
    failed_suites = $TaskFailed
    completed_suites = $TaskResults.Count
    expected_suites = 1 + $TaskSuites.Count
    mapping_provenance_accepted = $TaskRoster.mapping_provenance_accepted
    roster_preflight = $TaskRoster
    allowed_missing_model_warnings = $false
    suites = @($TaskResults.ToArray())
    known_limitations = @(
        'The original five user-confirmed identity mappings and three filename-based source mappings are recorded; source model/texture licensing and commercial permissions are not established by this validation.',
        'Headless logic/content checks do not establish graphical quality, animation alignment, audio quality, hardware controller operation, or rendered performance.'
    )
}
[System.IO.File]::WriteAllText($TaskSummaryPath, ($TaskSummary | ConvertTo-Json -Depth 12), $TaskUtf8)
Write-Host ("Validation report: " + $TaskSummaryPath)
if (-not $TaskSummary.passed) { Write-Host 'VALIDATION FAILED'; exit 1 }
Write-Host ("VALIDATION PASSED: import and all {0} suites." -f $TaskSuites.Count)
exit 0
