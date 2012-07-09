# Definitions for build scripts
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

ORIGPWD="$PWD"
cd "$MUSL_CC_BASE"
MUSL_CC_BASE="$PWD"
export MUSL_CC_BASE
cd "$ORIGPWD"
unset ORIGPWD

if [ ! -e config.sh ]
then
    echo 'Create a config.sh file.'
    exit 1
fi

# Versions of things (do this before config.sh so they can be config'd)

# ( GTK+
ATK_VERSION=2.4.0
ATK_MINOR=2.4
CAIRO_VERSION=1.12.2
DBUS_VERSION=1.6.2
EXPAT_VERSION=2.1.0
FONTCONFIG_VERSION=2.9.92
FREETYPE_VERSION=2.4.10
GLIB_VERSION=2.32.3
GLIB_MINOR=2.32
GDK_PIXBUF_VERSION=2.26.1
GDK_PIXBUF_MINOR=2.26
#GTK_VERSION=3.4.3
#GTK_MINOR=3.4
GTK_VERSION=2.24.10
GTK_MINOR=2.24
JPEG_VERSION=8d
LIBFFI_VERSION=3.0.11
LIBPNG_VERSION=1.5.11
PANGO_VERSION=1.30.1
PANGO_MINOR=1.30
PIXMAN_VERSION=0.26.2
TIFF_VERSION=4.0.2
X_VERSION=7cb6c735a5cbc491bc8df7e61d671e4f894a9ed9
ZLIB_VERSION=1.2.7
# )

# ( Other dependencies
LIBNOTIFY_VERSION=0.7.5
LIBNOTIFY_MINOR=0.7
DBUS_GLIB_VERSION=0.100
CURL_VERSION=7.26.0
MESA_VERSION=8.0.3
ALSA_LIB_VERSION=1.0.25
# )

. ./config.sh

PATH="$CC_PREFIX/bin:$PATH"
export PATH

die() {
    echo "$@"
    exit 1
}

fetch() {
    if [ ! -e "$MUSL_CC_BASE/tarballs/$2" ]
    then
        wget "$1""$2" -O "$MUSL_CC_BASE/tarballs/$2" || ( rm -f "$MUSL_CC_BASE/tarballs/$2" && return 1 )
    fi
    return 0
}

extract() {
    if [ ! -e "$2" ]
    then
        tar xf "$MUSL_CC_BASE/tarballs/$1" ||
            tar Jxf "$MUSL_CC_BASE/tarballs/$1" ||
            tar jxf "$MUSL_CC_BASE/tarballs/$1" ||
            tar zxf "$MUSL_CC_BASE/tarballs/$1"
    fi
}

fetchextract() {
    fetch "$1" "$2""$3"
    extract "$2""$3" "$2"
}

gitfetchextract() {
    if [ ! -e "$MUSL_CC_BASE/tarballs/$3".tar.gz ]
    then
        git archive --format=tar --remote="$1" "$2" | \
            gzip -c > "$MUSL_CC_BASE/tarballs/$3".tar.gz || die "Failed to fetch $3-$2"
    fi
    if [ ! -e "$3/extracted" ]
    then
        mkdir -p "$3"
        (
        cd "$3" || die "Failed to cd $3"
        extract "$3".tar.gz extracted
        touch extracted
        )
    fi
}

muslfetchextract() {
    if [ "$MUSL_GIT" = "yes" ]
    then
        gitfetchextract 'git://repo.or.cz/musl.git' $MUSL_VERSION musl-$MUSL_VERSION
    else
        fetchextract http://www.etalabs.net/musl/releases/ musl-$MUSL_VERSION .tar.gz
    fi
}

patch_source() {
    BD="$1"

    (
    cd "$BD" || die "Failed to cd $BD"

    if [ -e "$MUSL_CC_BASE/patches/$BD"-musl.diff -a ! -e patched ]
    then
        patch -p1 < "$MUSL_CC_BASE/patches/$BD"-musl.diff || die "Failed to patch $BD"
        touch patched
    fi
    )
}

build() {
    BP="$1"
    BD="$2"
    CF="./configure"
    BUILT="$PWD/$BD/built$BP"
    shift; shift

    if [ ! -e "$BUILT" ]
    then
        patch_source "$BD"

        (
        cd "$BD" || die "Failed to cd $BD"

        if [ "$BP" ]
        then
            mkdir -p build"$BP"
            cd build"$BP" || die "Failed to cd to build dir for $BD $BP"
            CF="../configure"
        fi
        ( $CF --prefix="$PREFIX" "$@" &&
            make $MAKEFLAGS &&
            touch "$BUILT" ) ||
            die "Failed to build $BD"

        )
    fi
}

buildmake() {
    BD="$1"
    BUILT="$PWD/$BD/built"
    shift

    if [ ! -e "$BUILT" ]
    then
        (
        cd "$BD" || die "Failed to cd $BD"

        if [ -e "$MUSL_CC_BASE/$BD"-musl.diff -a ! -e patched ]
        then
            patch -p1 < "$MUSL_CC_BASE/$BD"-musl.diff || die "Failed to patch $BD"
            touch patched
        fi

        ( make "$@" $MAKEFLAGS &&
            touch "$BUILT" ) ||
            die "Failed to build $BD"

        )
    fi
}

doinstall() {
    BP="$1"
    BD="$2"
    INSTALLED="$PWD/$BD/installed$BP"
    shift; shift

    if [ ! -e "$INSTALLED" ]
    then
        (
        cd "$BD" || die "Failed to cd $BD"

        if [ "$BP" ]
        then
            cd build"$BP" || die "Failed to cd build$BP"
        fi

        ( make install "$@" &&
            touch "$INSTALLED" ) ||
            die "Failed to install $BP"

        )
    fi
}

buildinstall() {
    build "$@"
    doinstall "$1" "$2"
}
