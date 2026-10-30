FROM debian:12-slim
ENV DEBIAN_FRONTEND=noninteractive
RUN set -eux; dpkg --add-architecture i386; \
    printf 'deb http://deb.debian.org/debian bookworm main contrib non-free non-free-firmware\ndeb http://deb.debian.org/debian bookworm-updates main contrib non-free non-free-firmware\ndeb http://security.debian.org/debian-security bookworm-security main contrib non-free non-free-firmware\n' > /etc/apt/sources.list; \
    rm -f /etc/apt/sources.list.d/debian.sources; apt-get update; \
    apt-get install -y --no-install-recommends ca-certificates curl wget gnupg debconf-utils; \
    mkdir -p /usr/share/keyrings; \
    wget -qO /tmp/winehq.key https://dl.winehq.org/wine-builds/winehq.key; \
    gpg --batch --yes --dearmor -o /usr/share/keyrings/winehq-archive.gpg /tmp/winehq.key; \
    chmod 644 /usr/share/keyrings/winehq-archive.gpg; \
    rm -f /tmp/winehq.key; \
    printf "deb [arch=amd64,i386 signed-by=/usr/share/keyrings/winehq-archive.gpg] https://dl.winehq.org/wine-builds/debian/ bookworm main\n" > /etc/apt/sources.list.d/winehq.list; \
    echo 'ttf-mscorefonts-installer msttcorefonts/accepted-mscorefonts-eula select true' | debconf-set-selections; \
    apt-get update; \
    apt-get install -y --install-recommends winehq-stable; \
    apt-get install -y --no-install-recommends \
      winetricks cabextract chromium xdg-utils xterm openbox python3-xdg \
      tigervnc-standalone-server novnc websockify dbus-x11 xauth x11-xserver-utils \
      fonts-dejavu-core fonts-liberation fonts-wine ttf-mscorefonts-installer \
      fontconfig unzip p7zip-full procps gosu tini python3 \
      xvfb xfonts-base mesa-utils libgl1-mesa-dri; \
    fc-cache -f; rm -rf /var/lib/apt/lists/*
ENV DISPLAY=:1 WINEPREFIX=/config/safeincloud/wine WINEDEBUG=-all \
    LIBGL_ALWAYS_SOFTWARE=1 GALLIUM_DRIVER=llvmpipe \
    HOME=/config BROWSER=/usr/local/bin/safeincloud-browser \
    DISPLAY_WIDTH=1440 DISPLAY_HEIGHT=900 USER_ID=99 GROUP_ID=100 \
    INSTALL_DOTNET48=0
RUN mkdir -p /config/safeincloud /opt/safeincloud/source /opt/safeincloud/wine-template /tmp/.X11-unix && chmod 1777 /tmp/.X11-unix; \
    if ! getent group 100 >/dev/null; then groupadd -g 100 appgroup; fi; \
    useradd -u 99 -g 100 -d /config -s /bin/bash -M appuser; chown -R 99:100 /config
# Build-time installation, not runtime. The Wine prefix is initialized at its final absolute path.
# Failure stops the GitHub build instead of publishing a broken .NET image.
ARG PREINSTALL_DOTNET48=1
RUN if [ "$PREINSTALL_DOTNET48" = 1 ]; then \
      gosu 99:100 env HOME=/config WINEPREFIX=/config/safeincloud/wine WINEDEBUG=-all \
        xvfb-run -a -s '-screen 0 1440x900x24' sh -ec \
        'wineboot --init; wineserver -w; winetricks -q dotnet48; wineserver -w'; \
      test -s /config/safeincloud/wine/system.reg; \
      grep -Eiq 'dotnet48|Microsoft\\\\NET Framework\\\\v4' /config/safeincloud/wine/winetricks.log /config/safeincloud/wine/system.reg; \
      touch /config/safeincloud/.dotnet48-installed; \
      tar -C /config/safeincloud -czf /opt/safeincloud/wine-template.tar.gz wine .dotnet48-installed; \
      rm -rf /config/safeincloud/wine /config/safeincloud/.dotnet48-installed; \
    fi
COPY scripts/ /opt/safeincloud/scripts/
RUN chmod +x /opt/safeincloud/scripts/*.sh && \
    ln -s /opt/safeincloud/scripts/browser.sh /usr/local/bin/safeincloud-browser
EXPOSE 5800
VOLUME ["/config", "/opt/safeincloud/source"]
ENTRYPOINT ["/usr/bin/tini", "--", "/opt/safeincloud/scripts/entrypoint.sh"]
