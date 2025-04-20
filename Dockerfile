# syntax=docker/dockerfile:1@sha256:4c68376a702446fc3c79af22de146a148bc3367e73c25a5803d453b6b3f722fb

ARG BUILD_FROM=ghcr.io/chukysoria/baseimage-alpine:v0.7.12-3.21@sha256:abd256c8e9410beccdc8ff0e009c12fa9bb64de05bc03f98ebe62595fafd34ff
FROM ${BUILD_FROM} 

# set version label
ARG BUILD_DATE
ARG BUILD_VERSION
ARG BUILD_ARCH=x86_64
ARG BUILD_EXT_RELEASE="v1.34.1.5021"
LABEL build_version="Chukyserver.io version:- ${BUILD_VERSION} Build-date:- ${BUILD_DATE}"
LABEL maintainer="chukysoria"

# environment settings
ARG PROWLARR_BRANCH="master"
ENV XDG_CONFIG_HOME="/config/xdg" \
  COMPlus_EnableDiagnostics=0 \
  TMPDIR=/run/prowlarr-temp

RUN \
  echo "**** install packages ****" && \
  apk add -U --upgrade --no-cache \
    icu-libs=74.2-r0 \
    sqlite-libs=3.48.0-r1 \
    xmlstarlet=1.6.1-r2 && \
  echo "**** install prowlarr ****" && \
  case ${BUILD_ARCH} in \
      "armv7") \
          ARCH="arm" \
          ;; \
      "aarch64") \
          ARCH="arm64" \
          ;; \
      "x86_64") \
          ARCH="x64" \
          ;; \
      *) \
          echo "Unknown architecture: ${BUILD_ARCH}" && \
          exit 1 \
          ;; \
  esac && \
  mkdir -p /app/prowlarr/bin && \
  curl -o \
    /tmp/prowlarr.tar.gz -L \
    "https://prowlarr.servarr.com/v1/update/${PROWLARR_BRANCH}/updatefile?version=${BUILD_EXT_RELEASE#v}&os=linuxmusl&runtime=netcore&arch=${ARCH}" && \
  tar xzf \
    /tmp/prowlarr.tar.gz -C \
    /app/prowlarr/bin --strip-components=1 && \
  echo -e "UpdateMethod=docker\nBranch=${PROWLARR_BRANCH}\nPackageVersion=${BUILD_VERSION}\nPackageAuthor=[linuxserver.io](https://www.linuxserver.io/)" > /app/prowlarr/package_info && \
  echo "**** cleanup ****" && \
  rm -rf \
    /app/prowlarr/bin/Prowlarr.Update \
    /tmp/* \
    /var/tmp/*

# copy local files
COPY root/ /

# ports and volumes
EXPOSE 9696

VOLUME /config

HEALTHCHECK --interval=30s --timeout=30s --start-period=2m --start-interval=5s --retries=5 CMD ["/etc/s6-overlay/s6-rc.d/svc-prowlarr/data/check"]
