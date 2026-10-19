# Shared read-only provenance for profiling and packaging. Keep the inventory
# filter identical to export_windows.ps1 and validate_windows_build.ps1.
function Get-ReleaseInventoryHash([object[]]$Records) {
    # Normalize before sorting: Sort-Object does not treat an OrderedDictionary
    # key like a deserialized PSCustomObject property on every PowerShell version.
    $taskNormalized = @($Records | ForEach-Object {
        [pscustomobject][ordered]@{path=([string]$_.path).Replace('\','/');bytes=[long]$_.bytes;sha256=([string]$_.sha256).ToUpperInvariant()}
    } | Sort-Object path)
    $taskBytes = [Text.Encoding]::UTF8.GetBytes((ConvertTo-Json -InputObject $taskNormalized -Depth 4 -Compress))
    $taskHasher = [Security.Cryptography.SHA256]::Create()
    try { return [BitConverter]::ToString($taskHasher.ComputeHash($taskBytes)).Replace('-','') }
    finally { $taskHasher.Dispose() }
}

function Get-ReleaseRuntimeInventory([string]$Project) {
    $taskProjectPath = [IO.Path]::GetFullPath($Project).TrimEnd([char[]]@('\','/'))
    if (-not (Test-Path -LiteralPath (Join-Path $taskProjectPath 'project.godot') -PathType Leaf)) { throw "Missing project: $taskProjectPath" }
    $taskRecords = @(Get-ChildItem -LiteralPath $taskProjectPath -Recurse -File | Where-Object {
        $_.FullName -notmatch '[\\/]\.godot[\\/]' -and $_.Extension -in @('.gd','.gdshader','.godot','.tscn','.tres','.glb','.png','.jpg','.jpeg','.svg','.wav','.ogg','.json','.import','.uid','.cfg') -and $_.Name -notlike 'source_*' -and $_.Name -notin @('validate_input.gd','engine.png')
    } | Sort-Object FullName | ForEach-Object {
        [ordered]@{path=$_.FullName.Substring($taskProjectPath.Length + 1).Replace('\','/');bytes=$_.Length;sha256=(Get-FileHash -LiteralPath $_.FullName -Algorithm SHA256).Hash}
    })
    return [pscustomobject]@{project=$taskProjectPath;sha256=(Get-ReleaseInventoryHash $taskRecords);files=$taskRecords}
}

function Get-ReleaseProjectArt([string]$Project) {
    # A baseline project may predate this report. Record that absence explicitly;
    # never associate it with the current checkout's art report.
    $taskArtPath = Join-Path (Split-Path -Parent ([IO.Path]::GetFullPath($Project).TrimEnd([char[]]@('\','/')))) 'evidence/characters/hero_rebuild/release_assets.json'
    $taskPresent = Test-Path -LiteralPath $taskArtPath -PathType Leaf
    return [pscustomobject]@{path=$taskArtPath;present=$taskPresent;sha256=$(if ($taskPresent) { (Get-FileHash -LiteralPath $taskArtPath -Algorithm SHA256).Hash } else { $null })}
}
