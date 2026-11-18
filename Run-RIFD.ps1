# RIFD local demonstration server for Windows PowerShell 5.1 or later.
# Serves the demo only on loopback. Not intended for deployment to a network.
$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $MyInvocation.MyCommand.Path
$html = Join-Path $root 'RIFD.html'
if (-not (Test-Path -LiteralPath $html)) {
  Write-Host 'RIFD.html was not found. Extract all repository files first.'
  exit 1
}
$listener = $null
$port = 0
foreach ($candidate in 8765..8770) {
  $tryListener = New-Object System.Net.HttpListener
  $tryListener.Prefixes.Add("http://127.0.0.1:$candidate/")
  try {
    $tryListener.Start()
    $listener = $tryListener
    $port = $candidate
    break
  } catch { $tryListener.Close() }
}
if (-not $listener) {
  Write-Host 'Unable to listen on ports 8765 to 8770. Close any prior RIFD window.'
  exit 1
}
$url = "http://127.0.0.1:$port/"
Write-Host ('RIFD local demo: ' + $url)
if ($port -ne 8765) { Write-Host 'Different port: local browser data may appear separate.' }
Write-Host 'Keep this window running. Ctrl+C to stop the local server.'
try { Start-Process $url } catch { Write-Host ('Open ' + $url + ' in Chrome/Edge.') }
try {
  while ($listener.IsListening) {
    $context = $listener.GetContext()
    try {
      $req = $context.Request
      $res = $context.Response
      if (($req.HttpMethod -eq 'GET' -or $req.HttpMethod -eq 'HEAD') -and
        @('/', '/RIFD.html', '/index.html').Contains($req.Url.AbsolutePath)) {
        $data = [System.IO.File]::ReadAllBytes($html)
        $res.StatusCode = 200
        $res.ContentType = 'text/html; charset=utf-8'
      } else {
        $data = [System.Text.Encoding]::UTF8.GetBytes('Not Found')
        $res.StatusCode = 404
        $res.ContentType = 'text/plain; charset=utf-8'
      }
      $res.Headers.Add('Cache-Control', 'no-store')
      $res.ContentLength64 = $data.Length
      if ($req.HttpMethod -ne 'HEAD') { $res.OutputStream.Write($data, 0, $data.Length) }
    } catch {
      Write-Host ('Request failed: ' + $_.Exception.Message)
    } finally {
      try { $context.Response.OutputStream.Close() } catch {}
    }
  }
} finally {
  $listener.Stop()
  $listener.Close()
}
