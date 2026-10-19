$ErrorActionPreference = 'Stop'
$taskRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$taskGodot = 'D:\Game Engines\Godot\Godot_v4.7.2-stable_win64_console.exe'
$taskProject = Join-Path $taskRoot 'Game File'
. (Join-Path $taskRoot 'tools/validation/release_provenance.ps1')
$taskBefore = Get-ReleaseRuntimeInventory $taskProject
$taskGate = Get-Content -LiteralPath (Join-Path $taskRoot 'evidence/validation_all.json') -Raw | ConvertFrom-Json
if (-not $taskGate.passed -or $taskBefore.sha256 -ne $taskGate.runtime.sha256) { throw 'Current source gate does not match the runtime' }
$taskGpuOutput = (& nvidia-smi --query-gpu=name,driver_version,temperature.gpu,memory.used --format=csv,noheader,nounits 2>&1 | Out-String).Trim()
if ($LASTEXITCODE -ne 0) { throw "GPU is unavailable: $taskGpuOutput" }
[ordered]@{checked_utc=[DateTime]::UtcNow.ToString('o');passed=$true;diagnostic=$taskGpuOutput;last_boot=(Get-CimInstance Win32_OperatingSystem).LastBootUpTime.ToUniversalTime().ToString('o')} | ConvertTo-Json | Set-Content -LiteralPath (Join-Path $PSScriptRoot 'gpu_recovered.json')
$taskFailures = Join-Path $PSScriptRoot 'failures/pre_reboot'
New-Item -ItemType Directory -Path $taskFailures -Force | Out-Null
foreach ($taskLog in @('review_final_engine.log','review_final_stdout.log')) {
    $taskOldLog = Join-Path $PSScriptRoot $taskLog
    $taskPreserved = Join-Path $taskFailures $taskLog
    if ((Test-Path -LiteralPath $taskOldLog) -and -not (Test-Path -LiteralPath $taskPreserved)) { Copy-Item -LiteralPath $taskOldLog -Destination $taskPreserved }
}
$taskCases = @(
    @{name='review_final';harness='rebuild_stage_review.gd';folder='review_final';report='stage_review.json'},
    @{name='review_motion';harness='living_background_review.gd';folder='review_motion';report='living_background_review.json'}
)
foreach ($taskCase in $taskCases) {
    $taskEngineLog = Join-Path $PSScriptRoot ($taskCase.name + '_engine.log')
    $taskNativeLog = Join-Path $PSScriptRoot ($taskCase.name + '_stdout.log')
    $taskOutput = Join-Path $PSScriptRoot $taskCase.folder
    $taskInfo = [Diagnostics.ProcessStartInfo]::new()
    $taskInfo.FileName = $taskGodot
    $taskInfo.WorkingDirectory = $taskRoot
    $taskInfo.UseShellExecute = $false
    $taskInfo.CreateNoWindow = $true
    $taskInfo.RedirectStandardOutput = $true
    $taskInfo.RedirectStandardError = $true
    foreach ($taskArgument in @('--path',$taskProject,'--script',(Join-Path $taskRoot ('tools/validation/' + $taskCase.harness)),'--log-file',$taskEngineLog,'--',("--output=" + $taskOutput))) { $taskInfo.ArgumentList.Add($taskArgument) }
    $taskProcess = [Diagnostics.Process]::new()
    $taskProcess.StartInfo = $taskInfo
    $taskStarted = [DateTime]::UtcNow
    try {
        if (-not $taskProcess.Start()) { throw 'Capture process did not start' }
        $taskStdout = $taskProcess.StandardOutput.ReadToEndAsync()
        $taskStderr = $taskProcess.StandardError.ReadToEndAsync()
        if (-not $taskProcess.WaitForExit(180000)) { $taskProcess.Kill($true); $null = $taskProcess.WaitForExit(5000); throw 'Capture process timed out' }
        $taskDrain = [Threading.Tasks.Task]::WhenAll([Threading.Tasks.Task[]]@($taskStdout,$taskStderr))
        if (-not $taskDrain.Wait(5000)) { throw 'Capture output pipes did not close' }
        $taskText = $taskStdout.GetAwaiter().GetResult() + "`nSTDERR:`n" + $taskStderr.GetAwaiter().GetResult()
        [IO.File]::WriteAllText($taskNativeLog,$taskText,[Text.UTF8Encoding]::new($false))
        if ($taskProcess.ExitCode -ne 0) { throw "Capture exited with code $($taskProcess.ExitCode)" }
        if ($taskText -match '(?im)\b(?:SCRIPT ERROR|Parse Error|ERROR)\s*:|^\s*WARNING\s*:|VK_ERROR_DEVICE_LOST|GPU is lost') { throw 'Capture logged an engine problem' }
        $taskReportPath = Join-Path $taskOutput $taskCase.report
        if ((Get-Item -LiteralPath $taskReportPath).LastWriteTimeUtc -lt $taskStarted) { throw 'Capture report was not fresh' }
        $taskReport = Get-Content -LiteralPath $taskReportPath -Raw | ConvertFrom-Json
        if ($taskCase.name -eq 'review_final') {
            if ($taskReport.captures.Count -ne 25 -or @($taskReport.captures | Where-Object { -not $_.saved }).Count) { throw 'Incomplete standard views' }
        } else {
            if (-not $taskReport.passed -or $taskReport.failures -ne 0 -or $taskReport.captures.Count -ne 70) { throw 'Incomplete scenery regression' }
        }
        Write-Output "$($taskCase.name): capture complete, $($taskReport.captures.Count) images"
    } finally {
        if (-not $taskProcess.HasExited) { $taskProcess.Kill($true); $null = $taskProcess.WaitForExit(5000) }
        if ($taskStdout -and $taskStdout.IsCompletedSuccessfully -and -not (Test-Path -LiteralPath $taskNativeLog)) {
            [IO.File]::WriteAllText($taskNativeLog,$taskStdout.GetAwaiter().GetResult(),[Text.UTF8Encoding]::new($false))
        }
        $taskProcess.Dispose()
    }
}
$taskAfter = Get-ReleaseRuntimeInventory $taskProject
if ($taskAfter.sha256 -ne $taskBefore.sha256) { throw 'Runtime changed during captures' }
[ordered]@{passed=$true;finished_utc=[DateTime]::UtcNow.ToString('o');runtime=$taskAfter;unchanged_during_capture=$true;visual_review='pending assistant image inspection'} | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath (Join-Path $PSScriptRoot 'capture_provenance.json')
