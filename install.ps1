#Requires -Version 5.1
$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

$Repo       = 'qontext-ai/cli'
$BinName    = 'qontext'
$Version    = if ($env:QONTEXT_VERSION)     { $env:QONTEXT_VERSION }     else { 'latest' }
$InstallDir = if ($env:QONTEXT_INSTALL_DIR) { $env:QONTEXT_INSTALL_DIR } else { Join-Path $env:LOCALAPPDATA "Programs\qontext" }

switch ($env:PROCESSOR_ARCHITECTURE) {
  'AMD64' { $Arch = 'amd64' }
  'ARM64' { $Arch = 'arm64' }
  default { throw "Unsupported architecture: $($env:PROCESSOR_ARCHITECTURE)" }
}

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

if ($Version -eq 'latest') {
  $Version = (Invoke-WebRequest -UseBasicParsing -Uri "https://raw.githubusercontent.com/$Repo/main/VERSION").Content.Trim()
  if (-not $Version) { throw "Failed to resolve current version from $Repo/VERSION" }
}
$Archive   = "${BinName}_${Version}_windows_${Arch}.zip"
$Checksums = "SHA256SUMS-${Version}.txt"
$BaseUrl   = "https://github.com/$Repo/releases/download/$Version"

$Tmp = New-Item -ItemType Directory -Path (Join-Path $env:TEMP "qontext-install-$([guid]::NewGuid())")
try {
  $archivePath   = Join-Path $Tmp $Archive
  $checksumsPath = Join-Path $Tmp $Checksums

  Write-Host "Downloading $Archive..."
  Invoke-WebRequest -UseBasicParsing -Uri "$BaseUrl/$Archive"   -OutFile $archivePath
  Invoke-WebRequest -UseBasicParsing -Uri "$BaseUrl/$Checksums" -OutFile $checksumsPath

  Write-Host "Verifying checksum..."
  $expected = (Get-Content $checksumsPath |
    Where-Object { $_ -match "\s$([regex]::Escape($Archive))\s*$" } |
    ForEach-Object { ($_ -split '\s+')[0] } |
    Select-Object -First 1)
  if (-not $expected) { throw "Checksum for $Archive not found in $Checksums" }

  $actual = (Get-FileHash -Algorithm SHA256 -Path $archivePath).Hash.ToLower()
  if ($actual -ne $expected.ToLower()) {
    throw "Checksum mismatch for ${Archive}:`n  expected: $expected`n  actual:   $actual"
  }

  Expand-Archive -Path $archivePath -DestinationPath $Tmp -Force
  $binSrc = Join-Path $Tmp "$BinName.exe"
  if (-not (Test-Path $binSrc)) { throw "Archive did not contain expected binary '$BinName.exe'" }

  if (-not (Test-Path $InstallDir)) {
    New-Item -ItemType Directory -Path $InstallDir | Out-Null
  }
  $binDest = Join-Path $InstallDir "$BinName.exe"
  Write-Host "Installing to $binDest..."
  Copy-Item -Path $binSrc -Destination $binDest -Force

  $userPath = [Environment]::GetEnvironmentVariable('Path', 'User')
  $pathParts = if ($userPath) { $userPath -split ';' } else { @() }
  if (-not ($pathParts | Where-Object { $_ -ieq $InstallDir })) {
    Write-Host "Adding $InstallDir to user PATH..."
    $newPath = if ($userPath) { "$userPath;$InstallDir" } else { $InstallDir }
    [Environment]::SetEnvironmentVariable('Path', $newPath, 'User')
    Write-Host "Open a new terminal for the PATH update to take effect."
  }

  Write-Host "Installed $BinName $Version to $binDest"
}
finally {
  Remove-Item -Recurse -Force -Path $Tmp -ErrorAction SilentlyContinue
}
