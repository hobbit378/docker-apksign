FROM debian:bookworm

ARG CMD_TOOLS_URL="https://dl.google.com/android/repository/commandlinetools-linux-10406996_latest.zip"

ENV BUILD_TOOlS_PKG="build-tools" \
    BUILD_TOOlS_VER="33.0.2" \
    DISTRO_PKGS="   zip \
                    less \
                    vim \
                    wget \
                    sudo" \
    JDK_PKG=openjdk-17-jre \
    SDK_HOME="/opt/sdk"

RUN export DEBIAN_FRONTEND=noninteractive && \
    apt-get update && \ 
    apt-get -y upgrade && \
    apt-get -y install  ${DISTRO_PKGS} \
                        ${JDK_PKG} && \
    \
    # download & install Android commandline tools
    tmpfile=/tmp/cmdtools.zip && \
    mkdir -p ${SDK_HOME} && \
    wget -t3 -qO ${tmpfile} "${CMD_TOOLS_URL}" && \
    unzip ${tmpfile} -d ${SDK_HOME} && \
    \
    # download, install & link Android buildtools via sdkmanager
    ln -s "${SDK_HOME}/cmdline-tools/bin/sdkmanager" /usr/bin && \
    yes|sdkmanager --sdk_root=${SDK_HOME} "${BUILD_TOOlS_PKG};${BUILD_TOOlS_VER}" && \
    ln -s "${SDK_HOME}/build-tools/${BUILD_TOOlS_VER}/zipalign" /usr/bin && \
    ln -s "${SDK_HOME}/build-tools/${BUILD_TOOlS_VER}/apksigner" /usr/bin && \
    \
    # cleanup filesystem
    rm -f ${tmpfile} && \
    apt-get autoclean && \
    apt-get autoremove

ADD --chmod=555 rootfs/sign-linphone.sh /usr/bin/apksigner-linphone

ENTRYPOINT [ "/bin/bash" ]

WORKDIR /project


