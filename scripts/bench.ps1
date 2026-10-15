$ErrorActionPreference = "Stop"
. "$PSScriptRoot\godot_path.ps1"

$godot = Get-GodotPath
$projectDir = Resolve-Path "$PSScriptRoot\.."

Write-Host "[game-x1] Running GPU performance benchmark (GL Compatibility)..."
& $godot --path "$projectDir" --script "scripts/test_performance.gd"
