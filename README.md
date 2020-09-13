# Docker container for Don Melton's Other-Transcode Tool

The `other-transcode` tool leverages `ffmpeg`, and by default tries to take advantage of hardware accelerated encoding. Since the different hardware dependencies are of varying levels of size and complexity, I've broken them up into three image types, `nvidia`, `vaapi`, `qsv`, and `sw`.

## NVidia

This image builds `ffmpeg` with NVidia & CUDA libraries, and should be used on systems that have an NVENC capable NVidia card.

## VAAPI

This image builds `ffmpeg` with the `VA-API` system to access hardware encoding exposed via the DRI mechanism. This is the easiest way to access Intel QSV, though it does suffer from a lack of encoder acceleration coverage. Most notably HEVC does not work correctly with the `VAAPI` system.

## QSV

This image builds `ffmpeg` with the Intel Media SDK to provide direct use of Intel's QSV system. While more feature complete it is non-trivial to build and may as a result be buggier than `VAAPI`.

## SW

This image is for only using software encoding via `ffmpeg`. It is also the only image that attempts to provide both an Intel (`amd64`) and ARM (`arm64`) image.

# Prebuilt Images

The base image version exactly tracks the `other-transcode` version. The `{version}` suffix can be replaced with `latest` to track the latest builds.

## Docker Hub

While images get pushed automatically to Docker Hub, it's possible they will be unavailable due to limitations of Docker Hub free accounts. Alternatively, they are also available from my self hosted Harbor instance.

* ttys0/other-transcode:nvidia-{version}
* ttys0/other-transcode:vaapi-{version}
* ttys0/other-transcode:qsv-{version}
* ttys0/other-transcode:sw-{version}


## Harbor

These images are served from a self-hosted Harbor instance running in my Home Lab environment. As such, availability is subject to the vagaries of my internet connection and the health of my Home Lab.

* hub.skj.dev/img/other-transcode:nvidia-{version}
* hub.skj.dev/img/other-transcode:vaapi-{version}
* hub.skj.dev/img/other-transcode:qsv-{version}
* hub.skj.dev.img/other-transcode:sw-{version}
