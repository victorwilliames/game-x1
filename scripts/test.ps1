$ErrorActionPreference = "Stop"
. "$PSScriptRoot\godot_path.ps1"

$godot = Get-GodotPath
$projectDir = Resolve-Path "$PSScriptRoot\.."

Write-Host "[game-x1] 1/2: Running headless editor import & parse check..."
& $godot --headless --editor --quit --path "$projectDir"

if ($LASTEXITCODE -ne 0) {
    Write-Error "[game-x1] Headless editor import & parse failed with exit code $LASTEXITCODE"
    exit $LASTEXITCODE
}

Write-Host "[game-x1] 2/2: Running headless runtime smoke check (60 frames)..."
& $godot --headless --path "$projectDir" --quit-after 60

if ($LASTEXITCODE -ne 0) {
    Write-Error "[game-x1] Headless runtime smoke check failed with exit code $LASTEXITCODE"
    exit $LASTEXITCODE
}

Write-Host "[game-x1] All headless checks passed successfully!"
