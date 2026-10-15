$ErrorActionPreference = "Stop"
. "$PSScriptRoot\godot_path.ps1"

$godot = Get-GodotPath
$projectDir = Resolve-Path "$PSScriptRoot\.."

Write-Host "[game-x1] Running project with Godot binary: $godot"
& $godot --path "$projectDir" $args
