FROM docker.io/library/ubuntu:22.04

# Install base dependencies
RUN apt-get update \
    && apt-get install --yes --no-install-recommends \
        cloud-image-utils=0.32-22-g45fe84a5-0ubuntu1 \
        curl=7.81.0-1ubuntu1.15 \
        gettext-base=0.21-4ubuntu4 \
        locales=2.35-0ubuntu3.6 \
        whois=5.5.13 \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Set Locale
RUN localedef -i en_US -c -f UTF-8 -A /usr/share/locale/locale.alias en_US.UTF-8
ENV LANG en_US.utf8

# Copy Cloud Config Templates
COPY ./template /usr/src/app/template

# Copy entrypoint
COPY ./entrypoint.sh /entrypoint.sh

# Set Workdir
WORKDIR /usr/src/app/

# Entrypoint
ENTRYPOINT ["/bin/sh", "/entrypoint.sh"]

# Command
CMD ["bash"]
