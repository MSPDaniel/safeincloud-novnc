# SafeInCloud noVNC — Debian/WineHQ build (experimental)

**Unofficial community project.** Not endorsed by SafeInCloud. Windows SafeInCloud under Wine is not supported by the vendor. Do not trust it with your only password vault until tested and backed up.

## Changes

- Fix repeated container starts: stale `/tmp/.X1-lock` and X11 socket cleanup when no live Xvnc owns the display.
- Application crashes no longer stop noVNC; `wait` watches Xvnc only.
- Install `python3-xdg` for Openbox auto-start warning.
- WineHQ stable rather than Debian's Wine 8 (version may change with upstream).
- Microsoft core fonts via Debian `ttf-mscorefonts-installer`.
- GitHub build-time .NET 4.8 inside a prefix created at `/config/safeincloud/wine`, archived as an image template and seeded into `/config` **only when no prefix exists**. This installation is slow and can fail under Wine; CI fails rather than publishing an incomplete image.
- Linux Chromium for cloud OAuth browser handoff: `winebrowser` + `xdg-open` integration. **Not yet end-to-end tested**; callback URI schemes and providers may still fail under Wine.
- Copies the official portable app from read-only `/opt/safeincloud/source` to writable `/config/safeincloud/app` once, preserving the portable `Data` folder.

## Official application

Get the Windows application only from https://www.safe-in-cloud.com/en/download/ or the developer's verified distribution. The current public Windows link may open Microsoft Store, whose app package is not a portable EXE. **This image does not bundle, scrape, or redistribute the proprietary SafeInCloud app.** If you already have the legitimate portable `SafeInCloud.exe` and companion files, place them in `/mnt/user/appdata/safeincloud-novnc/source/`.

For the official Windows portable edition, `Data/SafeInCloud.db` lives beside the EXE; the container's writable app copy preserves this in `/config/safeincloud/app/Data/`.

## Deployment

1. Back up `/mnt/user/appdata/safeincloud-novnc/config` before changing versions. **Never delete an existing Wine prefix or database to force startup.**
2. Upload these files to `MSPDaniel/safeincloud-novnc`, enable GitHub Actions, and wait for successful GHCR publication. Make GHCR package public or authenticate Docker to GHCR.
3. Use the Unraid XML template or `compose.yaml`. Open `http://UNRAID-IP:5811/vnc.html?autoconnect=true`.
4. For a **new** deployment, build-time .NET template is copied into `/config`. Existing `/config/safeincloud/wine` is deliberately not overwritten. If your old Wine 8 prefix remains, changing to WineHQ stable may trigger prefix migration; back up before testing.
5. In noVNC, use `xterm` to test `/usr/local/bin/safeincloud-browser https://example.com` if cloud restore doesn't open a browser. The OAuth flow may use a custom callback protocol that needs separate work.

## Diagnostics

```bash
docker inspect safeincloud-novnc --format '{{.State.Status}} {{.State.ExitCode}} {{.State.OOMKilled}}'
docker logs --tail 100 safeincloud-novnc
tail -80 /mnt/user/appdata/safeincloud-novnc/config/safeincloud/{xvnc,openbox,novnc,app}.log
```

## Important limitations

- This is **source code, not a successfully built or runtime-tested image**. GitHub Actions is the first real Docker build test. `dotnet48` under WineHQ may need additional adjustments.
- Wine browser integration is a best-effort fix; successful cloud OAuth and callbacks are **not guaranteed**.
- Avoid exposing port 5811 publicly. Put it behind HTTPS and strong authentication (e.g. Authelia), and restrict network access.
- Don't store passwords in Chromium. Back up your database and Wine prefix before upgrades.
