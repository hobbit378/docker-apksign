FROM debian:bookworm

ARG CMDTOOLS_URL="https://dl.google.com/android/repository/commandlinetools-linux-10406996_latest.zip"

ENV BUILDTOOlS_PKG="build-tools;33.0.2" \
    BUILDTOOlS_VER="33.0.2" \
    SDK_HOME="/opt/androidsdk"

RUN echo 'debconf debconf/frontend select Noninteractive' | debconf-set-selections && \
    apt-get clean && \
    apt-get update && \
    apt-get -y upgrade && \
    apt-get -y install openjdk-17-jre less vim wget zip zipalign && \
    \
    mkdir -p /project && \
    mkdir -p /opt/androidsdk && \
    \
    wget -t3 -qO /tmp/tmp.zip "${CMDTOOLS_URL}" && \
    unzip /tmp/tmp.zip -d /opt/androidsdk && rm /tmp/tmp.zip && \
    ln -s "${SDK_HOME}/cmdline-tools/bin/sdkmanager" /usr/bin && \
    \
    yes|sdkmanager --sdk_root=${SDK_HOME} "${BUILDTOOlS_PKG}" && \
    ln -s "${SDK_HOME}/build-tools/${BUILDTOOlS_VER}/apksigner" /usr/bin
