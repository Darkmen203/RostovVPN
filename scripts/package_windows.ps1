New-Item -ItemType Directory -Force -Name "dist\tmp"
New-Item -ItemType Directory -Force -Name "out"

# windows setup
# Get-ChildItem -Recurse -File -Path "dist" -Filter "*windows-setup.exe" | Copy-Item -Destination "dist\tmp\rostovVPN-next-setup.exe" -ErrorAction SilentlyContinue
# Compress-Archive -Force -Path "dist\tmp\rostovVPN-next-setup.exe",".github\help\mac-windows\*.url" -DestinationPath "out\rostovVPN-windows-x64-setup.zip"
Get-ChildItem -Recurse -File -Path "dist" -Filter "*windows-setup.exe" | Copy-Item -Destination "out\RostovVPN-Windows-Setup-x64.exe" -ErrorAction SilentlyContinue
Get-ChildItem -Recurse -File -Path "dist" -Filter "*windows.msix" | Copy-Item -Destination "out\RostovVPN-Windows-Setup-x64.msix" -ErrorAction SilentlyContinue


# windows portable
xcopy "build\windows\x64\runner\Release" "dist\tmp\rostovvpn-next" /E/H/C/I/Y
xcopy ".github\help\mac-windows\*.url" "dist\tmp\rostovvpn-next" /E/H/C/I/Y
Compress-Archive -Force -Path "dist\tmp\rostovvpn-next" -DestinationPath "out\RostovVPN-Windows-Portable-x64.zip" -ErrorAction SilentlyContinue

Remove-Item -Path "$HOME\.pub-cache\git\cache\flutter_circle_flags*" -Force -Recurse -ErrorAction SilentlyContinue

echo "Done"