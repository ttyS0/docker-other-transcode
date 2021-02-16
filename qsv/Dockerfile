FROM  ubuntu:focal AS runtime

RUN   runDeps="ca-certificates \
               expat \
               mpv \
               ruby \
               mkvtoolnix \
               intel-media-va-driver-non-free \
               libmfx1 \
               libva-drm2 \
               libigfxcmrt7 \
               libass9 \
               libfreetype6 \
               libfribidi0 \
               locales \
               libfontconfig1" && \
        apt-get -yqq update && \
        DEBIAN_FRONTEND="noninteractive" apt-get install -yq --no-install-recommends ${runDeps} && \
        apt-get upgrade -y && \
        apt-get clean -y

RUN   sed -i -e 's/# en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen && \
      dpkg-reconfigure --frontend=noninteractive locales && \
      update-locale LANG=en_US.UTF-8

FROM        ubuntu:focal AS build

WORKDIR     /tmp/workdir

ENV         FFMPEG_VERSION=4.3.1 \
            FDKAAC_VERSION=2.0.1 \
            OTHER_TRANSCODE_VERSION=0.8.0 \
            SRC=/usr/local \
            LIBVA_DRIVER_NAME=iHD


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
                   ca-certificates \
                   curl \
                   coreutils \
                   diffutils \
                   file \
                   g++ \
                   gcc \
                   git \
                   gperf \
                   libtool \
                   make \
                   python3 \
                   pkg-config \
                   libssl-dev \
                   libass-dev \
                   libfontconfig1-dev \
                   libfreetype-dev \
                   libpthread-stubs0-dev \
                   tar \
                   xz-utils \
                   yasm \
                   nasm \
                   libfribidi-dev \
                   zlib1g-dev \
                   libexpat1-dev \
                   libmfx1 \
                   libmfx-dev \
                   libmfx-tools \
                   libva-drm2 \
                   libsdl2-dev \
                   libva-dev \
                   libigfxcmrt-dev" && \
        apt-get -yqq update && \
        DEBIAN_FRONTEND="noninteractive" apt-get install -yq --no-install-recommends ${buildDeps}

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

## ffmpeg https://ffmpeg.org/
RUN  \
        DIR=/tmp/ffmpeg && mkdir -p ${DIR} && cd ${DIR} && \
        #git clone https://git.ffmpeg.org/ffmpeg.git .
        curl -sLO https://ffmpeg.org/releases/ffmpeg-${FFMPEG_VERSION}.tar.bz2 && \
        tar -jx --strip-components=1 -f ffmpeg-${FFMPEG_VERSION}.tar.bz2



RUN \
        DIR=/tmp/ffmpeg && mkdir -p ${DIR} && cd ${DIR} && \
        ./configure \
        --disable-debug \
        --disable-doc \
        --disable-ffplay \
        --enable-shared \
        --enable-avresample \
        --enable-gpl \
        --enable-libass \
        --enable-fontconfig \
        --enable-libfreetype \
        --enable-nonfree \
        --enable-openssl \
        --enable-libfdk_aac \
        --enable-postproc \
        --enable-small \
        --enable-version3 \
        --extra-libs=-ldl \
        --prefix="${PREFIX}" \
        --enable-libmfx \
        --enable-vaapi \
        --enable-sdl \
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
    cp -r ${PREFIX}/include/libav* ${PREFIX}/include/libpostproc ${PREFIX}/include/libsw* /usr/local/include && \
    mkdir -p /usr/local/lib/pkgconfig && \
    for pc in ${PREFIX}/lib/pkgconfig/libav*.pc ${PREFIX}/lib/pkgconfig/libpostproc.pc ${PREFIX}/lib/pkgconfig/libsw*.pc; do \
        sed "s:${PREFIX}:/usr/local:g" <"$pc" >/usr/local/lib/pkgconfig/"${pc##*/}"; \
    done

## other-transcode https://github.com/donmelton/other_video_transcoding
RUN \
    curl -o /usr/local/bin/other-transcode -sL https://raw.githubusercontent.com/donmelton/other_video_transcoding/${OTHER_TRANSCODE_VERSION}/bin/other-transcode && \
    chmod a+x /usr/local/bin/other-transcode

## add my personal wrapper script
COPY mytranscode.sh /usr/local/bin/mytranscode.sh
RUN chmod a+x /usr/local/bin/mytranscode.sh

### Release Stage
FROM        runtime AS release
MAINTAINER  Sean Johnson <sean@ttys0.net>

ENV         LD_LIBRARY_PATH=/usr/local/lib:/usr/local/lib64 \
            LIBVA_DRIVER_NAME="iHD" \
            LANG=en_US.UTF-8

CMD         ["--help"]
ENTRYPOINT  ["/usr/local/bin/other-transcode"]

COPY --from=build /usr/local /usr/local/


