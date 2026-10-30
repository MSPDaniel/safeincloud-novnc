#!/bin/bash
set -Eeuo pipefail
export HOME=/config DISPLAY=:1 WINEPREFIX=/config/safeincloud/wine
mkdir -p "$WINEPREFIX" /config/safeincloud
# Wine prefixes cannot safely be shared by two running containers.
if [[ ! -f "$WINEPREFIX/system.reg" ]]; then
  echo 'Initializing new Wine prefix...'
  wineboot --init
  wineserver -w
fi
# WPF software rendering workaround.
wine reg add 'HKCU\Software\Microsoft\Avalon.Graphics' /v DisableHWAcceleration /t REG_DWORD /d 1 /f || true
# Install .NET 4.8 once. This may take a long time and require network access.
if [[ "${INSTALL_DOTNET48:-1}" == 1 && ! -f /config/safeincloud/.dotnet48-installed ]]; then
  echo 'Installing .NET Framework 4.8 using winetricks (first start)...'
  if winetricks -q dotnet48; then
    touch /config/safeincloud/.dotnet48-installed
  else
    echo 'ERROR: dotnet48 installation failed; inspect /config/safeincloud/app.log' >&2
    exit 1
  fi
fi
# Allow either a single portable EXE or an unpacked app directory.
exe="${SAFEINCLOUD_EXE:-/opt/safeincloud/source/SafeInCloud.exe}"
if [[ ! -f "$exe" ]]; then
  echo "ERROR: SafeInCloud executable not found: $exe" >&2
  echo 'Mount your licensed portable Windows app at /opt/safeincloud/source.' >&2
  while true; do sleep 3600; done
fi
# Configure Wine to launch external URLs through Linux Chromium.
# xdg-open can be used manually; Wine OAuth callbacks may require further integration.
echo "Starting SafeInCloud: $exe"
sleep 5
exec wine "$exe"
