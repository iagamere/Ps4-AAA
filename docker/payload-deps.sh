#!/usr/bin/env bash
# Builds the libraries needed by the ezremote server for ps4-payload-dev/sdk.
# Everything is installed into $PS4_PAYLOAD_SDK/target/user/homebrew (PS4_SYSROOT + PS4_HBROOT),
# which orbis-clang already has on its -L path.
#
# Recipes for zlib and openssl follow ps4-payload-dev/pacbrew (zlib/PKGBUILD, openssl/PKGBUILD).
# json-c, libssh2, libsmb2 and libnfs are NOT in pacbrew: their recipes here are generic
# CMake cross builds, checked only by compiling and linking (never run on a console).
set -euo pipefail

: "${PS4_PAYLOAD_SDK:?PS4_PAYLOAD_SDK is not set}"
WORK="${1:-$(mktemp -d)}"
mkdir -p "$WORK"
cd "$WORK"

# shellcheck disable=SC1091
source "$PS4_PAYLOAD_SDK/toolchain/orbis.sh"   # sets CC CXX AR RANLIB CMAKE PREFIX DESTDIR ...
JOBS="$(nproc)"

ZLIB_VER=1.3.2
OPENLIBM_VER=0.8.6
OPENSSL_VER=3.5.2
JSONC_TAG=json-c-0.18-20240915
SSH2_VER=1.11.1
CURL_VER=8.13.0
PSL_VER=0.21.5
SMB2_REPO=https://github.com/cy33hc/libsmb2.git;  SMB2_BRANCH=ps4
NFS_REPO=https://github.com/cy33hc/libnfs.git;    NFS_BRANCH=ps4

say() { echo; echo "=== $* ==="; }

# cmake projects: install into the sysroot, find other libs there
cmake_dep() {  # <srcdir> [extra cmake args...]
    local src="$1"; shift
    rm -rf "$src/build-ps4"
    "$CMAKE" -S "$src" -B "$src/build-ps4" \
        -DCMAKE_BUILD_TYPE=Release \
        -DCMAKE_INSTALL_PREFIX="$PS4_HBROOT" \
        -DCMAKE_PREFIX_PATH="$PS4_HBROOT" \
        -DBUILD_SHARED_LIBS=OFF -DBUILD_TESTING=OFF \
        "$@"
    "$CMAKE" --build "$src/build-ps4" -j"$JOBS"
    DESTDIR="$PS4_SYSROOT" "$CMAKE" --install "$src/build-ps4"
}

say "zlib $ZLIB_VER"
curl -fsSL -o zlib.tgz "https://github.com/madler/zlib/releases/download/v$ZLIB_VER/zlib-$ZLIB_VER.tar.gz"
tar xf zlib.tgz
( cd "zlib-$ZLIB_VER"
  ./configure --prefix="$PREFIX"
  make -j"$JOBS" CFLAGS=-Os
  make install DESTDIR="$PS4_SYSROOT" )

say "openssl $OPENSSL_VER"
curl -fsSL -o openssl.tgz "https://github.com/openssl/openssl/releases/download/openssl-$OPENSSL_VER/openssl-$OPENSSL_VER.tar.gz"
tar xf openssl.tgz
( cd "openssl-$OPENSSL_VER"
  ./Configure BSD-x86_64 no-tests no-apps no-shared --prefix="$PREFIX"
  make -j"$JOBS" build_sw
  make install_sw DESTDIR="$PS4_SYSROOT" )

say "openlibm $OPENLIBM_VER (the SDK has no libm; recipe from pacbrew openlibm/PKGBUILD)"
git clone -q --depth 1 --branch "v$OPENLIBM_VER" https://github.com/JuliaMath/openlibm.git "openlibm-$OPENLIBM_VER"
( cd "openlibm-$OPENLIBM_VER"
  "$CMAKE" -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_LIBDIR="$PS4_HBROOT/lib" -B build -S .
  make -C build -j"$JOBS"
  make -C build install DESTDIR="$PS4_SYSROOT"
  ln -sf libopenlibm.a "$PS4_SYSROOT$PS4_HBROOT/lib/libm.a" )

say "json-c $JSONC_TAG"
git clone -q --depth 1 --branch "$JSONC_TAG" https://github.com/json-c/json-c.git
cmake_dep json-c

say "libpsl $PSL_VER (curl needs it; recipe from pacbrew libpsl/PKGBUILD)"
curl -fsSL -o libpsl.tgz "https://github.com/rockdaboot/libpsl/releases/download/$PSL_VER/libpsl-$PSL_VER.tar.gz"
tar xf libpsl.tgz
( cd "libpsl-$PSL_VER"
  ./configure --prefix="$PREFIX" --host=x86_64-pc-freebsd --enable-static --disable-shared --disable-nls
  make -j"$JOBS"
  make install DESTDIR="$PS4_SYSROOT"
  "$PS4_CROSS_FIX_ROOT" "$PS4_SYSROOT$PS4_HBROOT" )

say "curl $CURL_VER (only <curl/curl.h> is included by baseclient.cpp; recipe from pacbrew curl/PKGBUILD)"
curl -fsSL -o curl.txz "https://github.com/curl/curl/releases/download/curl-${CURL_VER//./_}/curl-$CURL_VER.tar.xz"
tar xf curl.txz
( cd "curl-$CURL_VER"
  sed -i 's|define USE_XATTR| |g' src/tool_xattr.h
  # CA bundle is only runtime data (the server does not link curl); do not fail the image if mozilla is unreachable
  ./scripts/mk-ca-bundle.pl || echo "WARNING: CA bundle download failed - ca-bundle.crt will be missing"
  ./configure --prefix="$PREFIX" --host=x86_64-pc-freebsd \
      --enable-static --disable-shared --with-openssl \
      --with-ca-bundle="$PREFIX/etc/ca-bundle.crt" --disable-docs
  make -j"$JOBS"
  make install DESTDIR="$PS4_SYSROOT"
  if [ -f ca-bundle.crt ]; then mkdir -p "$PS4_SYSROOT$PS4_HBROOT/etc"; cp ca-bundle.crt "$PS4_SYSROOT$PS4_HBROOT/etc"; fi )

say "libssh2 $SSH2_VER"
curl -fsSL -o ssh2.tgz "https://github.com/libssh2/libssh2/releases/download/libssh2-$SSH2_VER/libssh2-$SSH2_VER.tar.gz"
tar xf ssh2.tgz
cmake_dep "libssh2-$SSH2_VER" -DCRYPTO_BACKEND=OpenSSL -DENABLE_ZLIB_COMPRESSION=ON \
    -DBUILD_EXAMPLES=OFF -DBUILD_TESTING=OFF

# The cy33hc ps4 branches were written for OpenOrbis, which defines __PS4__ and ships <endian.h>.
# ps4-payload-dev/sdk defines __ORBIS__ + __FreeBSD__ instead and only has <sys/endian.h>.
# Workaround (visible, no source patched): define __PS4__ and provide a one-line endian.h shim.
SHIM="$WORK/shim"; mkdir -p "$SHIM"; printf '#include <sys/endian.h>\n' > "$SHIM/endian.h"
PS4COMPAT="-D__PS4__ -I$SHIM"

say "libsmb2 ($SMB2_BRANCH)"
git clone -q --depth 1 --branch "$SMB2_BRANCH" "$SMB2_REPO" libsmb2
cmake_dep libsmb2 "-DCMAKE_C_FLAGS=$PS4COMPAT"

say "libnfs ($NFS_BRANCH)"
git clone -q --depth 1 --branch "$NFS_BRANCH" "$NFS_REPO" libnfs
# libnfs only includes <sys/uio.h> when HAVE_SYS_UIO_H is set (autoconf does that, its CMake does not)
cmake_dep libnfs "-DCMAKE_C_FLAGS=$PS4COMPAT -DHAVE_SYS_UIO_H=1" -DENABLE_TESTS=OFF -DENABLE_DOCUMENTATION=OFF -DENABLE_UTILS=OFF -DENABLE_EXAMPLES=OFF

say "check"
LIBDIR="$PS4_SYSROOT$PS4_HBROOT/lib"
missing=0
for l in libz.a libm.a libpsl.a libcurl.a libcrypto.a libssl.a libjson-c.a libssh2.a libsmb2.a libnfs.a; do
    if [ -f "$LIBDIR/$l" ]; then echo "ok      $l"; else echo "MISSING $l"; missing=1; fi
done
exit $missing
