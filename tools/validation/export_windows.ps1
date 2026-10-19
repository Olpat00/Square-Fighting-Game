param([string]$Godot = 'D:\Game Engines\Godot\Godot_v4.7.2-stable_win64_console.exe')
$ErrorActionPreference = 'Stop'
$TaskRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$TaskProject = Join-Path $TaskRoot 'Game File'
$TaskBuild = Join-Path $TaskRoot 'builds/windows'
New-Item -ItemType Directory -Path $TaskBuild -Force | Out-Null
& $Godot --headless --path $TaskProject --export-release 'Windows Desktop' (Join-Path $TaskBuild 'RooftopRiot.exe')
if ($LASTEXITCODE -ne 0) { throw "Godot export failed: $LASTEXITCODE" }
Copy-Item -LiteralPath (Join-Path $TaskRoot 'docs/WINDOWS_BUILD_README.md') -Destination (Join-Path $TaskBuild 'README.md')
Copy-Item -LiteralPath (Join-Path $PSScriptRoot 'Launch-Mobile.cmd') -Destination $TaskBuild
Copy-Item -LiteralPath (Join-Path $PSScriptRoot 'Launch-ForwardPlus.cmd') -Destination $TaskBuild
Copy-Item -LiteralPath (Join-Path $TaskRoot 'docs/PROVENANCE.md') -Destination $TaskBuild
Copy-Item -LiteralPath (Join-Path $TaskRoot 'source_art/motion/README.md') -Destination (Join-Path $TaskBuild 'MOTION_CREDITS.md')
Copy-Item -LiteralPath (Join-Path $TaskProject 'assets/lunar_reach/CREDITS.md') -Destination (Join-Path $TaskBuild 'LUNAR_ASSET_CREDITS.md')
$TaskSourceRecords = @(Get-ChildItem -LiteralPath $TaskProject -Recurse -File | Where-Object { $_.FullName -notmatch '[\\/]\.godot[\\/]' -and $_.Extension -in @('.gd','.gdshader','.godot','.tscn','.tres','.glb','.png','.jpg','.jpeg','.svg','.wav','.ogg','.json','.import','.uid','.cfg') -and $_.Name -notlike 'source_*' -and $_.Name -notin @('validate_input.gd','engine.png') } | Sort-Object FullName | ForEach-Object {
    [ordered]@{path=$_.FullName.Substring($TaskProject.Length + 1).Replace('\','/'); bytes=$_.Length; sha256=(Get-FileHash -LiteralPath $_.FullName -Algorithm SHA256).Hash}
})
$TaskManifest = [ordered]@{build_timestamp_utc=(Get-Date).ToUniversalTime().ToString('o'); godot=$Godot; engine_version=(& $Godot --version | Out-String).Trim(); exe_sha256=(Get-FileHash -LiteralPath (Join-Path $TaskBuild 'RooftopRiot.exe')).Hash; pck_sha256=(Get-FileHash -LiteralPath (Join-Path $TaskBuild 'RooftopRiot.pck')).Hash; runtime_source_files=$TaskSourceRecords}
$TaskManifest | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath (Join-Path $TaskBuild 'build_manifest.json')
Copy-Item -LiteralPath (Join-Path $TaskBuild 'build_manifest.json') -Destination (Join-Path $TaskRoot 'evidence/windows_build_manifest.json')
$TaskFiles = Get-ChildItem -LiteralPath $TaskBuild -File | Select-Object Name, Length
$TaskFiles | ConvertTo-Json | Set-Content -LiteralPath (Join-Path $TaskRoot 'evidence/windows_export.json')
Write-Output $TaskFiles
