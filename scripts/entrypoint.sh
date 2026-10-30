#!/bin/bash
set -Eeuo pipefail
uid="${USER_ID:-99}"; gid="${GROUP_ID:-100}"
if ! [[ "$uid" =~ ^[0-9]+$ && "$gid" =~ ^[0-9]+$ ]]; then echo 'USER_ID/GROUP_ID must be numeric' >&2; exit 1; fi
if ! getent group "$gid" >/dev/null; then groupadd -g "$gid" appgroup; fi
if ! id -u appuser >/dev/null 2>&1; then useradd -u "$uid" -g "$gid" -d /config -s /bin/bash -M appuser; fi
mkdir -p /config/safeincloud /config/.vnc /config/.cache /config/.config
chown -R "$uid:$gid" /config
exec gosu "$uid:$gid" /opt/safeincloud/scripts/session.sh
