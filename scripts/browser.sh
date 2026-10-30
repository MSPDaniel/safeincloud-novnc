#!/bin/bash
# Open Linux Chromium in the same remote desktop session.
exec /usr/bin/chromium --no-first-run --disable-dev-shm-usage --password-store=basic --user-data-dir=/config/.config/chromium-safeincloud "$@"
