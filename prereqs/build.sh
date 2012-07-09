#!/bin/sh
# Build Firefox prereqs
# 
# Copyright (C) 2012 Gregor Richards
# 
# Permission to use, copy, modify, and/or distribute this software for any
# purpose with or without fee is hereby granted, provided that the above
# copyright notice and this permission notice appear in all copies.
# 
# THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES WITH
# REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF MERCHANTABILITY
# AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY SPECIAL, DIRECT,
# INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES WHATSOEVER RESULTING FROM
# LOSS OF USE, DATA OR PROFITS, WHETHER IN AN ACTION OF CONTRACT, NEGLIGENCE OR
# OTHER TORTIOUS ACTION, ARISING OUT OF OR IN CONNECTION WITH THE USE OR
# PERFORMANCE OF THIS SOFTWARE.

if [ ! "$MUSL_CC_BASE" ]
then
    MUSL_CC_BASE=`dirname "$0"`
fi

# Fail on any command failing, show commands:
set -ex

. "$MUSL_CC_BASE/defs.sh"

LD_LIBRARY_PATH="$PREFIX/lib${LD_LIBRARY_PATH+:}${LD_LIBRARY_PATH}"
export LD_LIBRARY_PATH
PKG_CONFIG_PATH="$PREFIX/lib/pkgconfig"
export PKG_CONFIG_PATH

# ( GTK+

# zlib
fetchextract http://zlib.net/ zlib-$ZLIB_VERSION .tar.bz2
OLDCC="$CC"
CC="$TRIPLE-gcc"
export CC
buildinstall '' zlib-$ZLIB_VERSION
unset CC
[ -n "$OLDCC" ] && CC="$OLDCC"
export CC
unset OLDCC

# freetype
fetchextract http://download.savannah.gnu.org/releases/freetype/ freetype-$FREETYPE_VERSION .tar.bz2
cp -f "$MUSL_CC_BASE/config.sub" freetype-$FREETYPE_VERSION/builds/unix/config.sub
buildinstall 1 freetype-$FREETYPE_VERSION --host=$TRIPLE

# expat
fetchextract http://sourceforge.net/projects/expat/files/expat/$EXPAT_VERSION/ expat-$EXPAT_VERSION .tar.gz
cp -f "$MUSL_CC_BASE/config.sub" expat-$EXPAT_VERSION/conftools/config.sub
buildinstall 1 expat-$EXPAT_VERSION --host=$TRIPLE CFLAGS='-g -O2 -Dcaddr_t=void*'

# fontconfig
fetchextract http://www.freedesktop.org/software/fontconfig/release/ fontconfig-$FONTCONFIG_VERSION .tar.bz2
cp -f "$MUSL_CC_BASE/config.sub" fontconfig-$FONTCONFIG_VERSION/config.sub
buildinstall 1 fontconfig-$FONTCONFIG_VERSION --host=$TRIPLE CFLAGS='-g -O2 -D_GNU_SOURCE'

# xorg
gitfetchextract git://repo.or.cz/xorg-util-modular.git $X_VERSION util-modular-$X_VERSION
if [ ! -e util-modular-$X_VERSION/built ]
then
    (
    cd util-modular-$X_VERSION
    export PREFIX
    export MAKEFLAGS
    TRIPLE_GNU=`echo "$TRIPLE" | sed 's/-.*/-musly-linux-gnu/'`
    CC="$TRIPLE-gcc -D_GNU_SOURCE -D_BSD_SOURCE -Wno-error=return-type" \
        ./build.sh \
        --confflags "--host=$TRIPLE_GNU xorg_cv_cc_flag__Werror_return_type=no xorg_cv_cc_flag__errwarn_E_FUNC_HAS_NO_RETURN_STMT=no" \
        --modfile "$MUSL_CC_BASE/x.mods" \
        --clone --autoresume building.ar $PREFIX
    touch built
    )
fi

# libffi
fetchextract ftp://sourceware.org/pub/libffi/ libffi-$LIBFFI_VERSION .tar.gz
cp -f "$MUSL_CC_BASE/config.sub" libffi-$LIBFFI_VERSION/config.sub
buildinstall 1 libffi-$LIBFFI_VERSION --host=$TRIPLE

# dbus
fetchextract http://dbus.freedesktop.org/releases/dbus/ dbus-$DBUS_VERSION .tar.gz
cp -f "$MUSL_CC_BASE/config.sub" dbus-$DBUS_VERSION/config.sub
buildinstall 1 dbus-$DBUS_VERSION --host=$TRIPLE

# glib
fetchextract http://ftp.gnome.org/pub/gnome/sources/glib/$GLIB_MINOR/ glib-$GLIB_VERSION .tar.xz
cp -f "$MUSL_CC_BASE/config.sub" glib-$GLIB_VERSION/config.sub
buildinstall 1 glib-$GLIB_VERSION --host=$TRIPLE CFLAGS='-g -O2 -D_GNU_SOURCE'

# libpng
fetchextract http://prdownloads.sourceforge.net/libpng/ libpng-$LIBPNG_VERSION .tar.xz
cp -f "$MUSL_CC_BASE/config.sub" libpng-$LIBPNG_VERSION/config.sub
buildinstall 1 libpng-$LIBPNG_VERSION --host=$TRIPLE

# pixman
fetchextract http://cairographics.org/releases/ pixman-$PIXMAN_VERSION .tar.gz
cp -f "$MUSL_CC_BASE/config.sub" pixman-$PIXMAN_VERSION/config.sub
buildinstall 1 pixman-$PIXMAN_VERSION --host=$TRIPLE ac_cv_tls=none

# cairo
fetchextract http://www.cairographics.org/releases/ cairo-$CAIRO_VERSION .tar.xz
cp -f "$MUSL_CC_BASE/config.sub" cairo-$CAIRO_VERSION/build/config.sub
buildinstall 1 cairo-$CAIRO_VERSION --host=$TRIPLE --enable-pthread

# pango
fetchextract http://ftp.gnome.org/pub/gnome/sources/pango/$PANGO_MINOR/ pango-$PANGO_VERSION .tar.xz
cp -f "$MUSL_CC_BASE/config.sub" pango-$PANGO_VERSION/config.sub
buildinstall 1 pango-$PANGO_VERSION --host=$TRIPLE

# atk
fetchextract http://ftp.gnome.org/pub/gnome/sources/atk/$ATK_MINOR/ atk-$ATK_VERSION .tar.xz
cp -f "$MUSL_CC_BASE/config.sub" atk-$ATK_VERSION/config.sub
buildinstall 1 atk-$ATK_VERSION --host=$TRIPLE

# tiff
fetchextract http://download.osgeo.org/libtiff/ tiff-$TIFF_VERSION .tar.gz
cp -f "$MUSL_CC_BASE/config.sub" tiff-$TIFF_VERSION/config/config.sub
buildinstall 1 tiff-$TIFF_VERSION --host=$TRIPLE

# jpeg
fetchextract http://www.ijg.org/files/ jpegsrc.v$JPEG_VERSION .tar.gz
cp -f "$MUSL_CC_BASE/config.sub" jpeg-$JPEG_VERSION/config.sub
buildinstall 1 jpeg-$JPEG_VERSION --host=$TRIPLE

# gdk-pixbuf
fetchextract http://ftp.gnome.org/pub/gnome/sources/gdk-pixbuf/$GDK_PIXBUF_MINOR/ gdk-pixbuf-$GDK_PIXBUF_VERSION .tar.xz
cp -f "$MUSL_CC_BASE/config.sub" gdk-pixbuf-$GDK_PIXBUF_VERSION/config.sub
buildinstall 1 gdk-pixbuf-$GDK_PIXBUF_VERSION --host=$TRIPLE

# gtk+
fetchextract http://ftp.gnome.org/pub/gnome/sources/gtk+/$GTK_MINOR/ gtk+-$GTK_VERSION .tar.xz
#cp -f "$MUSL_CC_BASE/config.sub" gtk+-$GTK_VERSION/build-aux/config.sub
cp -f "$MUSL_CC_BASE/config.sub" gtk+-$GTK_VERSION/config.sub
buildinstall 1 gtk+-$GTK_VERSION --host=$TRIPLE --disable-cups \
    ac_cv_func_isnan=yes ac_cv_func_isinf=yes \
    CFLAGS="-g -O2 -D_GNU_SOURCE" # _GNU_SOURCE is actually only for M_PI in math.h
# )

# ( Other dependencies
fetchextract http://ftp.gnome.org/pub/gnome/sources/libnotify/$LIBNOTIFY_MINOR/ libnotify-$LIBNOTIFY_VERSION .tar.xz
cp -f "$MUSL_CC_BASE/config.sub" libnotify-$LIBNOTIFY_VERSION/build-aux/config.sub
buildinstall 1 libnotify-$LIBNOTIFY_VERSION --host=$TRIPLE

fetchextract http://dbus.freedesktop.org/releases/dbus-glib/ dbus-glib-$DBUS_GLIB_VERSION .tar.gz
cp -f "$MUSL_CC_BASE/config.sub" dbus-glib-$DBUS_GLIB_VERSION/config.sub
buildinstall 1 dbus-glib-$DBUS_GLIB_VERSION --host=$TRIPLE

fetchextract http://curl.haxx.se/download/ curl-$CURL_VERSION .tar.bz2
cp -f "$MUSL_CC_BASE/config.sub" curl-$CURL_VERSION/config.sub
buildinstall 1 curl-$CURL_VERSION --host=$TRIPLE CFLAGS="-g -O2 -D_GNU_SOURCE"

fetchextract ftp://ftp.freedesktop.org/pub/mesa/$MESA_VERSION/ MesaLib-$MESA_VERSION .tar.bz2 && mkdir -p MesaLib-$MESA_VERSION
cp -f "$MUSL_CC_BASE/config.sub" Mesa-$MESA_VERSION/bin/config.sub
sed 's/_GNU_SOURCE/__GLIBC__/g' -i Mesa-$MESA_VERSION/src/glsl/strtod.c # wtf
buildinstall '' Mesa-$MESA_VERSION --host=$TRIPLE --disable-dri \
    --disable-driglx-direct --disable-gallium-llvm \
    --with-gallium-drivers=swrast \
    CFLAGS="-g -O2 -D_XOPEN_SOURCE=600"

fetchextract ftp://ftp.alsa-project.org/pub/lib/ alsa-lib-$ALSA_LIB_VERSION .tar.bz2
cp -f "$MUSL_CC_BASE/config.sub" alsa-lib-$ALSA_LIB_VERSION/config.sub
buildinstall 1 alsa-lib-$ALSA_LIB_VERSION --host=$TRIPLE \
    --disable-python \
    CC="$TRIPLE-gcc" \
    CFLAGS="-g -O2 -include stdlib.h -include $PWD/alsa-lib-$ALSA_LIB_VERSION/dladdr_hack.c -D_POSIX_C_SOURCE=200809L -D_GNU_SOURCE -DF_SETSIG=10"
# )
