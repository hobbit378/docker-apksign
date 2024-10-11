ARG DISTRO=bookworm
ARG DEFAULT_USER=vscode

#
### STAGE 1
#


FROM debian:${DISTRO} AS apksign

LABEL org.opencontainers.image.description=\
"This container provides tools and custom scripts to sign Android APK package files"

ARG DEFAULT_USER

RUN export DEBIAN_FRONTEND=noninteractive && \
\
# update base image & install required packages
apt-get update && \ 
apt-get upgrade -y && \
apt-get install -y \
        apksigner \
        curl \
        git \
        sudo  \
        vim \
        wget \
        zip \
        zipalign && \
\
# cleanup filesystem
apt-get autoclean ; \
apt-get autoremove ; \
\
# add user & password and put him into 'sudo' group
useradd -mG sudo ${DEFAULT_USER} && \
echo "${DEFAULT_USER}:${DEFAULT_USER}" | chpasswd 

WORKDIR /home/${DEFAULT_USER}
USER ${DEFAULT_USER}

ENTRYPOINT [ "/bin/bash" ]


#
### STAGE 2
#

FROM apksign

ADD rootfs/ /

CMD [ "/usr/local/bin/apkps","-h" ]
