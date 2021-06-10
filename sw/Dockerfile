FROM        alpine:3.13 AS runtime

RUN         apk add --no-cache --update libgcc libstdc++ ca-certificates libcrypto1.1 libssl1.1 libgomp expat mpv ruby-full mkvtoolnix

FROM        alpine:3.13 AS build

RUN         apk add --no-cache --update libgcc libstdc++ ca-certificates libcrypto1.1 libssl1.1 libgomp expat git

WORKDIR     /tmp/workdir

ENV         FFMPEG_VERSION=4.4 \
            FDKAAC_VERSION=2.0.2 \
            LIBASS_VERSION=0.15.1 \
            FRIBIDI_VERSION=1.0.10 \
            FONTCONFIG_VERSION=2.13.1 \
            LIBPTHREAD_STUBS_VERSION=0.4 \
            X265_VERSION=3.5 \
            OTHER_TRANSCODE_VERSION=0.9.0 \
            SRC=/usr/local


ARG         LD_LIBRARY_PATH=/opt/ffmpeg/lib
ARG         MAKEFLAGS="-j2"
ARG         PKG_CONFIG_PATH="/opt/ffmpeg/share/pkgconfig:/opt/ffmpeg/lib/pkgconfig:/opt/ffmpeg/lib64/pkgconfig"
ARG         PREFIX=/opt/ffmpeg
ARG         LD_LIBRARY_PATH="/opt/ffmpeg/lib:/opt/ffmpeg/lib64"


RUN     buildDeps="autoconf \
                   automake \
                   bash \
                   binutils \
                   bzip2 \
                   cmake \
                   curl \
                   coreutils \
                   diffutils \
                   file \
                   g++ \
                   gcc \
                   gperf \
                   libtool \
                   make \
                   python3 \
                   openssl-dev \
                   tar \
                   yasm \
                   nasm \
                   zlib-dev \
                   xz \
                   util-linux-dev \
                   harfbuzz-dev \
                   patch \
                   expat-dev" && \
        apk add --no-cache --update ${buildDeps}

## fridibi https://www.fribidi.org/
## required for libass
RUN  \
       DIR=/tmp/fribidi && \
       mkdir -p ${DIR} && \
       cd ${DIR} && \
       curl -sLO https://github.com/fribidi/fribidi/releases/download/v${FRIBIDI_VERSION}/fribidi-${FRIBIDI_VERSION}.tar.xz && \
       tar -x --strip-components=1 -f fribidi-${FRIBIDI_VERSION}.tar.xz && \
       ./autogen.sh && \
       ./configure --prefix="${PREFIX}" --disable-static --enable-shared && \
       make -j1 && \
       make install && \
       rm -rf ${DIR}

## fontconfig https://www.freedesktop.org/wiki/Software/fontconfig/
## required for libass
RUN  \
       DIR=/tmp/fontconfig && \
       mkdir -p ${DIR} && \
       cd ${DIR} && \
       curl -sLO https://www.freedesktop.org/software/fontconfig/release/fontconfig-${FONTCONFIG_VERSION}.tar.bz2 && \
       tar -jx --strip-components=1 -f fontconfig-${FONTCONFIG_VERSION}.tar.bz2 && \
       ./configure --prefix="${PREFIX}" --disable-static --enable-shared && \
       make && \
       make install && \
       rm -rf ${DIR}

## libass https://github.com/libass/libass
## This is for subtitles
RUN  \
       DIR=/tmp/libass && \
       mkdir -p ${DIR} && \
       cd ${DIR} && \
       curl -sLO https://github.com/libass/libass/archive/${LIBASS_VERSION}.tar.gz && \
       tar -zx --strip-components=1 -f ${LIBASS_VERSION}.tar.gz && \
       ./autogen.sh && \
       ./configure --prefix="${PREFIX}" --disable-static --enable-shared && \
       make && \
       make install && \
       rm -rf ${DIR}

### x265 http://x265.org/
### The multilib.patch removes 12bit support from x265, as 8bit & 10bit is all that's needed right now.
COPY multilib.patch /tmp/multilib.patch
RUN \
        DIR=/tmp/x265 && \
        mkdir -p ${DIR} && \
        cd ${DIR} && \
        git clone https://bitbucket.org/multicoreware/x265_git && \
        cd x265_git/build/linux && \
        git checkout Release_${X265_VERSION} && \
        patch -p1 multilib.sh < /tmp/multilib.patch && \
        ./multilib.sh && \
        rm -rf ${DIR}

### fdk-aac https://github.com/mstorsjo/fdk-aac
RUN \
        DIR=/tmp/fdk-aac && \
        mkdir -p ${DIR} && \
        cd ${DIR} && \
        curl -sL https://github.com/mstorsjo/fdk-aac/archive/v${FDKAAC_VERSION}.tar.gz | \
        tar -zx --strip-components=1 && \
        autoreconf -fiv && \
        ./configure --prefix="${PREFIX}" --enable-shared --datadir="${DIR}" && \
        make && \
        make install && \
        rm -rf ${DIR}

### libpthread
RUN \
        DIR=/tmp/libpthread-stubs && \
        mkdir -p ${DIR} && \
        cd ${DIR} && \
        curl -sLO https://xcb.freedesktop.org/dist/libpthread-stubs-${LIBPTHREAD_STUBS_VERSION}.tar.gz && \
        tar -zx --strip-components=1 -f libpthread-stubs-${LIBPTHREAD_STUBS_VERSION}.tar.gz && \
        ./configure --prefix="${PREFIX}" && \
        make && \
        make install && \
        rm -rf ${DIR}

## x264 http://www.videolan.org/developers/x264.html
RUN \
        DIR=/tmp/x264 && \
        mkdir -p ${DIR} && \
        cd ${DIR} && \
        git clone https://code.videolan.org/videolan/x264.git . && \
        ./configure --prefix="${PREFIX}" --enable-shared --enable-pic --disable-cli && \
        make && \
        make install && \
        rm -rf ${DIR}

## ffmpeg https://ffmpeg.org/
RUN  \
        DIR=/tmp/ffmpeg && mkdir -p ${DIR} && cd ${DIR} && \
        curl -sLO https://ffmpeg.org/releases/ffmpeg-${FFMPEG_VERSION}.tar.bz2 && \
        tar -jx --strip-components=1 -f ffmpeg-${FFMPEG_VERSION}.tar.bz2

RUN \
        DIR=/tmp/ffmpeg && mkdir -p ${DIR} && cd ${DIR} && \
        ./configure \
        --disable-debug \
        --disable-doc \
        --disable-ffplay \
        --disable-postproc \
        --enable-shared \
        --enable-fontconfig \
        --enable-libass \
        --enable-gpl \
        --enable-libx265 \
        --enable-libx264 \
        --enable-nonfree \
        --enable-libfdk_aac \
        --enable-small \
        --enable-version3 \
        --extra-libs=-ldl \
        --prefix="${PREFIX}" \
        --extra-libs=-lpthread \
        --extra-cflags="-I${PREFIX}/include" \
        --extra-ldflags="-L${PREFIX}/lib" && \
        make && \
        make install && \
        make distclean && \
        hash -r && \
        cd tools && \
        make qt-faststart && cp qt-faststart ${PREFIX}/bin/

RUN \
    ldd ${PREFIX}/bin/ffmpeg | grep opt/ffmpeg | cut -d ' ' -f 3 | xargs -i cp {} /usr/local/lib/ && \
    for lib in /usr/local/lib/*.so.*; do ln -s "${lib##*/}" "${lib%%.so.*}".so; done && \
    cp ${PREFIX}/bin/* /usr/local/bin/ && \
    cp -r ${PREFIX}/share/ffmpeg /usr/local/share/ && \
    LD_LIBRARY_PATH=/usr/local/lib ffmpeg -buildconf && \
    mkdir -p /usr/local/include && \
    cp -r ${PREFIX}/include/libav* ${PREFIX}/include/libsw* /usr/local/include && \
    mkdir -p /usr/local/lib/pkgconfig && \
    for pc in ${PREFIX}/lib/pkgconfig/libav*.pc ${PREFIX}/lib/pkgconfig/libsw*.pc; do \
        sed "s:${PREFIX}:/usr/local:g" <"$pc" >/usr/local/lib/pkgconfig/"${pc##*/}"; \
    done


### other-transcode https://github.com/donmelton/other_video_transcoding
RUN \
        curl -sLO https://raw.githubusercontent.com/donmelton/other_video_transcoding/${OTHER_TRANSCODE_VERSION}/bin/other-transcode && \
        mv other-transcode /usr/local/bin/other-transcode && \
        chmod a+x /usr/local/bin/other-transcode


### Release Stage
FROM        runtime AS release
MAINTAINER  Sean Johnson <sean@ttys0.net>

ENV         LD_LIBRARY_PATH=/usr/local/lib:/usr/local/lib64

CMD         ["--help"]
ENTRYPOINT  ["/usr/local/bin/other-transcode"]

COPY --from=build /usr/local /usr/local/


