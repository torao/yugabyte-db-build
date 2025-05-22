# Build and Testing Environment for YugabyteDB
# BUILD: docker build -t yugabyte-db-build:latest .
FROM almalinux:8

LABEL maintainer="TAKAMI Torao <torao.takami@lycorp.co.jp>"
LABEL description="Build and Testing Environment for YugabyteDB"
LABEL version="1.0"

# Prevent interactive prompts during package installation
ENV DEBIAN_FRONTEND=noninteractive

# Install basic build tools and dependencies
# See also: https://docs.yugabyte.com/preview/contribute/core-database/build-from-src-almalinux/
RUN dnf -y update && \
    dnf -y groupinstall "Development Tools" && \
    dnf -y install epel-release && \
    dnf -y install \
        ccache \
        gcc-toolset-11 \
        gcc-toolset-11-libatomic-devel \
        glibc-langpack-en \
        golang \
        java-1.8.0-openjdk \
        libatomic \
        maven \
        npm \
        patchelf \
        python39 \
        rsync && \
    dnf clean all && \
    alternatives --set python3 /usr/bin/python3.9

# If you'd like to use an unprivileged user for development, manually
# run/modify instructions from here onwards (change $USER, make sure shell
# variables are set appropriately when switching users).
# NOTE that cmake for aarch64 is used here.
ENV HOME=/home/yugabyte
ENV SHELLRC=$HOME/.bashrc
RUN target_arch="$(rpm --query --queryformat='%{ARCH}' rpm)" && \
    case "$target_arch" in \
		aarch64) ninja_zip='ninja-linux-aarch64.zip' ;; \
		x86_64)  ninja_zip='ninja-linux.zip' ;; \
        *) echo >&2 "error: unknown/unsupported architecture '$target_arch'"; exit 1 ;; \
	esac && \
    curl -Ls "https://github.com/ninja-build/ninja/releases/download/v1.12.1/$ninja_zip" | zcat > /usr/local/bin/ninja && \
    chmod +x /usr/local/bin/ninja && \
    echo "LANG=en_US.UTF-8" > /etc/locale.conf && \
    mkdir /opt/yb-build && \
    mkdir /opt/cmake && \
    mkdir -p $HOME/.cache/yb_ccache && \
    case "$target_arch" in \
		aarch64) cmake_arch='aarch64' ;; \
		x86_64)  cmake_arch='x86_64' ;; \
        *) echo >&2 "error: unknown/unsupported architecture '$target_arch'"; exit 1 ;; \
	esac && \
    curl -L "https://github.com/Kitware/CMake/releases/download/v3.31.7/cmake-3.31.7-linux-$cmake_arch.tar.gz" | tar xzC /opt/cmake && \
    echo 'export PATH="/opt/cmake/cmake-3.31.7-linux-'$cmake_arch'/bin:$PATH"' >> "$SHELLRC" && \
    echo '# source /opt/rh/rh-python38/enable'                                 >> "$SHELLRC" && \
    echo '# source /opt/rh/rh-maven35/enable'                                  >> "$SHELLRC" && \
    echo 'source /opt/rh/gcc-toolset-11/enable'                                >> "$SHELLRC" && \
    echo 'export YB_CCACHE_DIR="$HOME/.cache/yb_ccache"'                       >> "$SHELLRC" && \
    echo 'if [ -f ~/.bashrc ]; then . ~/.bashrc; fi'                           >> "$HOME/.bash_profile"

# Add entrypoint script
COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

# Create build directory
RUN mkdir -p /yugabyte-db
WORKDIR /yugabyte-db

# Install gosu
# https://github.com/tianon/gosu/blob/master/INSTALL.md
ENV GOSU_VERSION=1.17
RUN set -eux; \
    dnf -y install wget; \
    target_arch="$(rpm --query --queryformat='%{ARCH}' rpm)" && \
	case "$target_arch" in \
		aarch64) dpkg_arch='arm64' ;; \
		x86_64) dpkg_arch='amd64' ;; \
		*) echo >&2 "error: unknown/unsupported architecture '$target_arch'"; exit 1 ;; \
	esac; \
	wget -O /usr/local/bin/gosu "https://github.com/tianon/gosu/releases/download/$GOSU_VERSION/gosu-$dpkg_arch"; \
	wget -O /usr/local/bin/gosu.asc "https://github.com/tianon/gosu/releases/download/$GOSU_VERSION/gosu-$dpkg_arch.asc"; \
# verify the signature
	export GNUPGHOME="$(mktemp -d)"; \
	gpg --batch --keyserver hkps://keys.openpgp.org --recv-keys B42F6819007F00F88E364FD4036A9C25BF357DD4; \
	gpg --batch --verify /usr/local/bin/gosu.asc /usr/local/bin/gosu; \
	gpgconf --kill all; \
	rm -rf "$GNUPGHOME" /usr/local/bin/gosu.asc; \
	chmod +x /usr/local/bin/gosu; \
# verify that the binary works
	gosu --version; \
	gosu nobody true

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
CMD ["/bin/bash", "-l"]
