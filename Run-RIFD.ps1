# RIFD portable local preview. Windows PowerShell 5.1+; loopback only.
# This is not a production web server and does not synchronize browser data.
$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $MyInvocation.MyCommand.Path
$htmlPath = Join-Path $root 'RIFD.html'
if (!(Test-Path -LiteralPath $htmlPath)) {
  Write-Host 'RIFD.html is missing. Extract the complete ZIP first.'
  exit 1
}
$listener = $null
$port = 0
foreach ($candidate in 8765..8770) {
  $attempt = $null
  try {
    $attempt = [System.Net.Sockets.TcpListener]::new([System.Net.IPAddress]::Loopback, [int]$candidate)
    $attempt.Start()
    $listener = $attempt
    $port = [int]$candidate
    break
  } catch {
    if ($attempt) { try { $attempt.Stop() } catch {} }
  }
}
if (!$listener) {
  Write-Host 'Unable to start local port 8765-8770. Close older RIFD window.'
  exit 1
}
$baseUrl = "http://127.0.0.1:$port/"
Write-Host ('RIFD is ready at ' + $baseUrl)
if ($port -ne 8765) {
  Write-Host 'NOTICE: A different port means separate local browser storage.'
}
Write-Host 'Keep this window open while using RIFD. Ctrl+C to stop.'
try { Start-Process $baseUrl } catch { Write-Host ('Open this URL in Edge/Chrome: ' + $baseUrl) }
try {
  while ($true) {
    $client = $listener.AcceptTcpClient()
    try {
      $client.ReceiveTimeout = 7000
      $client.SendTimeout = 7000
      $stream = $client.GetStream()
      $stream.ReadTimeout = 7000
      $reader = [System.IO.StreamReader]::new($stream, [System.Text.Encoding]::ASCII, $false, 1024, $true)
      $first = $reader.ReadLine()
      if (!$first) { continue }
      while ($true) {
        $line = $reader.ReadLine()
        if ($null -eq $line -or $line -eq '') { break }
      }
      $parts = $first -split ' '
      $method = $parts[0]
      $path = if ($parts.Length -gt 1) { ($parts[1] -split '\?')[0] } else { '/' }
      if (($method -eq 'GET' -or $method -eq 'HEAD') -and
          @('/', '/RIFD.html', '/index.html').Contains($path)) {
        $body = [System.IO.File]::ReadAllBytes($htmlPath)
        $status = '200 OK'
        $mime = 'text/html; charset=utf-8'
      } else {
        $body = [System.Text.Encoding]::UTF8.GetBytes('Not found')
        $status = '404 Not Found'
        $mime = 'text/plain; charset=utf-8'
      }
      $nl = [Environment]::NewLine
      $header = 'HTTP/1.1 ' + $status + $nl +
        'Content-Type: ' + $mime + $nl +
        'Content-Length: ' + $body.Length + $nl +
        'Cache-Control: no-store' + $nl +
        'X-Content-Type-Options: nosniff' + $nl +
        'Connection: close' + $nl + $nl
      $hb = [System.Text.Encoding]::ASCII.GetBytes($header)
      $stream.Write($hb, 0, $hb.Length)
      if ($method -ne 'HEAD') { $stream.Write($body, 0, $body.Length) }
      $stream.Flush()
    } catch {
      Write-Host ('Local request error: ' + $_.Exception.Message)
    } finally {
      if ($client) { $client.Close() }
    }
  }
} finally {
  $listener.Stop()
}
