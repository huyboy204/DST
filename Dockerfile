FROM --platform=linux/amd64 ubuntu:22.04

# Set environment variables
ENV DEBIAN_FRONTEND=noninteractive \
    USER=steam \
    HOME=/home/steam \
    STEAMCMD_DIR=/home/steam/steamcmd \
    DST_DIR=/home/steam/dst

# Install dependencies
RUN apt-get update && apt-get install -y \
    lib32gcc-s1 \
    lib32stdc++6 \
    libc6 \
    libstdc++6 \
    libcurl4-gnutls-dev \
    libcurl3-gnutls \
    libgcc1 \
    libstdc++6 \
    wget \
    curl \
    ca-certificates \
    procps \
    gettext-base \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Create steam user and home directories
RUN useradd -m -d $HOME -s /bin/bash $USER

# Create necessary directories as steam user
RUN mkdir -p $STEAMCMD_DIR $DST_DIR

RUN cd $STEAMCMD_DIR \
    && wget https://steamcdn-a.akamaihd.net/client/installer/steamcmd_linux.tar.gz \
    && tar -xvzf steamcmd_linux.tar.gz && rm -f steamcmd_linux.tar.gz

# Expose ports
# Game ports (need port forwarding)
EXPOSE 10999/udp 11000/udp
# Steam authentication ports (internal)
EXPOSE 12345/udp 12346/udp 12347/udp 12348/udp
# Shard communication port (internal)
EXPOSE 10888/udp

# Copy startup script
COPY start_server.sh $HOME/start_server.sh
COPY healthcheck.sh $HOME/healthcheck.sh
COPY templates/ $HOME/templates/
RUN chown -R $USER:$USER $HOME

USER $USER
WORKDIR $HOME

RUN chmod +x $HOME/start_server.sh $HOME/healthcheck.sh

# Set the entrypoint
ENTRYPOINT ["/home/steam/start_server.sh"]
