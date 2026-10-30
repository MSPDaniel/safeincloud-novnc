#!/bin/bash
set -Eeuo pipefail
export HOME=/config USER=appuser LOGNAME=appuser DISPLAY=:1
export WINEPREFIX=/config/safeincloud/wine
export XDG_CONFIG_HOME=/config/.config XDG_CACHE_HOME=/config/.cache
mkdir -p /config/.vnc /config/safeincloud /config/.cache /config/.config
width="${DISPLAY_WIDTH:-1440}"; height="${DISPLAY_HEIGHT:-900}"
[[ "$width" =~ ^[0-9]+$ && "$height" =~ ^[0-9]+$ ]] || { echo 'Invalid display size' >&2; exit 1; }
# VNC is bound to loopback; only noVNC's web port is exposed.
Xvnc :1 -geometry "${width}x${height}" -depth 24 -SecurityTypes None -localhost -rfbport 5901 > /config/safeincloud/xvnc.log 2>&1 &
vnc_pid=$!
cleanup() { kill "$vnc_pid" "${web_pid:-}" "${app_pid:-}" 2>/dev/null || true; }
trap cleanup EXIT INT TERM
for n in $(seq 1 30); do [[ -S /tmp/.X11-unix/X1 ]] && break; sleep 1; done
[[ -S /tmp/.X11-unix/X1 ]] || { cat /config/safeincloud/xvnc.log; exit 1; }
openbox-session > /config/safeincloud/openbox.log 2>&1 &
websockify --web /usr/share/novnc 0.0.0.0:5800 127.0.0.1:5901 > /config/safeincloud/novnc.log 2>&1 &
web_pid=$!
/opt/safeincloud/scripts/run.sh > /config/safeincloud/app.log 2>&1 &
app_pid=$!
wait -n "$vnc_pid" "$web_pid" "$app_pid"
