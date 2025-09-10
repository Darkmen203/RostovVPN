New-Item -ItemType Directory -Force -Name "dist\tmp"
New-Item -ItemType Directory -Force -Name "out"

# windows setup (robust name matching)
# Try to find installer exe with flexible pattern across flutter_distributor versions
$exeCandidates = Get-ChildItem -Recurse -File -Path "dist" -Include *.exe -ErrorAction SilentlyContinue

function Pick-Installer([System.IO.FileInfo[]]$cands) {
  # 1) из windows-setup_exe, не CLI
  $exe = $cands |
    Where-Object { $_.FullName -match 'windows-setup_exe' -and $_.Name -notmatch '(?i)cli' } |
    Sort-Object Length -Descending | Select-Object -First 1
  if ($exe) { return $exe }

  # 2) любые setup/install/installer, не CLI
  $exe = $cands |
    Where-Object { $_.Name -match '(?i)(setup|install|installer).*\.exe$' -and $_.Name -notmatch '(?i)cli' } |
    Sort-Object Length -Descending | Select-Object -First 1
  if ($exe) { return $exe }

  # 3) иначе — просто самый большой exe
  return ($cands | Sort-Object Length -Descending | Select-Object -First 1)
}

if ($exeCandidates) {
  $installer = Pick-Installer $exeCandidates

  if ($installer -and $installer.Length -ge 30MB) {
    Write-Host "Found Windows installer:" $installer.FullName
    Copy-Item $installer.FullName -Destination "out\RostovVPN-Windows-Setup-x64.exe" -Force
  } else {
    Write-Warning "Installer missing or too small (<30MB). Check the previous step that builds/fallbacks the installer."
  }
} else {
  Write-Host "No .exe installer found under dist/"
}

$msix = Get-ChildItem -Recurse -File -Path "dist" -Include *.msix -ErrorAction SilentlyContinue | Select-Object -First 1
if ($msix) {
  Write-Host "Found MSIX:" $msix.FullName
  Copy-Item $msix.FullName -Destination "out\RostovVPN-Windows-Setup-x64.msix" -Force -ErrorAction SilentlyContinue
} else {
  Write-Host "No .msix found under dist/"
}


# windows portable
xcopy "build\windows\x64\runner\Release" "dist\tmp\rostovvpn-next" /E/H/C/I/Y
xcopy ".github\help\mac-windows\*.url" "dist\tmp\rostovvpn-next" /E/H/C/I/Y
Compress-Archive -Force -Path "dist\tmp\rostovvpn-next" -DestinationPath "out\RostovVPN-Windows-Portable-x64.zip" -ErrorAction SilentlyContinue

Remove-Item -Path "$HOME\.pub-cache\git\cache\flutter_circle_flags*" -Force -Recurse -ErrorAction SilentlyContinue

echo "Done"
