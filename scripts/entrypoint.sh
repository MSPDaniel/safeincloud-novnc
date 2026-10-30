#!/bin/bash
set -Eeuo pipefail
uid="${USER_ID:-99}"; gid="${GROUP_ID:-100}"
[[ "$uid" =~ ^[0-9]+$ && "$gid" =~ ^[0-9]+$ ]] || exit 1
if ! getent group "$gid" >/dev/null; then groupadd -g "$gid" appgroup; fi
if ! getent passwd "$uid" >/dev/null; then useradd -u "$uid" -g "$gid" -d /config -s /bin/bash -M appuser; fi
mkdir -p /config/safeincloud /config/.cache /config/.config /config/.vnc
# Unraid's default UID/GID are 99:100. Avoid expensive recursive chown on every boot.
chown "$uid:$gid" /config /config/safeincloud /config/.cache /config/.config /config/.vnc
if [[ ! -e /config/safeincloud/wine/system.reg && -s /opt/safeincloud/wine-template.tar.gz ]]; then
  echo 'Seeding preinstalled Wine/.NET prefix into persistent /config...'
  tar -C /config/safeincloud -xzf /opt/safeincloud/wine-template.tar.gz
  chown -R "$uid:$gid" /config/safeincloud/wine /config/safeincloud/.dotnet48-installed
fi
exec gosu "$uid:$gid" /opt/safeincloud/scripts/session.sh
