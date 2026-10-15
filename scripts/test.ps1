$ErrorActionPreference = "Stop"
. "$PSScriptRoot\godot_path.ps1"

$godot = Get-GodotPath
$projectDir = Resolve-Path "$PSScriptRoot\.."

Write-Host "[game-x1] Running headless smoke check with Godot: $godot"
& $godot --headless --path "$projectDir" --quit-after 60

if ($LASTEXITCODE -ne 0) {
    Write-Error "[game-x1] Headless smoke check failed with exit code $LASTEXITCODE"
    exit $LASTEXITCODE
}

Write-Host "[game-x1] Headless smoke check passed successfully!"
