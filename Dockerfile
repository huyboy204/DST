FROM --platform=linux/amd64 ubuntu:22.04

# Set environment variables
ENV DEBIAN_FRONTEND=noninteractive \
    USER=steam \
    HOME=/opt/steam \
    STEAMCMD_DIR=/opt/steam/steamcmd \
    DST_DIR=/opt/steam/dst

# Enable i386 architecture and install dependencies
RUN dpkg --add-architecture i386 \
    && apt-get update && apt-get install -y \
    lib32gcc-s1 \
    lib32stdc++6 \
    libcurl4-gnutls-dev:i386 \
    libcurl3-gnutls:i386 \
    libc6:i386 \
    libstdc++6:i386 \
    wget \
    curl \
    ca-certificates \
    procps \
    gettext-base \
    && ln -s /usr/lib/i386-linux-gnu/libcurl-gnutls.so.4 /usr/lib/libcurl-gnutls.so.4 2>/dev/null || true \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Create steam user and directories
RUN useradd -m -d $HOME -s /bin/bash $USER \
    && mkdir -p $STEAMCMD_DIR $DST_DIR \
    && chown -R $USER:$USER $HOME

# Switch to steam user
USER $USER
WORKDIR $HOME

# Download and install SteamCMD
RUN cd $STEAMCMD_DIR \
    && wget https://steamcdn-a.akamaihd.net/client/installer/steamcmd_linux.tar.gz \
    && tar -xvzf steamcmd_linux.tar.gz && rm -f steamcmd_linux.tar.gz

# Note: SteamCMD will initialize on first run in the startup script

# Create necessary directories for DST server
RUN mkdir -p $HOME/.klei/DoNotStarveTogether/MyDediServer/Master \
    && mkdir -p $HOME/.klei/DoNotStarveTogether/MyDediServer/Caves

# Expose ports
# Game ports (need port forwarding)
EXPOSE 10999/udp 11000/udp
# Steam authentication ports (internal)
EXPOSE 12345/udp 12346/udp 12347/udp 12348/udp
# Shard communication port (internal)
EXPOSE 10888/udp

# Copy startup script
COPY --chown=steam:steam start_server.sh $HOME/start_server.sh
COPY --chown=steam:steam healthcheck.sh $HOME/healthcheck.sh
COPY --chown=steam:steam templates/ $HOME/templates/
RUN chmod +x $HOME/start_server.sh $HOME/healthcheck.sh

# Set the entrypoint
ENTRYPOINT ["/opt/steam/start_server.sh"]
