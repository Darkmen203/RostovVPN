# New-Item -ItemType Directory -Force -Name "dist\tmp"
# New-Item -ItemType Directory -Force -Name "out"

# # windows setup
# # Get-ChildItem -Recurse -File -Path "dist" -Filter "*windows-setup.exe" | Copy-Item -Destination "dist\tmp\rostovVPN-next-setup.exe" -ErrorAction SilentlyContinue
# # Compress-Archive -Force -Path "dist\tmp\rostovVPN-next-setup.exe",".github\help\mac-windows\*.url" -DestinationPath "out\rostovVPN-windows-x64-setup.zip"
# Get-ChildItem -Recurse -File -Path "dist" -Filter "*windows-setup.exe" | Copy-Item -Destination "out\RostovVPN-Windows-Setup-x64.exe" -ErrorAction SilentlyContinue
# Get-ChildItem -Recurse -File -Path "dist" -Filter "*windows.msix" | Copy-Item -Destination "out\RostovVPN-Windows-Setup-x64.msix" -ErrorAction SilentlyContinue


# # windows portable
# xcopy "build\windows\x64\runner\Release" "dist\tmp\rostovvpn-next" /E/H/C/I/Y
# xcopy ".github\help\mac-windows\*.url" "dist\tmp\rostovvpn-next" /E/H/C/I/Y
# Compress-Archive -Force -Path "dist\tmp\rostovvpn-next" -DestinationPath "out\RostovVPN-Windows-Portable-x64.zip" -ErrorAction SilentlyContinue

# Remove-Item -Path "$HOME\.pub-cache\git\cache\flutter_circle_flags*" -Force -Recurse -ErrorAction SilentlyContinue

# echo "Done"
$ErrorActionPreference = "Continue"

# Подготовка каталогов
New-Item -ItemType Directory -Force -Name "dist\tmp" | Out-Null
New-Item -ItemType Directory -Force -Name "out"      | Out-Null

Write-Host "=== Working dir  : $((Get-Location).Path)"
if (Test-Path "dist") {
  $distAbs = (Resolve-Path "dist").ProviderPath
  Write-Host "=== DIST resolved: $distAbs"
  Write-Host "=== DIST tree (cmd tree /F):"
  try { cmd /c "tree `"$distAbs`" /F" } catch { Write-Warning "tree failed: $_" }

  Write-Host "=== DIST files (top 100 by size):"
  Get-ChildItem -Path $distAbs -Recurse -File |
    Sort-Object Length -Descending |
    Select-Object -First 100 @{N='SizeMB';E={[math]::Round($_.Length/1MB,2)}}, FullName |
    Format-Table -AutoSize | Out-Host

  Write-Host "=== DIST *.exe (by size):"
  Get-ChildItem -Path $distAbs -Recurse -File -Filter *.exe |
    Sort-Object Length -Descending |
    Select-Object @{N='SizeMB';E={[math]::Round($_.Length/1MB,2)}}, Name, DirectoryName |
    Format-Table -AutoSize | Out-Host
} else {
  Write-Warning "dist/ not found"
}

# --- Windows setup: ИЩЕМ и ЯВНО КОПИРУЕМ кандидат ---
$setupCandidates = Get-ChildItem -Recurse -File -Path "dist" -Filter "*windows-setup.exe" -ErrorAction SilentlyContinue
if ($setupCandidates) {
  $setupExe = $setupCandidates | Sort-Object Length -Descending | Select-Object -First 1
  Copy-Item $setupExe.FullName -Destination "out\RostovVPN-Windows-Setup-x64.exe" -Force
  Write-Host ("Copied setup EXE: {0}  ({1} MB)" -f $setupExe.FullName, [math]::Round($setupExe.Length/1MB,1))
} else {
  Write-Warning "No '*windows-setup.exe' found under dist/"
  # Показать все exe, чтобы понять, что вообще есть
  Get-ChildItem -Recurse -File -Path "dist" -Filter *.exe -ErrorAction SilentlyContinue |
    Select-Object Name, DirectoryName, @{N='SizeMB';E={[math]::Round($_.Length/1MB,2)}} |
    Format-Table -AutoSize | Out-Host
}

# --- Windows MSIX (если собирается) ---
$msixCandidates = Get-ChildItem -Recurse -File -Path "dist" -Filter "*windows.msix" -ErrorAction SilentlyContinue
if ($msixCandidates) {
  $msix = $msixCandidates | Sort-Object Length -Descending | Select-Object -First 1
  Copy-Item $msix.FullName -Destination "out\RostovVPN-Windows-Setup-x64.msix" -Force
  Write-Host ("Copied MSIX: {0}  ({1} MB)" -f $msix.FullName, [math]::Round($msix.Length/1MB,1))
} else {
  Write-Host "No '*.msix' found under dist/ (ok if не собираешь msix)"
}

# --- Лог Release перед портативной сборкой ---
if (Test-Path "build\windows\x64\runner\Release") {
  $relAbs = (Resolve-Path "build\windows\x64\runner\Release").ProviderPath
  Write-Host "=== RELEASE dir: $relAbs"
  Get-ChildItem -Path $relAbs -Recurse -File |
    Sort-Object Length -Descending |
    Select-Object -First 50 @{N='SizeMB';E={[math]::Round($_.Length/1MB,2)}}, Name, DirectoryName |
    Format-Table -AutoSize | Out-Host
} else {
  Write-Warning "Release dir not found: build\windows\x64\runner\Release"
}

# --- Windows portable ZIP ---
xcopy "build\windows\x64\runner\Release" "dist\tmp\rostovvpn-next" /E/H/C/I/Y
xcopy ".github\help\mac-windows\*.url"     "dist\tmp\rostovvpn-next" /E/H/C/I/Y
Compress-Archive -Force -Path "dist\tmp\rostovvpn-next" -DestinationPath "out\RostovVPN-Windows-Portable-x64.zip" -ErrorAction SilentlyContinue

# Чистим кэш circle_flags (без шума в логах)
Remove-Item -Path "$HOME\.pub-cache\git\cache\flutter_circle_flags*" -Force -Recurse -ErrorAction SilentlyContinue

Write-Host "Done"
