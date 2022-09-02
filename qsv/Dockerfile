FROM  ubuntu:22.04 AS runtime
LABEL org.opencontainers.image.source="https://github.com/ttyS0/docker-other-transcode"


RUN   runDeps="ca-certificates \
               expat \
               ruby \
               mkvtoolnix \
               libass9 \
               libfreetype6 \
               libfribidi0 \
               locales \
               curl \
               libxcb1 \
               libasound2 \
               libsdl2-2.0-0 \
               libsndio7.0 \
               libxv1 \
               libdrm2 \
               libfontconfig1" && \
        apt-get -yqq update && \
        DEBIAN_FRONTEND="noninteractive" apt-get install -yq --no-install-recommends ${runDeps} && \
        apt-get upgrade -y && \
        apt-get clean -y

RUN   sed -i -e 's/# en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen && \
      dpkg-reconfigure --frontend=noninteractive locales && \
      update-locale LANG=en_US.UTF-8

FROM        ubuntu:22.04 AS build

WORKDIR     /tmp/workdir

ENV         FFMPEG_VERSION=5.1.1  \
            FDKAAC_VERSION=2.0.2 \
            LIBVA_DRIVER_NAME="iHD" \
            LIBVA_VERSION=2.15.0 \
            GMMLIB_VERSION=22.1.4 \
            INTEL_MEDIA_VERSION=22.4.4 \
            INTEL_MEDIA_SDK_VERSION=22.4.4


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
                   libtool \
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
                   libdrm-dev \
                   xorg \
                   xorg-dev \
                   openbox \
                   libx11-dev \
                   libgl1-mesa-glx \
                   libgl1-mesa-dev \
                   libsdl2-dev" && \
        apt-get -yqq update && \
        DEBIAN_FRONTEND="noninteractive" apt-get install -yq --no-install-recommends ${buildDeps}

## Intel Media and dependencies
### libva https://github.com/intel/libva
RUN \
        DIR=/tmp/libva && \
        mkdir -p ${DIR} && \
        cd ${DIR} && \
        curl -sL https://github.com/intel/libva/archive/refs/tags/${LIBVA_VERSION}.tar.gz | \
        tar -zx --strip-components=1 && \
        ./autogen.sh --prefix="${PREFIX}" && \
        make && \
        make install && \
        rm -rf ${DIR}

### GmmLib https://github.com/intel/gmmlib
RUN \
        DIR=/tmp/gmmlib && \
        mkdir -p ${DIR} && \
        cd ${DIR} && \
        curl -sL https://github.com/intel/gmmlib/archive/refs/tags/intel-gmmlib-${GMMLIB_VERSION}.tar.gz | \
        tar -zx --strip-components=1 && \
        mkdir build && \
        cd build && \
        cmake -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=${PREFIX} .. && \
        make && \
        make install && \
        rm -rf {DIR}

### Intel Media Driver https://github.com/intel/media-driver
RUN \
        DIR=/tmp/intel-media && \
        mkdir -p ${DIR} && \
        cd ${DIR} && \
        curl -sL https://github.com/intel/media-driver/archive/refs/tags/intel-media-${INTEL_MEDIA_VERSION}.tar.gz | \
        tar -zx --strip-components=1 && \
        mkdir -p ${DIR}/build && \
        cd build && \
        cmake -DCMAKE_INSTALL_PREFIX=${PREFIX} .. && \
        make install && \
        rm -rf ${DIR}

### Intel Media SDK https://github.com/Intel-Media-SDK/MediaSDK
RUN \
        DIR=/tmp/intel-media-sdk && \
        mkdir -p ${DIR} && \
        cd ${DIR} && \
        curl -sL https://github.com/Intel-Media-SDK/MediaSDK/archive/refs/tags/intel-mediasdk-${INTEL_MEDIA_SDK_VERSION}.tar.gz | \
        tar -zx --strip-components=1 && \
        mkdir build && \
        cd build && \
        cmake -DCMAKE_INSTALL_PREFIX=${PREFIX} .. && \
        make && \
        make install && \
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
        --enable-gpl \
        --enable-libass \
        --enable-fontconfig \
        --enable-nonfree \
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


### Release Stage
FROM        runtime AS release
MAINTAINER  Sean Johnson <sean@ttys0.net>
LABEL org.opencontainers.image.source="https://github.com/ttyS0/docker-other-transcode"


ENV         LD_LIBRARY_PATH=/opt/ffmpeg/lib \
            LIBVA_DRIVERS_PATH=/opt/ffmpeg/lib/dri \
            LIBVA_DRIVER_NAME="iHD" \
            OTHER_TRANSCODE_VERSION=0.10.0 \
            LANG=en_US.UTF-8

COPY --from=build /opt /opt/

RUN \
    rm -rf /opt/ffmpeg/share && \
    cd /usr/local/bin && \
    ln -s /opt/ffmpeg/bin/* . && \
    curl -o /usr/local/bin/other-transcode -sL https://raw.githubusercontent.com/donmelton/other_video_transcoding/${OTHER_TRANSCODE_VERSION}/bin/other-transcode && \
    chmod a+x /usr/local/bin/other-transcode

CMD         ["--help"]
ENTRYPOINT  ["/usr/local/bin/other-transcode"]




