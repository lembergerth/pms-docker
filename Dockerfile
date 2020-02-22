FROM multiarch/debian-debootstrap:armhf-stretch-slim

ARG S6_OVERLAY_VERSION=v1.21.7.0
ARG DEBIAN_FRONTEND="noninteractive"
ENV TERM="xterm" LANG="C.UTF-8" LC_ALL="C.UTF-8"

ENTRYPOINT ["/init"]

RUN \
# Update and get dependencies
    apt-get update && \
    apt-get install -y \
      tzdata \
      curl \
      xmlstarlet \
      uuid-runtime \
      unrar-free

# Fetch and extract S6 overlay
RUN curl -J -L -o /tmp/s6-overlay-armhf.tar.gz https://github.com/just-containers/s6-overlay/releases/download/${S6_OVERLAY_VERSION}/s6-overlay-armhf.tar.gz && \
    tar xzf /tmp/s6-overlay-armhf.tar.gz -C /

# Add user
RUN useradd -U -d /config -s /bin/false plex && \
    usermod -G users plex

# Setup directories
RUN mkdir -p \
      /config \
      /transcode \
      /data

# Cleanup
RUN apt-get -y autoremove && \
    apt-get -y clean && \
    rm -rf /var/lib/apt/lists/* && \
    rm -rf /tmp/* && \
    rm -rf /var/tmp/*

EXPOSE 32400/tcp 3005/tcp 8324/tcp 32469/tcp 1900/udp 32410/udp 32412/udp 32413/udp 32414/udp
VOLUME /config /transcode

ENV CHANGE_CONFIG_DIR_OWNERSHIP="true" \
    HOME="/config"

ARG TAG=
ARG URL=https://downloads.plex.tv/plex-media-server-new/1.18.7.2438-f342a5a43/debian/plexmediaserver_1.18.7.2438-f342a5a43_armhf.deb

COPY root/ /

RUN \
# Save version and install
    /installBinary.sh

HEALTHCHECK --interval=5s --timeout=2s --retries=20 CMD /healthcheck.sh || exit 1
