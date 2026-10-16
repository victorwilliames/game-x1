param(
    [int]$Runs = 3,
    [float]$Sec = 6.0,
    [float]$Warmup = 3.0,
    [string]$Configs = "full,no_fxaa,no_shadows,no_ui",
    [string]$OutFile = "docs/migration/visual/native_perf_bench.json"
)

$ErrorActionPreference = "Stop"

. "$PSScriptRoot/godot_path.ps1"
$Godot = Get-GodotPath

$ResolvedOut = [System.IO.Path]::GetFullPath((Join-Path $PSScriptRoot "..\$OutFile"))
$OutDir = [System.IO.Path]::GetDirectoryName($ResolvedOut)
if (-not (Test-Path $OutDir)) {
    New-Item -ItemType Directory -Path $OutDir -Force | Out-Null
}

Write-Host "[PerfBench] Launching Godot native benchmark..." -ForegroundColor Cyan
Write-Host "  Godot:   $Godot"
Write-Host "  Configs: $Configs"
Write-Host "  Runs:    $Runs"
Write-Host "  Sec/sc:  $Sec"
Write-Host "  Warmup:  $Warmup"
Write-Host "  Output:  $ResolvedOut"

& $Godot --path . -- --bench "--bench-runs=$Runs" "--bench-sec=$Sec" "--bench-warmup=$Warmup" "--bench-configs=$Configs" "--bench-out=$ResolvedOut"
$ExitCode = $LASTEXITCODE

Write-Host "[PerfBench] Finished with exit code $ExitCode"
if (Test-Path $ResolvedOut) {
    Write-Host "[PerfBench] Output written to $ResolvedOut" -ForegroundColor Green
} else {
    Write-Warning "[PerfBench] Output file not found: $ResolvedOut"
}

exit $ExitCode
