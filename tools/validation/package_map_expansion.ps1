[CmdletBinding()]
param(
    [Parameter(Mandatory=$true)][string]$PerformanceDirectory,
    [string]$ArchivePath = '',
    [string]$DeliveryReceiptPath = ''
)
$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'release_provenance.ps1')

# This separate delivery preserves the prior rebuild archive and packager. All
# gates are read and verified before any build documentation or archive is made.
$taskRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$taskProject = Join-Path $taskRoot 'Game File'
$taskBuild = Join-Path $taskRoot 'builds/windows'
$PerformanceDirectory = [IO.Path]::GetFullPath($PerformanceDirectory)
if ([string]::IsNullOrWhiteSpace($ArchivePath)) { $ArchivePath = Join-Path $taskRoot 'builds/RooftopRiot-Five-Arenas-Windows.zip' }
if ([string]::IsNullOrWhiteSpace($DeliveryReceiptPath)) { $DeliveryReceiptPath = Join-Path $taskRoot 'evidence/map_expansion/delivery.json' }
$taskZip = [IO.Path]::GetFullPath($ArchivePath)
$taskReceiptPath = [IO.Path]::GetFullPath($DeliveryReceiptPath)
if ([IO.Path]::GetExtension($taskZip) -ine '.zip' -or [IO.Path]::GetExtension($taskReceiptPath) -ine '.json') { throw 'Delivery destinations must be a ZIP archive and JSON receipt.' }
$taskArenas = @('rooftop_riot','lunar_reach','verdant_shrine','abyssal_observatory','ember_foundry')
$taskNewArenas = @('verdant_shrine','abyssal_observatory','ember_foundry')
$taskGatePath = Join-Path $taskRoot 'evidence/validation_all.json'
$taskPackageCheckPath = Join-Path $taskRoot 'evidence/windows_release_flow/validation.json'
$taskReleasePath = Join-Path $taskRoot 'evidence/map_expansion/release_validation.json'
$taskFlowPath = Join-Path $taskRoot 'evidence/rebuild/match_flow.json'
$taskArtPath = Join-Path $taskRoot 'evidence/characters/hero_rebuild/release_assets.json'
$taskArenaArtPath = Join-Path $taskRoot 'source_art/environment/arena_artwork_manifest.json'
$taskManifestPath = Join-Path $taskBuild 'build_manifest.json'
$taskProfileReceiptPath = Join-Path $PerformanceDirectory 'profile_provenance.json'

function Assert-MapPackageHash([string]$Path,[string]$Expected) {
    if ($Expected -notmatch '^[a-fA-F0-9]{64}$' -or -not (Test-Path -LiteralPath $Path -PathType Leaf)) { throw "Missing file or SHA-256: $Path" }
    if ((Get-FileHash -LiteralPath $Path -Algorithm SHA256).Hash -ne $Expected) { throw "File changed after validation: $Path" }
}
function Assert-MapPackageRecord($Record) {
    Assert-MapPackageHash ([string]$Record.path) ([string]$Record.sha256)
    if ((Get-Item -LiteralPath $Record.path).Length -ne $Record.bytes) { throw "File size differs: $($Record.path)" }
}
function Assert-MapPackageBuild($Hashes) {
    foreach ($taskKey in @('executable','pck','manifest')) {
        $taskExpected = switch ($taskKey) {
            'executable' { $taskManifest.exe_sha256 }
            'pck' { $taskManifest.pck_sha256 }
            'manifest' { $taskManifestHash }
        }
        if ($Hashes.$taskKey.sha256 -ne $taskExpected) { throw "Release receipt belongs to a different $taskKey." }
        Assert-MapPackageRecord $Hashes.$taskKey
    }
}
function Assert-MapPackageInventory($Inventory,[string]$Expected,[string]$Label) {
    if ($Inventory.sha256 -ne $Expected -or @($Inventory.files).Count -eq 0 -or (Get-ReleaseInventoryHash $Inventory.files) -ne $Expected) { throw "$Label does not match the current runtime inventory." }
}
function Assert-MapPackagePng($Record) {
    Assert-MapPackageRecord $Record
    $taskPngStream = [IO.File]::OpenRead($Record.path)
    $taskHeader = New-Object byte[] 24
    try { if ($taskPngStream.Read($taskHeader,0,24) -ne 24) { throw 'Truncated PNG header.' } }
    finally { $taskPngStream.Dispose() }
    if ([BitConverter]::ToString($taskHeader,0,8) -ne '89-50-4E-47-0D-0A-1A-0A' -or [BitConverter]::ToString($taskHeader,12,4) -ne '49-48-44-52') { throw "Invalid PNG header: $($Record.path)" }
    $taskWidth = ([int]$taskHeader[16] -shl 24) -bor ([int]$taskHeader[17] -shl 16) -bor ([int]$taskHeader[18] -shl 8) -bor [int]$taskHeader[19]
    $taskHeight = ([int]$taskHeader[20] -shl 24) -bor ([int]$taskHeader[21] -shl 16) -bor ([int]$taskHeader[22] -shl 8) -bor [int]$taskHeader[23]
    if ($taskWidth -ne 1920 -or $taskHeight -ne 1080 -or $Record.width -ne 1920 -or $Record.height -ne 1080) { throw "Release capture is not 1920x1080: $($Record.path)" }
}

$taskGate = Get-Content -LiteralPath $taskGatePath -Raw | ConvertFrom-Json
$taskPackageCheck = Get-Content -LiteralPath $taskPackageCheckPath -Raw | ConvertFrom-Json
$taskRelease = Get-Content -LiteralPath $taskReleasePath -Raw | ConvertFrom-Json
$taskFlow = Get-Content -LiteralPath $taskFlowPath -Raw | ConvertFrom-Json
$taskArt = Get-Content -LiteralPath $taskArtPath -Raw | ConvertFrom-Json
$taskArenaArt = Get-Content -LiteralPath $taskArenaArtPath -Raw | ConvertFrom-Json
$taskManifest = Get-Content -LiteralPath $taskManifestPath -Raw | ConvertFrom-Json
$taskManifestHash = (Get-FileHash -LiteralPath $taskManifestPath -Algorithm SHA256).Hash
$taskCurrentSource = Get-ReleaseRuntimeInventory $taskProject
$taskCurrentArt = Get-ReleaseProjectArt $taskProject

if (-not $taskGate.passed -or -not $taskGate.runtime_unchanged_during_validation -or -not $taskGate.roster_preflight.originals_preserved -or $taskGate.failed_suites -ne 0 -or $taskGate.completed_suites -ne $taskGate.expected_suites -or $taskGate.completed_suites -lt 12) { throw 'The current complete source/original-preservation gate has not passed.' }
Assert-MapPackageInventory $taskGate.runtime $taskCurrentSource.sha256 'Source gate'
if (@($taskGate.suites).Count -ne $taskGate.expected_suites) { throw 'Source suite records are incomplete.' }
foreach ($taskSuite in $taskGate.suites) {
    if (-not $taskSuite.passed -or $taskSuite.exit_code -ne 0 -or @($taskSuite.problems).Count -gt 0 -or @($taskSuite.unexpected_error_lines).Count -gt 0 -or @($taskSuite.unexpected_warning_lines).Count -gt 0) { throw "Source suite failed: $($taskSuite.name)" }
    if ($taskSuite.script_sha256) {
        if ($taskSuite.command -notmatch '--script\s+"([^"]+)"') { throw "Cannot identify suite script: $($taskSuite.name)" }
        Assert-MapPackageHash $Matches[1] $taskSuite.script_sha256
    }
}
if (@($taskGate.roster_preflight.original_sources).Count -ne 8) { throw 'Expected eight preserved supplied originals.' }
foreach ($taskOriginal in $taskGate.roster_preflight.original_sources) {
    if (-not $taskOriginal.preserved -or $taskOriginal.actual_sha256 -ne $taskOriginal.expected_sha256) { throw "Original preservation failed: $($taskOriginal.path)" }
    Assert-MapPackageHash (Join-Path $taskRoot $taskOriginal.path) $taskOriginal.expected_sha256
}
if (-not $taskArt.pass -or @($taskArt.fighters).Count -ne 8 -or @($taskArt.fighters.fighter | Sort-Object -Unique).Count -ne 8) { throw 'Accepted eight-fighter art report is incomplete.' }
foreach ($taskFighter in $taskArt.fighters) {
    foreach ($taskPair in @(
        @{path=('Game File/assets/characters/' + $taskFighter.fighter + '.glb');hash=$taskFighter.high_sha256},
        @{path=('Game File/assets/characters/' + $taskFighter.fighter + '_low.glb');hash=$taskFighter.low_sha256},
        @{path=('source_art/characters/' + $taskFighter.fighter + '/curated.blend');hash=$taskFighter.curated_sha256},
        @{path=('Game File/assets/portraits/' + $taskFighter.fighter + '.png');hash=$taskFighter.portrait_sha256}
    )) { Assert-MapPackageHash (Join-Path $taskRoot $taskPair.path) $taskPair.hash }
}
if (@($taskArenaArt.assets).Count -ne 3 -or -not $taskArenaArt.supplied_originals_all_preserved) { throw 'Three-arena artwork provenance is incomplete.' }
foreach ($taskArena in $taskNewArenas) {
    $taskAssets = @($taskArenaArt.assets | Where-Object { $_.arena_id -eq $taskArena })
    if ($taskAssets.Count -ne 1) { throw "Missing/duplicate arena artwork record: $taskArena" }
    $taskAsset = $taskAssets[0]
    if ($taskAsset.runtime_path -ne ('Game File/assets/arenas/' + $taskArena + '/backdrop.png') -or -not $taskAsset.runtime_is_byte_identical_original -or $taskAsset.runtime_sha256 -ne $taskAsset.original_sha256) { throw "Artwork is no longer the accepted original: $taskArena" }
    Assert-MapPackageHash (Join-Path $taskRoot $taskAsset.runtime_path) $taskAsset.runtime_sha256
    if ((Get-Item -LiteralPath (Join-Path $taskRoot $taskAsset.runtime_path)).Length -ne $taskAsset.bytes) { throw "Artwork size differs: $taskArena" }
}

Assert-MapPackageHash (Join-Path $taskBuild 'RooftopRiot.exe') $taskManifest.exe_sha256
Assert-MapPackageHash (Join-Path $taskBuild 'RooftopRiot.pck') $taskManifest.pck_sha256
if (@($taskManifest.runtime_source_files).Count -eq 0 -or (Get-ReleaseInventoryHash $taskManifest.runtime_source_files) -ne $taskCurrentSource.sha256) { throw 'Current runtime source differs from the exported build.' }
if (-not $taskPackageCheck.passed -or -not $taskPackageCheck.build_unchanged_during_validation -or @($taskPackageCheck.problems).Count -gt 0) { throw 'Windows package/UI validation has not passed.' }
if ([DateTime]$taskPackageCheck.started_utc -lt [DateTime]$taskManifest.build_timestamp_utc -or $taskPackageCheck.executable_sha256 -ne $taskManifest.exe_sha256 -or $taskPackageCheck.pck_sha256 -ne $taskManifest.pck_sha256 -or $taskPackageCheck.build_manifest_sha256 -ne $taskManifestHash) { throw 'Windows package validation belongs to a different or older build.' }

if (-not $taskRelease.passed -or -not $taskRelease.build_unchanged_during_validation -or @($taskRelease.problems).Count -gt 0 -or @($taskRelease.cases).Count -ne 3) { throw 'Three-arena actual Windows EXE validation has not passed.' }
if ([DateTime]$taskRelease.started_utc -lt [DateTime]$taskManifest.build_timestamp_utc) { throw 'Map release validation predates this build.' }
Assert-MapPackageHash (Join-Path $PSScriptRoot 'validate_map_release.ps1') $taskRelease.harness_sha256
foreach ($taskMoment in @('before','after')) {
    $taskInventory = $taskRelease.('runtime_inventory_' + $taskMoment)
    # The release runner stores the canonical inventory hash and file count;
    # full entries are retained in the immutable exported build manifest.
    if ($taskInventory.sha256 -ne $taskCurrentSource.sha256 -or $taskInventory.files -ne @($taskCurrentSource.files).Count -or $taskInventory.manifest_inventory_sha256 -ne $taskCurrentSource.sha256) { throw 'Release validation used another manifest source inventory.' }
    Assert-MapPackageBuild $taskRelease.('build_hashes_' + $taskMoment)
}
foreach ($taskArena in $taskNewArenas) {
    $taskCases = @($taskRelease.cases | Where-Object { $_.requested_arena -eq $taskArena })
    if ($taskCases.Count -ne 1) { throw "Missing/duplicate actual-EXE arena case: $taskArena" }
    $taskCase = $taskCases[0]
    if (-not $taskCase.passed -or $taskCase.reported_arena -ne $taskArena -or $taskCase.exit_code -ne 0 -or $taskCase.timed_out -ne $false -or $taskCase.ticks -ne 600 -or $taskCase.contacts -le 0 -or @($taskCase.fighter_ids).Count -ne 4 -or @($taskCase.problems).Count -gt 0 -or @($taskCase.errors).Count -gt 0 -or @($taskCase.warnings).Count -gt 0) { throw "Incomplete actual-EXE case: $taskArena" }
    if (@($taskCase.reported_input_providers).Count -ne 4 -or @($taskCase.reported_input_providers | Where-Object { $_ -cne 'res://input/cpu_input_provider.gd' }).Count -gt 0 -or $taskCase.renderer -ne 'forward_plus' -or $taskCase.settings.graphics -ne 'High' -or $taskCase.settings.resolution -ne '1920x1080') { throw "Incorrect release case configuration: $taskArena" }
    Assert-MapPackageBuild $taskCase.build_hashes_before
    Assert-MapPackageBuild $taskCase.build_hashes_after
    Assert-MapPackageRecord $taskCase.runtime_report_file
    Assert-MapPackagePng $taskCase.capture
    Assert-MapPackageRecord $taskCase.log_files.engine
    Assert-MapPackageRecord $taskCase.log_files.native
    $taskSmoke = Get-Content -LiteralPath $taskCase.runtime_report_file.path -Raw | ConvertFrom-Json
    if ($taskSmoke.arena -ne $taskArena -or $taskSmoke.ticks -ne 600 -or $taskSmoke.contacts -ne $taskCase.contacts -or @($taskSmoke.fighters).Count -ne 4 -or $taskSmoke.profile_mode -ne $true -or $taskSmoke.captured_pixel_size -ne '(1920, 1080)') { throw "Actual runtime report contradicts release case: $taskArena" }
    $taskLogText = [IO.File]::ReadAllText($taskCase.log_files.engine.path) + [IO.File]::ReadAllText($taskCase.log_files.native.path)
    if ($taskLogText -match '(?im)\b(?:SCRIPT ERROR|Parse Error|ERROR)\s*:|^\s*WARNING\s*:|\b(?:CRASH|FATAL)\b' -or $taskLogText -notmatch 'ROOFTOP_READY renderer=forward_plus' -or $taskLogText -notmatch 'SMOKE_REPORT ') { throw "Release native log is incomplete or contains errors: $taskArena" }
}

# The lifecycle harness records exactly seven checks per selected arena. It is
# accelerated gameplay through main/results/rematch, not a performance sample.
if ($taskFlow.checks -ne 35 -or $taskFlow.failures -ne 0 -or $taskFlow.graphical -ne $true -or @($taskFlow.results).Count -ne 35 -or @($taskFlow.results | Where-Object { $_.passed -ne $true }).Count -gt 0 -or @($taskFlow.matches).Count -ne 5) { throw 'Five-arena/35-check graphical lifecycle validation is incomplete.' }
foreach ($taskArena in $taskArenas) {
    $taskMatches = @($taskFlow.matches | Where-Object { $_.arena -eq $taskArena })
    $taskArenaChecks = @($taskFlow.results | Where-Object { $_.name.StartsWith($taskArena + ' ') })
    if ($taskMatches.Count -ne 1 -or $taskArenaChecks.Count -ne 7) { throw "Missing/duplicate lifecycle arena: $taskArena" }
    $taskMatch = $taskMatches[0]
    if ($taskMatch.ticks -le 0 -or $taskMatch.contacts -le 0 -or $taskMatch.kos -le 0 -or -not $taskMatch.result.PSObject.Properties['winner'] -or [string]::IsNullOrWhiteSpace([string]$taskMatch.result.reason)) { throw "Lifecycle lacks a natural completed match: $taskArena" }
}
$taskLatestRuntimeWrite = ($taskCurrentSource.files | ForEach-Object { (Get-Item -LiteralPath (Join-Path $taskProject $_.path)).LastWriteTimeUtc } | Sort-Object -Descending | Select-Object -First 1)
$taskFlowWrite = (Get-Item -LiteralPath $taskFlowPath).LastWriteTimeUtc
if ($taskFlowWrite -lt $taskLatestRuntimeWrite -or $taskFlowWrite -lt (Get-Item -LiteralPath (Join-Path $PSScriptRoot 'rebuild_match_flow.gd')).LastWriteTimeUtc) { throw 'Lifecycle report predates current runtime or lifecycle harness edits.' }

$taskProfileReceipt = Get-Content -LiteralPath $taskProfileReceiptPath -Raw | ConvertFrom-Json
if (-not $taskProfileReceipt.passed -or -not $taskProfileReceipt.unchanged_during_profiling -or @($taskProfileReceipt.cases).Count -ne 10) { throw 'Expected ten completed unchanged four-player profile cases.' }
Assert-MapPackageInventory $taskProfileReceipt.runtime $taskCurrentSource.sha256 'Profiles'
if (-not $taskProfileReceipt.art.present -or $taskProfileReceipt.art.sha256 -ne $taskCurrentArt.sha256) { throw 'Profiles used a different accepted fighter art report.' }
Assert-MapPackageHash (Join-Path $PSScriptRoot 'rebuild_performance.gd') $taskProfileReceipt.harness_sha256
$taskPerformance = @()
foreach ($taskArena in $taskArenas) {
    foreach ($taskQuality in @('high','low')) {
        $taskCaseName = '{0}_{1}_4p' -f $taskArena,$taskQuality
        $taskPath = Join-Path $PerformanceDirectory ($taskCaseName + '.json')
        $taskCases = @($taskProfileReceipt.cases | Where-Object { $_.case -eq $taskCaseName })
        if ($taskCases.Count -ne 1) { throw "Missing/duplicate profile case: $taskCaseName" }
        $taskCase = $taskCases[0]
        if ($taskCase.file -ne ($taskCaseName + '.json') -or $taskCase.arena -ne $taskArena -or $taskCase.quality -ne $taskQuality -or $taskCase.players -ne 4 -or $taskCase.requested_seconds -lt 60) { throw "Profile case provenance differs: $taskCaseName" }
        Assert-MapPackageHash $taskPath $taskCase.sha256
        $taskProfile = Get-Content -LiteralPath $taskPath -Raw | ConvertFrom-Json
        if ($taskProfile.arena -ne $taskArena -or $taskProfile.quality -ne $taskQuality -or $taskProfile.players -ne 4 -or $taskProfile.readback_inside_sample_window -ne $false -or $taskProfile.duration_seconds -lt 59 -or $taskProfile.simulation_ticks_in_sample_window -lt 3300 -or $taskProfile.frame_intervals.count -lt 100 -or -not $taskProfile.viewport_render_gpu.available -or -not $taskProfile.viewport_render_cpu.available -or $taskProfile.captured_pixels -ne '(1920, 1080)') { throw "Incomplete 1080p CPU/GPU profile: $taskCaseName" }
        $taskPerformance += [ordered]@{case=$taskCaseName;file=$taskPath;sha256=$taskCase.sha256;frame_p95_ms=$taskProfile.frame_intervals.p95_ms;frame_p99_ms=$taskProfile.frame_intervals.p99_ms;gpu_p95_ms=$taskProfile.viewport_render_gpu.p95_ms}
    }
}

# Copy only explicitly chosen current delivery documents. build_manifest.json
# stays byte-identical to the one already verified by both release validators.
$taskPayload = @(
    @{file='RooftopRiot.exe';source=(Join-Path $taskBuild 'RooftopRiot.exe')},
    @{file='RooftopRiot.pck';source=(Join-Path $taskBuild 'RooftopRiot.pck')},
    @{file='build_manifest.json';source=$taskManifestPath},
    @{file='Launch-Mobile.cmd';source=(Join-Path $PSScriptRoot 'Launch-Mobile.cmd')},
    @{file='Launch-ForwardPlus.cmd';source=(Join-Path $PSScriptRoot 'Launch-ForwardPlus.cmd')},
    @{file='MOTION_CREDITS.md';source=(Join-Path $taskRoot 'source_art/motion/README.md')},
    @{file='LUNAR_ASSET_CREDITS.md';source=(Join-Path $taskProject 'assets/lunar_reach/CREDITS.md')}
)
foreach ($taskDocument in @('WINDOWS_BUILD_README.md','PROVENANCE.md','VALIDATION.md','PERFORMANCE.md','animation_pipeline.md','animation_validation.md','MAP_EXPANSION.md')) {
    $taskName = if ($taskDocument -eq 'WINDOWS_BUILD_README.md') { 'README.md' } else { $taskDocument }
    $taskPayload += @{file=$taskName;source=(Join-Path $taskRoot ('docs/' + $taskDocument))}
}
foreach ($taskArena in $taskNewArenas) { $taskPayload += @{file=('maps/' + $taskArena + '.md');source=(Join-Path $taskRoot ('docs/maps/' + $taskArena + '.md'))} }
$taskPayload += @{file='maps/artwork_manifest.json';source=$taskArenaArtPath}
foreach ($taskArena in $taskNewArenas) { $taskPayload += @{file=('maps/' + $taskArena + '_CREDITS.md');source=(Join-Path $taskProject ('assets/arenas/' + $taskArena + '/CREDITS.md'))} }
$taskPayloadRecords = @()
foreach ($taskItem in $taskPayload) {
    $taskDestination = Join-Path $taskBuild $taskItem.file
    if (-not (Test-Path -LiteralPath $taskItem.source -PathType Leaf)) { throw "Missing delivery document: $($taskItem.source)" }
    New-Item -ItemType Directory -Path (Split-Path -Parent $taskDestination) -Force | Out-Null
    if ([IO.Path]::GetFullPath($taskItem.source) -ne [IO.Path]::GetFullPath($taskDestination)) { Copy-Item -LiteralPath $taskItem.source -Destination $taskDestination }
    $taskHash = (Get-FileHash -LiteralPath $taskItem.source -Algorithm SHA256).Hash
    Assert-MapPackageHash $taskDestination $taskHash
    $taskPayloadRecords += [ordered]@{file=$taskItem.file;bytes=(Get-Item -LiteralPath $taskDestination).Length;sha256=$taskHash}
}
$taskEvidence = [ordered]@{}
foreach ($taskEvidenceItem in @(
    @{name='source_gate';path=$taskGatePath},@{name='windows_package_validation';path=$taskPackageCheckPath},
    @{name='map_release_validation';path=$taskReleasePath},@{name='match_lifecycle';path=$taskFlowPath},
    @{name='accepted_fighter_art';path=$taskArtPath},@{name='arena_artwork';path=$taskArenaArtPath},@{name='profile_provenance';path=$taskProfileReceiptPath}
)) { $taskEvidence[$taskEvidenceItem.name] = [ordered]@{path=$taskEvidenceItem.path;sha256=(Get-FileHash -LiteralPath $taskEvidenceItem.path -Algorithm SHA256).Hash} }
$taskNames = @($taskPayload.file) + @('package_manifest.json')
$taskPackageManifest = [ordered]@{
    generated_at_utc=[DateTime]::UtcNow.ToString('o'); product='Rooftop Riot - Five Arenas'; arenas=$taskArenas
    build_manifest_sha256=$taskManifestHash; runtime_source_sha256=$taskCurrentSource.sha256
    expected_archive_entries=$taskNames; files=$taskPayloadRecords; evidence=$taskEvidence
    note='files lists all payloads except this manifest; the external delivery receipt also hashes this manifest and every decoded ZIP entry.'
}
$taskPackageManifestPath = Join-Path $taskBuild 'package_manifest.json'
$taskPackageManifest | ConvertTo-Json -Depth 10 | Set-Content -LiteralPath $taskPackageManifestPath -Encoding utf8
$taskPackageManifestHash = (Get-FileHash -LiteralPath $taskPackageManifestPath -Algorithm SHA256).Hash

New-Item -ItemType Directory -Path (Split-Path -Parent $taskZip) -Force | Out-Null
Add-Type -AssemblyName System.IO.Compression.FileSystem
$taskZipStream = [IO.File]::Open($taskZip,[IO.FileMode]::Create,[IO.FileAccess]::Write,[IO.FileShare]::None)
$taskArchive = [IO.Compression.ZipArchive]::new($taskZipStream,[IO.Compression.ZipArchiveMode]::Create,$false)
try {
    foreach ($taskName in $taskNames) { [void][IO.Compression.ZipFileExtensions]::CreateEntryFromFile($taskArchive,(Join-Path $taskBuild $taskName),$taskName,[IO.Compression.CompressionLevel]::Optimal) }
} finally { $taskArchive.Dispose(); $taskZipStream.Dispose() }
$taskArchive = [IO.Compression.ZipFile]::OpenRead($taskZip)
$taskRecords = @()
try {
    if ($taskArchive.Entries.Count -ne 22 -or $taskNames.Count -ne 22 -or @($taskArchive.Entries.FullName | Sort-Object -Unique).Count -ne 22) { throw 'ZIP contains an unexpected count or duplicate entries.' }
    foreach ($taskEntry in $taskArchive.Entries) { if ($taskEntry.FullName -cnotin $taskNames) { throw "Unexpected ZIP entry: $($taskEntry.FullName)" } }
    foreach ($taskName in $taskNames) {
        $taskEntry = $taskArchive.GetEntry($taskName)
        if ($null -eq $taskEntry) { throw "ZIP entry missing: $taskName" }
        $taskStream = $taskEntry.Open()
        $taskHasher = [Security.Cryptography.SHA256]::Create()
        try { $taskHash = [BitConverter]::ToString($taskHasher.ComputeHash($taskStream)).Replace('-','') }
        finally { $taskHasher.Dispose(); $taskStream.Dispose() }
        $taskExpected = if ($taskName -eq 'package_manifest.json') { $taskPackageManifestHash } else { ($taskPayloadRecords | Where-Object { $_.file -ceq $taskName }).sha256 }
        if ($taskHash -ne $taskExpected) { throw "ZIP bytes differ from package manifest: $taskName" }
        Assert-MapPackageHash (Join-Path $taskBuild $taskName) $taskExpected
        $taskRecords += [ordered]@{file=$taskName;bytes=$taskEntry.Length;sha256=$taskHash}
    }
} finally { $taskArchive.Dispose() }
foreach ($taskItem in $taskPayload) { Assert-MapPackageHash $taskItem.source ($taskPayloadRecords | Where-Object { $_.file -ceq $taskItem.file }).sha256 }
foreach ($taskEvidenceRecord in $taskEvidence.Values) { Assert-MapPackageRecord ([pscustomobject]@{path=$taskEvidenceRecord.path;sha256=$taskEvidenceRecord.sha256;bytes=(Get-Item -LiteralPath $taskEvidenceRecord.path).Length}) }
if ((Get-ReleaseRuntimeInventory $taskProject).sha256 -ne $taskCurrentSource.sha256) { throw 'Runtime source changed during packaging.' }
$taskReceipt = [ordered]@{
    generated_at_utc=[DateTime]::UtcNow.ToString('o'); passed=$true; archive=$taskZip
    archive_sha256=(Get-FileHash -LiteralPath $taskZip -Algorithm SHA256).Hash; archive_bytes=(Get-Item -LiteralPath $taskZip).Length
    arenas=$taskArenas; files=$taskRecords; exact_entry_set_verified=$true; every_entry_decoded_and_sha256_verified=$true
    package_manifest_sha256=$taskPackageManifestHash; build_manifest_sha256=$taskManifestHash; runtime_source_sha256=$taskCurrentSource.sha256
    evidence=$taskEvidence; performance=$taskPerformance; full_match_count=5; lifecycle_checks=35; actual_new_arena_release_smokes=3
    editable_stage_sources=(Join-Path $taskProject 'stages'); editable_character_art=(Join-Path $taskRoot 'source_art/characters'); tools=$PSScriptRoot
    limitations=@('Graphical captures and automated matches are not human gameplay or audio acceptance.','Physical multiple-controller operation and weaker-PC performance remain unverified.','The ten performance cases measure this workstation at 1080p with four CPU fighters, not every hardware configuration.')
}
New-Item -ItemType Directory -Path (Split-Path -Parent $taskReceiptPath) -Force | Out-Null
$taskReceipt | ConvertTo-Json -Depth 12 | Set-Content -LiteralPath $taskReceiptPath -Encoding utf8
Write-Output "FIVE ARENAS DELIVERY PASS: $taskZip ($($taskReceipt.archive_bytes) bytes); all 22 entries decoded and SHA-256 verified."
