#!/bin/bash
# Used by xdg-open and by Wine's winebrowser. Never pass untrusted flags as root.
export HOME=/config DISPLAY=:1 XDG_CONFIG_HOME=/config/.config
exec /usr/bin/chromium --no-first-run --disable-dev-shm-usage \
  --password-store=basic --user-data-dir=/config/.config/chromium-safeincloud "$@"
