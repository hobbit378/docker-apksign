ARG DISTRO=bookworm
FROM debian:${DISTRO}

LABEL org.opencontainers.image.description \
    "Container provides tools and helper scripts necessary to (batch-)sign Android(R) APK files \
    including tools to create and modify a keystore required for this task \
    The provided helper script allows for the inclusion of custom patch routines"

ARG DEFAULT_USER=signer
ARG PROJECT_DIR=/project

ENV APK_PATCH_DIR="/usr/local/share/apksign-helper/patches" \
    KSTORE=${PROJECT_DIR}/kstore


RUN export DEBIAN_FRONTEND=noninteractive && \
    apt-get update && \ 
    apt-get upgrade -y && \
    apt-get install -y apksigner zip zipalign \
                        wget vim sudo && \
    \
    # cleanup filesystem
    rm -f ${tmpfile} && \
    apt-get autoclean && \
    apt-get autoremove ; \
    \
    # add user
    useradd -G sudo ${DEFAULT_USER} && \
    echo "${DEFAULT_USER}:${DEFAULT_USER}" | chpasswd && \
    \
    # add folder
    mkdir ${PROJECT_DIR} && \
    chown -vR ${DEFAULT_USER} ${PROJECT_DIR} && \
    : "ln -s /project ~${DEFAULT_USER}/project"

VOLUME [ "${PROJECT_DIR}" ]

WORKDIR "${PROJECT_DIR}"

USER "${DEFAULT_USER}"

ADD rootfs/ /

ENTRYPOINT [ "/bin/bash" ]


