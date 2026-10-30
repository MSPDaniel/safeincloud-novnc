#!/bin/bash
set -Eeuo pipefail
export HOME=/config DISPLAY=:1 WINEPREFIX=/config/safeincloud/wine
export PATH=/opt/safeincloud/scripts:$PATH
mkdir -p "$WINEPREFIX" /config/safeincloud
if [[ ! -s "$WINEPREFIX/system.reg" ]]; then
  echo 'Initializing Wine prefix (no build-time template found)...'
  wineboot --init; wineserver -w
fi
wine reg add 'HKCU\Software\Microsoft\Avalon.Graphics' /v DisableHWAcceleration /t REG_DWORD /d 1 /f || true
# The Wine prefix is persistent. Never silently reinstall .NET on each restart.
if [[ "${INSTALL_DOTNET48:-0}" == 1 && ! -f /config/safeincloud/.dotnet48-installed ]]; then
  echo 'Installing .NET 4.8 into existing prefix (explicitly requested)...'
  winetricks -q dotnet48 && touch /config/safeincloud/.dotnet48-installed
fi
# Configure Wine's native URL opener: winebrowser -> Linux xdg-open -> Chromium.
wine reg add 'HKCU\Software\Wine\WineBrowser' /v Browsers /t REG_SZ /d safeincloud-browser /f || true
exe="${SAFEINCLOUD_EXE:-/config/safeincloud/app/SafeInCloud.exe}"
if [[ ! -f "$exe" && -f /opt/safeincloud/source/SafeInCloud.exe ]]; then
  # Portable application stores Data beside its EXE; source is read-only.
  mkdir -p /config/safeincloud/app
  cp -an /opt/safeincloud/source/. /config/safeincloud/app/
fi
if [[ ! -f "$exe" ]]; then
  echo 'No SafeInCloud.exe found. Put the official portable Windows files in the Unraid source directory.'
  xterm -title 'SafeInCloud setup' -e sh -c 'echo "SafeInCloud.exe missing. See README."; read x' || true
  exit 0
fi
printf 'Launching %s\n' "$exe"
wine "$exe"
