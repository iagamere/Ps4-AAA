# PS4 (OpenOrbis via PacBrew) toolchain image.
# Recipe source: cy33hc/ps4-ezremote-client README + PacBrew/pacbrew-packages README (Ubuntu 24.04 route).
# Steps marked "UNVERIFIED" had no recipe in those READMEs; they fail loudly if wrong (see toolchain.yml logs).
FROM ubuntu:24.04

ARG REPO_URL=""
LABEL org.opencontainers.image.source="${REPO_URL}"
LABEL org.opencontainers.image.description="PS4 OpenOrbis toolchain + libs for ps4-ezremote-server"

SHELL ["/bin/bash", "-o", "pipefail", "-c"]
ENV DEBIAN_FRONTEND=noninteractive

# --- host tools + pacman (PacBrew README, "ubuntu 24.04") ---
RUN apt-get update && apt-get install -y --no-install-recommends \
      pacman-package-manager makepkg libarchive-tools build-essential \
      autoconf automake libtool cmake nasm git curl wget ca-certificates \
      python3 python3-setuptools pkg-config xz-utils unzip zip file perl \
    && rm -rf /var/lib/apt/lists/*

# --- pacbrew repository ---
RUN set -eux; \
    test -f /etc/pacman.conf || printf '[options]\nArchitecture = auto\n' > /etc/pacman.conf; \
    printf '\n[pacbrew]\nSigLevel = Optional TrustAll\nServer = https://pacman.mydedibox.fr/pacbrew/packages/\n' >> /etc/pacman.conf; \
    cat /etc/pacman.conf

# --- toolchain + portlibs (zlib, libjson-c, mbedtls, libcurl(mbedtls), ...) ---
# Docker has no /etc/mtab and pacman's CheckSpace needs it ("could not open file: /etc/mtab") -> link it and disable CheckSpace.
RUN set -eux; \
    ln -sf /proc/self/mounts /etc/mtab; \
    sed -i 's/^CheckSpace/#CheckSpace/' /etc/pacman.conf; \
    pacman -Sy --noconfirm; \
    pacman -S --noconfirm ps4-openorbis ps4-openorbis-portlibs; \
    chmod a+x /opt/pacbrew/ps4/openorbis/ps4vars.sh

ENV PACBREW=/opt/pacbrew \
    OPENORBIS=/opt/pacbrew/ps4/openorbis

WORKDIR /opt/src

# --- OpenSSL (cy33hc/ps4-openssl, branch OpenSSL_1_1_1-ps4) ---
RUN set -eux; \
    source /opt/pacbrew/ps4/openorbis/ps4vars.sh; \
    git clone --depth 1 -b OpenSSL_1_1_1-ps4 https://github.com/cy33hc/ps4-openssl.git openssl; \
    cd openssl; \
    ./Configure --prefix=/opt/pacbrew/ps4/openorbis/usr ps4-cross; \
    make -j"$(nproc)"; \
    make install; \
    cd ..; rm -rf openssl

# --- libcurl 7.80.0 (README recipe: -DSOL_IP=0, -lSceNet, comment out osreldate.h) ---
RUN set -eux; \
    source /opt/pacbrew/ps4/openorbis/ps4vars.sh; \
    curl -fsSL https://curl.haxx.se/download/curl-7.80.0.tar.xz -o curl.tar.xz; \
    tar xf curl.tar.xz; cd curl-7.80.0; \
    autoreconf -fi; \
    CFLAGS="${CFLAGS} -DSOL_IP=0" LIBS="${LIBS} -lSceNet" \
      ./configure --prefix="${OPENORBIS}/usr" --host=x86_64 \
        --disable-shared --enable-static --with-openssl --disable-manual; \
    sed -i 's|#include <osreldate.h>|//#include <osreldate.h>|g' include/curl/curl.h; \
    make -j"$(nproc)" -C lib install; \
    make -C include install; \
    cd ..; rm -rf curl-7.80.0 curl.tar.xz

# --- libsmb2 (cy33hc/libsmb2, branch ps4; README_PS4.md recipe) ---
RUN set -eux; \
    source /opt/pacbrew/ps4/openorbis/ps4vars.sh; \
    git clone --depth 1 -b ps4 https://github.com/cy33hc/libsmb2.git libsmb2; \
    cd libsmb2; mkdir build; cd build; \
    openorbis-cmake -DCMAKE_INSTALL_PREFIX="${OPENORBIS}/usr" ..; \
    make -j"$(nproc)"; \
    make install; \
    cd /opt/src; rm -rf libsmb2

# --- libssh2 -- UNVERIFIED: no PS4 recipe found in any README; generic CMake cross build ---
RUN set -eux; \
    source /opt/pacbrew/ps4/openorbis/ps4vars.sh; \
    curl -fsSL https://github.com/libssh2/libssh2/releases/download/libssh2-1.11.0/libssh2-1.11.0.tar.gz -o ssh2.tgz; \
    tar xf ssh2.tgz; cd libssh2-1.11.0; mkdir build; cd build; \
    openorbis-cmake -DCMAKE_INSTALL_PREFIX="${OPENORBIS}/usr" \
      -DBUILD_SHARED_LIBS=OFF -DBUILD_EXAMPLES=OFF -DBUILD_TESTING=OFF \
      -DCRYPTO_BACKEND=OpenSSL \
      -DOPENSSL_INCLUDE_DIR="${OPENORBIS}/usr/include" \
      -DOPENSSL_SSL_LIBRARY="${OPENORBIS}/usr/lib/libssl.a" \
      -DOPENSSL_CRYPTO_LIBRARY="${OPENORBIS}/usr/lib/libcrypto.a" \
      ..; \
    make -j"$(nproc)"; \
    make install; \
    cd /opt/src; rm -rf libssh2-1.11.0 ssh2.tgz

# --- libnfs (cy33hc/libnfs, branch ps4) -- UNVERIFIED: no PS4 recipe found; generic CMake cross build ---
RUN set -eux; \
    source /opt/pacbrew/ps4/openorbis/ps4vars.sh; \
    git clone --depth 1 -b ps4 https://github.com/cy33hc/libnfs.git libnfs; \
    cd libnfs; mkdir build; cd build; \
    openorbis-cmake -DCMAKE_INSTALL_PREFIX="${OPENORBIS}/usr" -DBUILD_SHARED_LIBS=OFF ..; \
    make -j"$(nproc)"; \
    make install; \
    cd /opt/src; rm -rf libnfs

# --- json-c: already provided by ps4-openorbis-portlibs (ps4-openorbis-libjson-c 0.15, PS4-patched) ---

# --- final check: every library the server links must exist as a static lib ---
RUN set -eu; \
    U=/opt/pacbrew/ps4/openorbis/usr/lib; L=/opt/pacbrew/ps4/openorbis/lib; miss=0; \
    for f in libz.a libcrypto.a libssl.a libjson-c.a libsmb2.a libssh2.a libnfs.a libcurl.a; do \
      if [ -f "$U/$f" ]; then echo "OK      $f"; else echo "MISSING $f (searched $U)"; miss=1; fi; \
    done; \
    echo "--- kernel_sys / Sce* libs visible in the SDK (informational) ---"; \
    find /opt/pacbrew/ps4/openorbis \( -name 'libkernel_sys*' -o -name 'libSceNet*' -o -name 'libSceSysmodule*' -o -name 'libSceSystemService*' \) | sort || true; \
    test "$miss" = 0

WORKDIR /
