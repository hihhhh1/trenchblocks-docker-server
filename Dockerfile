FROM ubuntu:22.04

LABEL maintainer="docker-server"

# Disable interactive frontend during package installation
ENV DEBIAN_FRONTEND=noninteractive

# Install 32-bit and 64-bit runtime libraries required by Unreal Engine & SteamCMD
RUN dpkg --add-architecture i386 \
    && apt-get update \
    && apt-get install -y --no-install-recommends \
        ca-certificates \
        curl \
        lib32gcc-s1 \
        libstdc++6 \
        lib32stdc++6 \
        libcurl4 \
        procps \
        findutils \
        locales \
    && locale-gen en_US.UTF-8 \
    && rm -rf /var/lib/apt/lists/*

# Set default locale
ENV LANG=en_US.UTF-8
ENV LANGUAGE=en_US:en
ENV LC_ALL=en_US.UTF-8

# Create dedicated non-root user (steam, UID 1000) for security
ENV USER=steam
ENV HOME=/home/steam
RUN useradd -u 1000 -m -s /bin/bash steam

WORKDIR /home/steam

# Download and install SteamCMD
RUN mkdir -p /home/steam/steamcmd \
    && curl -sqL "https://steamcdn-a.akamaihd.net/client/installer/steamcmd_linux.tar.gz" | tar zxvf - -C /home/steam/steamcmd \
    && chown -R steam:steam /home/steam

# Copy entrypoint script and ensure executable permissions
COPY entrypoint.sh /home/steam/entrypoint.sh

RUN sed -i 's/\r$//' /home/steam/entrypoint.sh \
    && chmod +x /home/steam/entrypoint.sh \
    && chown steam:steam /home/steam/entrypoint.sh

USER steam

# Expose game and query ports
EXPOSE 7777/udp 27015/udp

ENTRYPOINT ["/home/steam/entrypoint.sh"]
