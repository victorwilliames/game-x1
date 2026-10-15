$ErrorActionPreference = "Stop"
. "$PSScriptRoot\godot_path.ps1"

$godot = Get-GodotPath
$projectDir = Resolve-Path "$PSScriptRoot\.."
$outDir = Join-Path $projectDir "build\web"

if (-not (Test-Path $outDir)) {
    New-Item -ItemType Directory -Force -Path $outDir | Out-Null
}

$gdignore = Join-Path $projectDir "build\.gdignore"
if (-not (Test-Path $gdignore)) {
    "# Godot ignore marker" | Out-File -FilePath $gdignore -Encoding utf8
}

$targetHtml = Join-Path $outDir "index.html"

Write-Host "[game-x1] Exporting Web build to $targetHtml..."
& $godot --headless --path "$projectDir" --export-release "Web" "$targetHtml"

if ($LASTEXITCODE -ne 0) {
    Write-Error "[game-x1] Web export failed with exit code $LASTEXITCODE"
    exit $LASTEXITCODE
}

Write-Host "[game-x1] Web export succeeded!"
Get-ChildItem $outDir
