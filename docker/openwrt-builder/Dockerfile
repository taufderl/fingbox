# OpenWrt build environment (keeps build deps off the host).
# Build:  docker build -t fingbox-openwrt-builder docker/openwrt-builder
# Use:    scripts/openwrt-build.sh <make args>
FROM debian:trixie

RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
	build-essential clang flex bison g++ gawk gcc-multilib g++-multilib gettext git \
	libncurses-dev libssl-dev python3 python3-dev python3-setuptools python3-pyelftools \
	rsync swig unzip zlib1g-dev file wget curl ca-certificates xz-utils zstd bzip2 \
	patch perl time diffutils libelf-dev quilt ccache less vim-tiny \
	&& rm -rf /var/lib/apt/lists/*

ARG UID=1000
ARG GID=1000
RUN groupadd -g ${GID} builder && useradd -m -u ${UID} -g ${GID} -s /bin/bash builder
USER builder
WORKDIR /src
