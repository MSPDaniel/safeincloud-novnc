FROM debian:12-slim
ENV DEBIAN_FRONTEND=noninteractive
RUN set -eux; \
    printf 'deb http://deb.debian.org/debian bookworm main contrib non-free non-free-firmware\ndeb http://deb.debian.org/debian bookworm-updates main contrib non-free non-free-firmware\ndeb http://security.debian.org/debian-security bookworm-security main contrib non-free non-free-firmware\n' > /etc/apt/sources.list; \
    rm -f /etc/apt/sources.list.d/debian.sources; \
    echo 'msttcorefonts msttcorefonts/accepted-mscorefonts-eula select true' | debconf-set-selections; \
    dpkg --add-architecture i386; apt-get update; \
    apt-get install -y --no-install-recommends \
      wine wine64 wine32 winetricks cabextract \
      chromium xdg-utils xterm openbox tigervnc-standalone-server \
      novnc websockify dbus-x11 xauth x11-xserver-utils \
      fonts-dejavu-core fonts-liberation fonts-wine ttf-mscorefonts-installer \
      fontconfig wget curl unzip p7zip-full ca-certificates \
      procps gosu tini python3 mesa-utils libgl1-mesa-dri; \
    fc-cache -f; rm -rf /var/lib/apt/lists/*
ENV DISPLAY=:1 WINEPREFIX=/config/safeincloud/wine WINEDEBUG=-all \
    LIBGL_ALWAYS_SOFTWARE=1 GALLIUM_DRIVER=llvmpipe \
    BROWSER=/usr/local/bin/safeincloud-browser HOME=/config \
    DISPLAY_WIDTH=1440 DISPLAY_HEIGHT=900 USER_ID=99 GROUP_ID=100 \
    INSTALL_DOTNET48=1
COPY scripts/ /opt/safeincloud/scripts/
RUN chmod +x /opt/safeincloud/scripts/*.sh && \
    ln -s /opt/safeincloud/scripts/browser.sh /usr/local/bin/safeincloud-browser && \
    mkdir -p /config /opt/safeincloud/source
EXPOSE 5800
VOLUME ["/config", "/opt/safeincloud/source"]
ENTRYPOINT ["/usr/bin/tini", "--", "/opt/safeincloud/scripts/entrypoint.sh"]
