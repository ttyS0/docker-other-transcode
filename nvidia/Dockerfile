#
# This heavily leverages jrottenberg's ffmpeg Dockerfile for ffmpeg:
# https://github.com/jrottenberg/ffmpeg/blob/master/docker-images/4.2/nvidia1804/Dockerfile
#
# I've added the pieces needed by Don Melton's `other-transcode` script:
# https://github.com/donmelton/other_video_transcoding
#

FROM    nvidia/cuda:11.1.1-devel-ubuntu20.04 AS devel-base

ENV	    NVIDIA_DRIVER_CAPABILITIES compute,utility,video

WORKDIR     /tmp/workdir

RUN     apt-get -yqq update && \
        apt-get install -yq --no-install-recommends ca-certificates expat libgomp1 && \
        apt-get autoremove -y && \
        apt-get clean -y

FROM        nvidia/cuda:11.1.1-runtime-ubuntu20.04 AS runtime-base

ENV	    NVIDIA_DRIVER_CAPABILITIES compute,utility,video

WORKDIR     /tmp/workdir

RUN   runDeps="ca-certificates \
               expat \
               mpv \
               ruby \
               mkvtoolnix \
               libxcb-shape0-dev \
               libva-drm2 \
               libva2 \
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

RUN     sed -i -e 's/# en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen && \
        dpkg-reconfigure --frontend=noninteractive locales && \
        update-locale LANG=en_US.UTF-8

FROM devel-base as build

ENV         FFMPEG_VERSION=4.4 \
            FDKAAC_VERSION=2.0.2 \
            OTHER_TRANSCODE_VERSION=0.9.0 \
            SRC=/usr/local

ARG         MAKEFLAGS="-j2"
ARG         PKG_CONFIG_PATH="/opt/ffmpeg/share/pkgconfig:/opt/ffmpeg/lib/pkgconfig:/opt/ffmpeg/lib64/pkgconfig"
ARG         PREFIX=/opt/ffmpeg
ARG         LD_LIBRARY_PATH="/opt/ffmpeg/lib:/opt/ffmpeg/lib64:/usr/lib64:/usr/lib:/lib64:/lib"

RUN      buildDeps="autoconf \
                    automake \
                    cmake \
                    curl \
                    bzip2 \
                    libexpat1-dev \
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
                    g++ \
                    gcc \
                    git \
                    gperf \
                    libtool \
                    make \
                    nasm \
                    perl \
                    python \
                    python3 \
                    libva-dev \
                    zlib1g-dev" && \
        apt-get -yqq update && \
        DEBIAN_FRONTEND="noninteractive" apt-get install -yq --no-install-recommends ${buildDeps}

RUN \
        DIR=/tmp/nv-codec-headers && \
        git clone https://git.videolan.org/git/ffmpeg/nv-codec-headers ${DIR} && \
        cd ${DIR} && \
        make PREFIX="${PREFIX}" && \
        make install PREFIX="${PREFIX}" && \
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
        --extra-libs=-lpthread \
        --enable-postproc \
        --enable-small \
        --enable-version3 \
        --extra-cflags="-I${PREFIX}/include -I${PREFIX}/include/ffnvcodec -I/usr/local/cuda/include/" \
        --extra-ldflags="-L${PREFIX}/lib -L/usr/local/cuda/lib64" \
        --extra-libs=-ldl \
        --prefix="${PREFIX}" \
        --enable-nvdec \
        --enable-cuda \
        --enable-ffnvcodec \
        --enable-libnpp && \
        make && \
        make install && \
        make distclean && \
        hash -r && \
        cd tools && \
        make qt-faststart && \
        cp qt-faststart ${PREFIX}/bin

## cleanup
RUN \
        LD_LIBRARY_PATH="${PREFIX}/lib:${PREFIX}/lib64:${LD_LIBRARY_PATH}" ldd ${PREFIX}/bin/ffmpeg | grep opt/ffmpeg | cut -d ' ' -f 3 | xargs -i cp {} /usr/local/lib/ && \
        cp ${PREFIX}/bin/* /usr/local/bin/ && \
        cp -r ${PREFIX}/share/* /usr/local/share/ && \
        LD_LIBRARY_PATH=/usr/local/lib ffmpeg -buildconf

## other-transcode https://github.com/donmelton/other_video_transcoding
RUN \
        curl -o /usr/local/bin/other-transcode -sLO https://raw.githubusercontent.com/donmelton/other_video_transcoding/${OTHER_TRANSCODE_VERSION}/bin/other-transcode && \
        chmod a+x /usr/local/bin/other-transcode



FROM        runtime-base AS release
MAINTAINER  Sean Johnson <sean@ttys0.net>

CMD         ["--help"]
ENTRYPOINT  ["/usr/local/bin/other-transcode"]
ENV         LD_LIBRARY_PATH=/usr/local/lib

# copy only needed files, without copying nvidia dev files
COPY --from=build /usr/local/bin /usr/local/bin/
COPY --from=build /usr/local/share /usr/local/share/
COPY --from=build /usr/local/lib /usr/local/lib/
COPY --from=build /usr/local/include /usr/local/include/


