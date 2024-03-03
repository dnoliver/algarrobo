FROM docker.io/library/ubuntu:22.04

# Install base dependencies
RUN apt-get update \
    && apt-get install --yes --no-install-recommends \
        git=1:2.34.1-1ubuntu1.10 \
        netcat=1.218-4ubuntu1 \
        locales=2.35-0ubuntu3.6 \
        openssh-client=1:8.9p1-3ubuntu0.6 \
        python3=3.10.6-1~22.04 \
        python3-pip=22.0.2+dfsg-1ubuntu0.4 \
        iputils-ping=3:20211215-1 \
        sshpass=1.09-1 \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Set Locale
RUN localedef -i en_US -c -f UTF-8 -A /usr/share/locale/locale.alias en_US.UTF-8
ENV LANG en_US.utf8

# Install Ansible
RUN python3 -m pip install --no-cache-dir \
        ansible==9.3.0 \
        ansible-lint==24.2.0

# Add Root SSH Config
COPY ./.ssh /root/.ssh/

# Add Source Code
COPY . /usr/src/app/

# Set Workdir
WORKDIR /usr/src/app/

# Install Ansible Dependencies
RUN ansible-galaxy install -r /usr/src/app/requirements.yml

# Command
CMD ["bash"]
