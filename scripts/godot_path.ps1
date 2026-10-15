function Get-GodotPath {
    if ($env:GODOT_BIN -and (Test-Path $env:GODOT_BIN)) {
        return $env:GODOT_BIN
    }

    $cmd = Get-Command "godot" -ErrorAction SilentlyContinue
    if ($cmd) {
        return $cmd.Source
    }

    $wingetDir = "$env:LOCALAPPDATA\Microsoft\WinGet\Packages"
    if (Test-Path $wingetDir) {
        $found = Get-ChildItem -Path $wingetDir -Recurse -Filter "Godot_*_console.exe" -ErrorAction SilentlyContinue | Select-Object -First 1
        if ($found) {
            return $found.FullName
        }
        $foundGui = Get-ChildItem -Path $wingetDir -Recurse -Filter "Godot_*.exe" -ErrorAction SilentlyContinue | Select-Object -First 1
        if ($foundGui) {
            return $foundGui.FullName
        }
    }

    throw "Godot executable not found. Set `$env:GODOT_BIN or install Godot 4 via WinGet."
}
