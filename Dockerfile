FROM cs50/cli:amd64-jammy
ARG DEBIAN_FRONTEND=noninteractive


# Unset user
USER root


# Install Ubuntu packages
RUN apt update && \
    apt install --no-install-recommends --yes \
        dwarfdump \
        jq \
        manpages-dev \
        pgloader \
        php-cli \
        php-mbstring \
        php-sqlite3


# For temporarily removing ACLs via opt/cs50/bin/postCreateCommand
# https://github.community/t/bug-umask-does-not-seem-to-be-respected/129638/9
RUN apt update && \
    apt install acl


# Install VS Code extensions
RUN npm install -g vsce && \
    mkdir --parents /opt/cs50/extensions && \
    cd /tmp && \
    git clone https://github.com/cs50/cs50.vsix.git && \
    cd cs50.vsix && \
    npm install && \
    vsce package && \
    mv cs50-0.0.1.vsix /opt/cs50/extensions && \
    pip3 install python-clients/cs50vsix-client/ && \
    cd /tmp && \
    rm --force --recursive cs50.vsix && \
    git clone https://github.com/cs50/ddb50.vsix.git && \
    cd ddb50.vsix && \
    npm install && \
    vsce package && \
    mv ddb50-0.0.1.vsix /opt/cs50/extensions && \
    cd /tmp && \
    rm --force --recursive ddb50.vsix && \
    git clone https://github.com/cs50/phpliteadmin.vsix.git && \
    cd phpliteadmin.vsix && \
    npm install && \
    vsce package && \
    mv phpliteadmin-0.0.1.vsix /opt/cs50/extensions && \
    cd /tmp && \
    rm --force --recursive phpliteadmin.vsix && \
    npm uninstall -g vsce


# Copy files to image
COPY ./etc /etc
COPY ./opt /opt
RUN chmod a+rx /opt/cs50/bin/*
RUN chmod a+rx /opt/cs50/phpliteadmin/bin/phpliteadmin
RUN ln --symbolic /opt/cs50/phpliteadmin/bin/phpliteadmin /opt/cs50/bin/phpliteadmin


# Install window manager, X server, x11vnc (VNC server), noVNC (VNC client)
RUN apt install openbox xvfb x11vnc -y
RUN wget https://github.com/novnc/noVNC/archive/refs/tags/v1.3.0.zip -P/tmp && \
    unzip /tmp/v1.3.0.zip -d /tmp && \
    mv /tmp/noVNC-1.3.0 /opt/noVNC && \
    rm -rf /tmp/noVNC-1.3.0 && \
    chown -R ubuntu:ubuntu /opt/noVNC
ENV DISPLAY=":0"

# Temporary workaround for https://github.com/cs50/code.cs50.io/issues/19
RUN echo "if [ -z \"\$_PROFILE_D\" ] ; then for i in /etc/profile.d/*.sh; do if ["$i" == "/etc/profile.d/debuginfod*"] ; then continue; fi; . \"\$i\"; done; export _PROFILE_D=1; fi"


# Install glibc sources for debugger
# https://github.com/Microsoft/vscode-cpptools/issues/1123#issuecomment-335867997
RUN echo "deb-src http://archive.ubuntu.com/ubuntu/ focal main restricted" > /etc/apt/sources.list.d/_.list && \
    apt update && \
    cd /tmp && \
    apt source glibc && \
    rm --force /etc/apt/sources.list.d/_.list && \
    apt update && \
    mkdir --parents /build/glibc-sMfBJT && \
    mv glibc* /build/glibc-sMfBJT && \
    cd /build/glibc-sMfBJT \
    rm --force --recursive *.tar.xz \
    rm --force --recursive *.dsc


# Set user
USER ubuntu
