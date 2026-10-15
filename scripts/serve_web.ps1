param(
    [int]$Port = 8080,
    [switch]$OpenBrowser
)

$ErrorActionPreference = "Stop"
$projectDir = Resolve-Path "$PSScriptRoot\.."
$webDir = Join-Path $projectDir "build\web"

if (-not (Test-Path "$webDir\index.html")) {
    Write-Warning "[game-x1] build\web\index.html not found. Running export_web.ps1 first..."
    & "$PSScriptRoot\export_web.ps1"
}

# Canonical root directory path with trailing separator for traversal check
$canonicalWebDir = [System.IO.Path]::GetFullPath($webDir)
if (-not $canonicalWebDir.EndsWith([System.IO.Path]::DirectorySeparatorChar.ToString())) {
    $canonicalWebDir += [System.IO.Path]::DirectorySeparatorChar
}

$url = "http://localhost:$Port/"
$listener = New-Object System.Net.HttpListener
$listener.Prefixes.Add($url)

try {
    $listener.Start()
} catch {
    Write-Error "Could not start server on $url. Is the port in use? $_"
    exit 1
}

Write-Host "===================================================="
Write-Host "  game-x1 Web Server running at: $url"
Write-Host "  Serving: $canonicalWebDir"
Write-Host "  Press Ctrl+C in terminal to stop server."
Write-Host "===================================================="

if ($OpenBrowser) {
    Start-Process $url
}

$mimeTypes = @{
    ".html" = "text/html; charset=utf-8"
    ".js"   = "application/javascript"
    ".wasm" = "application/wasm"
    ".pck"  = "application/octet-stream"
    ".png"  = "image/png"
    ".svg"  = "image/svg+xml"
    ".ico"  = "image/x-icon"
    ".json" = "application/json"
    ".css"  = "text/css"
}

try {
    while ($listener.IsListening) {
        $context = $listener.GetContext()
        $request = $context.Request
        $response = $context.Response

        $rawRelative = $request.Url.LocalPath.TrimStart('/')
        if ([string]::IsNullOrEmpty($rawRelative) -or $rawRelative -eq "") {
            $rawRelative = "index.html"
        }

        # URL-decode to catch encoded traversal attempts (%2e%2e)
        $decodedPath = [System.Uri]::UnescapeDataString($rawRelative)

        # Normalize directory separators
        $normalizedPath = $decodedPath.Replace('/', [System.IO.Path]::DirectorySeparatorChar)

        # Security/headers for WebAssembly & Godot
        $response.AddHeader("Cross-Origin-Opener-Policy", "same-origin")
        $response.AddHeader("Cross-Origin-Embedder-Policy", "require-corp")
        $response.AddHeader("Cache-Control", "no-cache, no-store, must-revalidate")
        $response.AddHeader("Pragma", "no-cache")
        $response.AddHeader("Expires", "0")

        try {
            # Reject direct traversal patterns before resolving
            if ($decodedPath -match '(\.\.[\\/])|([\\/]\.\.)|(\.\.$)') {
                $response.StatusCode = 403
                $msg = [System.Text.Encoding]::UTF8.GetBytes("403 - Forbidden")
                $response.ContentLength64 = $msg.Length
                if ($request.HttpMethod -ne "HEAD") {
                    $response.OutputStream.Write($msg, 0, $msg.Length)
                }
                continue
            }

            # Canonical path resolution & containment check
            $combinedPath = [System.IO.Path]::Combine($canonicalWebDir, $normalizedPath)
            $canonicalFilePath = [System.IO.Path]::GetFullPath($combinedPath)

            if (-not $canonicalFilePath.StartsWith($canonicalWebDir, [System.StringComparison]::OrdinalIgnoreCase)) {
                $response.StatusCode = 403
                $msg = [System.Text.Encoding]::UTF8.GetBytes("403 - Forbidden")
                $response.ContentLength64 = $msg.Length
                if ($request.HttpMethod -ne "HEAD") {
                    $response.OutputStream.Write($msg, 0, $msg.Length)
                }
                continue
            }

            if (Test-Path $canonicalFilePath -PathType Leaf) {
                $ext = [System.IO.Path]::GetExtension($canonicalFilePath).ToLower()
                $mime = "application/octet-stream"
                if ($mimeTypes.ContainsKey($ext)) {
                    $mime = $mimeTypes[$ext]
                }
                $response.ContentType = $mime

                $bytes = [System.IO.File]::ReadAllBytes($canonicalFilePath)
                $response.ContentLength64 = $bytes.Length
                $response.StatusCode = 200

                if ($request.HttpMethod -ne "HEAD") {
                    $response.OutputStream.Write($bytes, 0, $bytes.Length)
                }
            } else {
                $response.StatusCode = 404
                $msg = [System.Text.Encoding]::UTF8.GetBytes("404 - Not Found")
                $response.ContentLength64 = $msg.Length
                if ($request.HttpMethod -ne "HEAD") {
                    $response.OutputStream.Write($msg, 0, $msg.Length)
                }
            }
        } catch {
            Write-Warning "Error processing request for $($decodedPath): $_"
        } finally {
            $response.OutputStream.Close()
        }
    }
} finally {
    $listener.Stop()
    $listener.Close()
}
