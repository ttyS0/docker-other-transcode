# Docker container for Don Melton's Other-Transcode Tool

The `other-transcode` tool leverages `ffmpeg`, and by default tries to take advantage of hardware accelerated encoding. Since the different hardware dependencies are of varying levels of size and complexity, I've broken them up into three image types, `nvidia`, `vaapi`, `qsv`, and `sw`.

## NVidia

This image builds `ffmpeg` with NVidia & CUDA libraries, and should be used on systems that have an NVENC capable NVidia card.

### Requirements

* The latest [NVidia drivers from NVidia](https://www.nvidia.com/Download/index.aspx), _not_ the ones bundled with the running Linux Distribution, should be used.

* The latest [Docker-CE](https://docs.docker.com/engine/install/), _not_ the Docker bundled with the running Linux Distribution should be used. This is to provide the best compatibility with the NVidia Container Toolkit. With newer distributions, such as Ubuntu 20.04, the distro bundled Docker seems to work fine. When in doubt, use the upstream.

* The [NVidia Container Toolkit](https://github.com/NVIDIA/nvidia-docker) must be installed. It's very important to restart the Docker daemon after installation as it updates the Docker configuration.

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


# Usage

Create a sub directory into which source files are put. In these examples I name that `src`.

```
\_src
  \_source_file.mkv
```

Using that setup, to transcode `source_file.mkv` with the default H264 encoding, some recommended Docker commands for the different images are listed below. For more options, see [Don's Documentation](https://github.com/donmelton/other_video_transcoding/wiki). The important thing to be aware of here is to make sure the tag name lines up with the hardware you're planning on using.

```
# Software Encoding H.264
docker run --rm -v $(pwd):$(pwd) -w $(pwd) \ 
  hub.skj.dev/other-transcode:sw-0.3.2 --x264-avbr --target=5000 \
  src/source_file.mkv

# NVidia Encoding H.264
docker run --rm --gpus all -v $(pwd):$(pwd) -w $(pwd) \ 
  hub.skj.dev/other-transcode:nvidia-0.3.2 \
  src/source_file.mkv

# NVidia Encoding HEVC (non-Turing card)
docker run --rm --gpus all -v $(pwd):$(pwd) -w $(pwd) \ 
  hub.skj.dev/other-transcode:nvidia-0.3.2 --hevc \
  src/source_file.mkv
  
# NVidia Encoding HEVC (Turing card)
docker run --rm --gpus all -v $(pwd):$(pwd) -w $(pwd) \ 
  hub.skj.dev/other-transcode:nvidia-0.3.2 --hevc --nvenc-temporal-aq \
  src/source_file.mkv
```

# About

[Don Melton](http://donmelton.com/) of [Video Transcoding](https://github.com/donmelton/video_transcoding) fame has brought his expertise to hardware accelerated transcoding in the form of [Other Video Transcoding](https://github.com/donmelton/other_video_transcoding). While Don covers the installation and usage of `other-transcode` for all normal desktop platforms, this repository's focus is using `other-transcode` as a Docker container.

I have leaned _heavily_ on [Julien Rottenberg's](https://github.com/jrottenberg) [ffmpeg](https://github.com/jrottenberg/ffmpeg) Dockerfiles. Basically I've taken them, pulled out a lot of the `ffmpeg` compile options, added in the `other-transcode` dependencies, and finally bundled in `other-transcode` itself.

