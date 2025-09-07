New-Item -ItemType Directory -Force -Name "dist\tmp"
New-Item -ItemType Directory -Force -Name "out"

# windows setup (robust name matching)
# Try to find installer exe with flexible pattern across flutter_distributor versions
$exeCandidates = Get-ChildItem -Recurse -File -Path "dist" -Include *.exe -ErrorAction SilentlyContinue
if ($exeCandidates) {
  $preferred = $exeCandidates | Where-Object { $_.Name -match '(?i)(setup|install|windows).*x64.*\.exe$' }
  if (-not $preferred) { $preferred = $exeCandidates }
  $exe = $preferred | Select-Object -First 1
  Write-Host "Found Windows installer:" $exe.FullName
  Copy-Item $exe.FullName -Destination "out\RostovVPN-Windows-Setup-x64.exe" -Force -ErrorAction SilentlyContinue
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
