#!/bin/bash
set -Eeuo pipefail
export HOME=/config USER=appuser LOGNAME=appuser DISPLAY=:1
export WINEPREFIX=/config/safeincloud/wine
export XDG_CONFIG_HOME=/config/.config XDG_CACHE_HOME=/config/.cache
mkdir -p /config/safeincloud /config/.cache /config/.config
width="${DISPLAY_WIDTH:-1440}"; height="${DISPLAY_HEIGHT:-900}"
[[ "$width" =~ ^[0-9]+$ && "$height" =~ ^[0-9]+$ ]] || exit 1
# Only remove a stale lock if no X server owns it. A PID in a lock may be recycled;
# refuse to interfere with a live X server rather than killing it.
if [[ -e /tmp/.X1-lock || -S /tmp/.X11-unix/X1 ]]; then
  if pgrep -f '^(Xvnc|Xtigervnc) :1([[:space:]]|$)' >/dev/null 2>&1; then
    echo 'ERROR: an X server already owns display :1' >&2; exit 1
  fi
  rm -f /tmp/.X1-lock /tmp/.X11-unix/X1
fi
mkdir -p /tmp/.X11-unix
Xvnc :1 -geometry "${width}x${height}" -depth 24 -SecurityTypes None -localhost -rfbport 5901 > /config/safeincloud/xvnc.log 2>&1 &
vnc_pid=$!
cleanup() { trap - EXIT INT TERM; kill "${app_pid:-}" "${web_pid:-}" "${openbox_pid:-}" "$vnc_pid" 2>/dev/null || true; wait 2>/dev/null || true; }
trap cleanup EXIT INT TERM
for n in $(seq 1 30); do
  [[ -S /tmp/.X11-unix/X1 ]] && break
  if ! kill -0 "$vnc_pid" 2>/dev/null; then cat /config/safeincloud/xvnc.log; exit 1; fi
  sleep 1
done
[[ -S /tmp/.X11-unix/X1 ]] || { cat /config/safeincloud/xvnc.log; exit 1; }
openbox-session > /config/safeincloud/openbox.log 2>&1 & openbox_pid=$!
websockify --web /usr/share/novnc 0.0.0.0:5800 127.0.0.1:5901 > /config/safeincloud/novnc.log 2>&1 & web_pid=$!
# Application failure is logged but never takes down the VNC desktop.
( /opt/safeincloud/scripts/run.sh >> /config/safeincloud/app.log 2>&1 || echo "SafeInCloud exited with an error; desktop remains available" ) & app_pid=$!
wait "$vnc_pid"
