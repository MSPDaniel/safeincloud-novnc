# SafeInCloud on Debian 12 + Wine + noVNC

**Experimental build.** This project has not been built or runtime-tested here. No password manager executable, proprietary .NET installers, or password databases are included.

## Included
- Debian 12 base with regular system user/group database (not jlesage)
- Wine 8 (Debian Bookworm packages, 32- and 64-bit)
- Microsoft core fonts via `ttf-mscorefonts-installer` (EULA preaccepted for unattended build), plus Liberation/DejaVu/Wine fonts
- Chromium, Openbox, TigerVNC, noVNC
- Persistent Wine prefix and app state under `/config`
- One-time .NET Framework 4.8 install via Winetricks at first startup

## GitHub
1. Upload all package contents (including `.github/workflows/publish.yml`) to `MSPDaniel/safeincloud-novnc` branch `main`.
2. Enable Actions, allow workflow to write packages, and run the build.
3. Set the GHCR package visibility to Public, or authenticate Unraid to GHCR.
4. Wait for a successful publish before pulling on Unraid.

## Unraid
1. **Do not delete or overwrite the working SafeInCloud database.** Back it up first. Do not reuse a live Wine prefix simultaneously.
2. Copy your Windows portable app folder into `/mnt/user/appdata/safeincloud-novnc/source` so the executable is `/mnt/user/appdata/safeincloud-novnc/source/SafeInCloud.exe`.
3. Import `unraid/safeincloud-novnc.xml` as a local Unraid template, or use `compose.yaml`.
4. Start container; first start may take a long time while installing .NET 4.8. Check `/mnt/user/appdata/safeincloud-novnc/config/safeincloud/app.log`.
5. Visit `http://UNRAID-IP:5811/vnc.html?autoconnect=true`.

## Critical notes
- The HTTP noVNC port has **no built-in authentication**. Restrict to trusted LAN or put behind a correctly configured authenticated reverse proxy (e.g. Authelia); do not expose 5811 directly to the internet.
- The Wine prefix lives at `/config/safeincloud/wine`. App-specific data in the source mount is **read-only**; if the portable app stores its database alongside the executable, configure/migrate its data path to a persistent writable location under `/config` before use.
- A working cloud OAuth browser callback is **not yet guaranteed**. Chromium is installed and can be launched from a terminal with `safeincloud-browser`, but Wine-to-Linux browser delegation may need additional configuration.
- `.NET 4.8` installation may fail under Wine 8; inspect the logs. `INSTALL_DOTNET48=0` skips installation only when using a previously configured prefix.
- The Microsoft core font installer downloads licensed font files during image build; you accept its EULA when using this image. Microsoft fonts are not bundled in this source archive.
- Chromium is configured with `--password-store=basic`; do not save passwords in Chromium. Use the SafeInCloud application and protect the persistent `/config` folder.
- The project does not yet have automated build/runtime verification. It is a starting implementation, not a confirmed working SafeInCloud deployment.
