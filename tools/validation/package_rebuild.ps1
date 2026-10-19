[CmdletBinding()]
param([Parameter(Mandatory=$true)][string]$PerformanceDirectory)
$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'release_provenance.ps1')
$taskRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$taskBuild = Join-Path $taskRoot 'builds/windows'
$taskGate = Get-Content -LiteralPath (Join-Path $taskRoot 'evidence/validation_all.json') -Raw | ConvertFrom-Json
$taskPackageCheck = Get-Content -LiteralPath (Join-Path $taskRoot 'evidence/windows_release_flow/validation.json') -Raw | ConvertFrom-Json
$taskManifest = Get-Content -LiteralPath (Join-Path $taskBuild 'build_manifest.json') -Raw | ConvertFrom-Json
$taskArt = Get-Content -LiteralPath (Join-Path $taskRoot 'evidence/characters/hero_rebuild/release_assets.json') -Raw | ConvertFrom-Json
if (-not $taskGate.passed -or -not $taskGate.roster_preflight.originals_preserved -or -not $taskArt.pass) { throw 'Source/art preservation gate has not passed.' }
if (-not $taskPackageCheck.passed -or -not $taskPackageCheck.build_unchanged_during_validation) { throw 'Windows package validation has not passed.' }
if ([DateTime]$taskPackageCheck.started_utc -lt [DateTime]$taskManifest.build_timestamp_utc) { throw 'Package validation predates the build.' }
if ($taskPackageCheck.executable_sha256 -ne $taskManifest.exe_sha256 -or $taskPackageCheck.pck_sha256 -ne $taskManifest.pck_sha256 -or $taskPackageCheck.build_manifest_sha256 -ne (Get-FileHash -LiteralPath (Join-Path $taskBuild 'build_manifest.json') -Algorithm SHA256).Hash) { throw 'Package validation belongs to a different EXE, PCK or manifest.' }
foreach ($taskEntry in @(@{name='RooftopRiot.exe';hash=$taskManifest.exe_sha256}, @{name='RooftopRiot.pck';hash=$taskManifest.pck_sha256})) {
    if ((Get-FileHash -LiteralPath (Join-Path $taskBuild $taskEntry.name)).Hash -ne $taskEntry.hash) { throw "Build changed: $($taskEntry.name)" }
}
$taskCurrentSource = Get-ReleaseRuntimeInventory (Join-Path $taskRoot 'Game File')
if (@($taskManifest.runtime_source_files).Count -eq 0 -or (Get-ReleaseInventoryHash $taskManifest.runtime_source_files) -ne $taskCurrentSource.sha256) { throw 'Current runtime source inventory differs from the exported build.' }
$taskProfileReceiptPath = Join-Path $PerformanceDirectory 'profile_provenance.json'
$taskProfileReceipt = Get-Content -LiteralPath $taskProfileReceiptPath -Raw | ConvertFrom-Json
$taskCurrentArt = Get-ReleaseProjectArt (Join-Path $taskRoot 'Game File')
if (-not $taskProfileReceipt.passed -or -not $taskProfileReceipt.unchanged_during_profiling -or $taskProfileReceipt.runtime.sha256 -ne $taskCurrentSource.sha256 -or (Get-ReleaseInventoryHash $taskProfileReceipt.runtime.files) -ne $taskCurrentSource.sha256) { throw 'Profiles do not match the current runtime source inventory.' }
if (-not $taskProfileReceipt.art.present -or $taskProfileReceipt.art.sha256 -ne $taskCurrentArt.sha256) { throw 'Profiles do not match the current accepted art report.' }
if ($taskProfileReceipt.harness_sha256 -ne (Get-FileHash -LiteralPath (Join-Path $PSScriptRoot 'rebuild_performance.gd') -Algorithm SHA256).Hash) { throw 'Profiles used a different performance harness.' }
if (@($taskProfileReceipt.cases).Count -ne 8) { throw 'Profile receipt must contain all eight release cases.' }
foreach ($taskFighter in $taskArt.fighters) {
    foreach ($taskPair in @(
        @{path=('Game File/assets/characters/' + $taskFighter.fighter + '.glb');hash=$taskFighter.high_sha256},
        @{path=('Game File/assets/characters/' + $taskFighter.fighter + '_low.glb');hash=$taskFighter.low_sha256},
        @{path=('source_art/characters/' + $taskFighter.fighter + '/curated.blend');hash=$taskFighter.curated_sha256},
        @{path=('Game File/assets/portraits/' + $taskFighter.fighter + '.png');hash=$taskFighter.portrait_sha256}
    )) {
        if ((Get-FileHash -LiteralPath (Join-Path $taskRoot $taskPair.path)).Hash -ne $taskPair.hash) { throw "Art changed after acceptance: $($taskPair.path)" }
    }
}
$taskPerformance = @()
foreach ($taskArena in @('rooftop_riot','lunar_reach')) {
    foreach ($taskQuality in @('high','low')) {
        foreach ($taskPlayers in @(2,4)) {
            $taskPath = Join-Path $PerformanceDirectory ('{0}_{1}_{2}p.json' -f $taskArena,$taskQuality,$taskPlayers)
            $taskCaseName = '{0}_{1}_{2}p' -f $taskArena,$taskQuality,$taskPlayers
            $taskCaseRecords = @($taskProfileReceipt.cases | Where-Object { $_.case -eq $taskCaseName })
            if ($taskCaseRecords.Count -ne 1) { throw "Missing or duplicate profile case: $taskCaseName" }
            $taskCaseRecord = $taskCaseRecords[0]
            if ($taskCaseRecord.file -ne ($taskCaseName + '.json') -or $taskCaseRecord.arena -ne $taskArena -or $taskCaseRecord.quality -ne $taskQuality -or $taskCaseRecord.players -ne $taskPlayers -or $taskCaseRecord.requested_seconds -lt 60 -or $taskCaseRecord.sha256 -ne (Get-FileHash -LiteralPath $taskPath -Algorithm SHA256).Hash) { throw "Profile case provenance differs: $taskCaseName" }
            $taskProfile = Get-Content -LiteralPath $taskPath -Raw | ConvertFrom-Json
            if ($taskProfile.arena -ne $taskArena -or $taskProfile.quality -ne $taskQuality -or $taskProfile.players -ne $taskPlayers -or $taskProfile.readback_inside_sample_window -ne $false) { throw "Profile contains the wrong case or capture overhead: $taskPath" }
            if ($taskProfile.duration_seconds -lt 59 -or $taskProfile.simulation_ticks_in_sample_window -lt 3300 -or -not $taskProfile.viewport_render_gpu.available -or $taskProfile.captured_pixels -ne '(1920, 1080)') { throw "Incomplete profile: $taskPath" }
            $taskPerformance += [ordered]@{file=[IO.Path]::GetFullPath($taskPath);sha256=(Get-FileHash -LiteralPath $taskPath).Hash}
        }
    }
}
# Package only the current delivery files; preserve unrelated historical notes in
# the build directory without silently redistributing them as current evidence.
foreach ($taskDocument in @('WINDOWS_BUILD_README.md','PROVENANCE.md','VALIDATION.md','PERFORMANCE.md','animation_pipeline.md','animation_validation.md')) {
    $taskDestination = if ($taskDocument -eq 'WINDOWS_BUILD_README.md') { 'README.md' } else { $taskDocument }
    Copy-Item -LiteralPath (Join-Path $taskRoot ('docs/' + $taskDocument)) -Destination (Join-Path $taskBuild $taskDestination)
}
$taskNames = @('RooftopRiot.exe','RooftopRiot.pck','README.md','Launch-Mobile.cmd','Launch-ForwardPlus.cmd','build_manifest.json','PROVENANCE.md','VALIDATION.md','PERFORMANCE.md','animation_pipeline.md','animation_validation.md','MOTION_CREDITS.md','LUNAR_ASSET_CREDITS.md')
$taskFiles = @($taskNames | ForEach-Object { Join-Path $taskBuild $_ })
$taskZip = Join-Path $taskRoot 'builds/RooftopRiot-Rebuild-Windows.zip'
Compress-Archive -LiteralPath $taskFiles -DestinationPath $taskZip -CompressionLevel Optimal -Force
Add-Type -AssemblyName System.IO.Compression.FileSystem
$taskArchive = [IO.Compression.ZipFile]::OpenRead($taskZip)
$taskRecords = @()
try {
    if ($taskArchive.Entries.Count -ne $taskNames.Count) { throw 'Unexpected ZIP contents.' }
    foreach ($taskName in $taskNames) {
        $taskEntry = $taskArchive.GetEntry($taskName)
        if ($null -eq $taskEntry) { throw "ZIP entry missing: $taskName" }
        $taskStream = $taskEntry.Open()
        $taskHasher = [Security.Cryptography.SHA256]::Create()
        try { $taskHash = [BitConverter]::ToString($taskHasher.ComputeHash($taskStream)).Replace('-','') }
        finally { $taskHasher.Dispose(); $taskStream.Dispose() }
        if ($taskHash -ne (Get-FileHash -LiteralPath (Join-Path $taskBuild $taskName)).Hash) { throw "ZIP byte verification failed: $taskName" }
        $taskRecords += [ordered]@{file=$taskName;bytes=$taskEntry.Length;sha256=$taskHash}
    }
} finally { $taskArchive.Dispose() }
$taskReceipt = [ordered]@{
    generated_at_utc=[DateTime]::UtcNow.ToString('o'); passed=$true; archive=$taskZip
    archive_sha256=(Get-FileHash -LiteralPath $taskZip).Hash; archive_bytes=(Get-Item -LiteralPath $taskZip).Length
    files=$taskRecords; performance=$taskPerformance
    source_gate_sha256=(Get-FileHash -LiteralPath (Join-Path $taskRoot 'evidence/validation_all.json')).Hash
    package_validation_sha256=(Get-FileHash -LiteralPath (Join-Path $taskRoot 'evidence/windows_release_flow/validation.json')).Hash
    asset_validation_sha256=(Get-FileHash -LiteralPath (Join-Path $taskRoot 'evidence/characters/hero_rebuild/release_assets.json')).Hash
    profile_provenance_sha256=(Get-FileHash -LiteralPath $taskProfileReceiptPath -Algorithm SHA256).Hash
    editable_art=(Join-Path $taskRoot 'source_art/characters'); tools=(Join-Path $taskRoot 'tools/blender')
    limitations=@('Human gameplay/continuous-motion/audio acceptance pending.','Physical multiple-controller operation and weaker-PC performance unverified.')
}
$taskReceipt | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath (Join-Path $taskRoot 'evidence/rebuild/delivery.json')
Write-Output "DELIVERY PASS: $taskZip ($($taskReceipt.archive_bytes) bytes); every archive entry decoded and SHA-256 verified."
