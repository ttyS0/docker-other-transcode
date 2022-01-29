# Docker container for Don Melton's Other-Transcode Tool

The `other-transcode` tool leverages `ffmpeg`, and by default tries to take advantage of hardware accelerated encoding. Since the different hardware dependencies are of varying levels of size and complexity, I've broken them up into three image types, `nvidia`, `qsv`, and `sw`.

## NVidia

This image builds `ffmpeg` with NVidia & CUDA libraries, and should be used on systems that have an NVENC capable NVidia card.

### Requirements

* The latest [NVidia drivers from NVidia](https://www.nvidia.com/Download/index.aspx), _not_ the ones bundled with the running Linux Distribution, should be used.

* The [NVidia Container Toolkit](https://github.com/NVIDIA/nvidia-docker) must be installed. It's very important to restart the Docker daemon after installation as it updates the Docker configuration.


## QSV

This image builds `ffmpeg` with the [Intel Media SDK](https://github.com/Intel-Media-SDK/MediaSDK) to provide direct use of Intel's QSV system. That combined with VAAPI provides a high quality and performant transcode. Performance is very dependent on both clock speed and iGPU variant.

### Requirements

* The [i915](https://01.org/linuxgraphics/gfx-docs/drm/gpu/i915.html) kernel module must be loaded
* `/dev/dri` devices must be available. This is a typical default, since it's also a requirement for Intel systems without discrete video.

## SW

This image is for only using software encoding via `ffmpeg`. It is also the only image that attempts to provide both an Intel (`amd64`) and ARM (`arm64`) image, as there are no video hardware dependencies.

# Prebuilt Images

The base image version exactly tracks the `other-transcode` version. The `{version}` suffix can be replaced with `latest` to track the latest builds.

All images are hosted via GitHub Container Registry

* ghcr.io/ttys0/other-transcode:nvidia-{version}
* ghcr.io/ttys0/other-transcode:qsv-{version}
* ghcr.io/ttys0/other-transcode:sw-{version}


# Usage

The software inside the container needs to be able to both read and write to a location outside of itself. This means both an input and an output location must be specified. Since `other-transcode` writes to its working directory, it's important that you use a directory structure that provides a separation between the source material and the output. Alternatively, the paths can be specified as different bind mounts to the container.

## Single Bind Mount

To use a single bind mount, the easiest approach is to place the source files in a sub directory (`src` in this example) to the output. The the `/src/source_file.mkv` can be used at the input path, and the output will go into the root of the bind mount, or `$(pwd)`. 

```
\_src
  \_source_file.mkv
```

Using that setup, to transcode `source_file.mkv` with the default H264 encoding, some recommended Docker commands for the different images are listed below. For more options, see [Don's Documentation](https://github.com/donmelton/other_video_transcoding/wiki). The important thing to be aware of here is to make sure the tag name lines up with the hardware you're planning on using.

```shell
# Software Encoding H.264
docker run --rm -v $(pwd):$(pwd) -w $(pwd) \ 
  ghcr.io/ttys0/other-transcode:sw-latest --x264-cbr \
  src/source_file.mkv
  
# QSV Encoding H.264
docker run --rm --device /dev/dri:/dev/dri -v $(pwd):$(pwd) -w $(pwd) \
  ghcr.io/ttys0/other-transcode:qsv-latest \
  src/source_file.mkv

# NVidia Encoding HEVC
docker run --rm --gpus all -v $(pwd):$(pwd) -w $(pwd) \ 
  ghcr.io/ttys0/other-transcode:nvidia-latest --hevc \
  src/source_file.mkv
```

## Multiple Bind Mounts

There are many reasons why moving the source material into a sub directory might be non-optimal. An obvious one is the source is on a different filesystem, either block or network storage, than where the output is going. For this scenario, it's important to set the working directory to the bind mount location that is desinated as the output destination. As an example, lets assume the source material is on a network mounted volume at `/mnt/nas1/video/rips`, and the output is going into `/mnt/nas2/video/compressed`. The idea is there are two different mount points that are both network attached storage. One has the rips, and is maybe on a large slow NAS. The destination is maybe on a smaller, but faster NAS that's also running something like Plex, which will be the consumer for the transcoded files.

```shell
# Software Encoding H.264
docker run --rm -v /mnt/nas1/video/rips:/src -v /mnt/nas2/video/compressed:/out -w /out \
  ghcr.io/ttys0/other-transcode:sw-latest --x264-cbr  \
  /src/source_file.mkv

# QSV Encoding H.264
docker run --rm --device /dev/dri:/dev/dri \
  -v /mnt/nas1/video/rips:/src  -v /mnt/nas2/video/compressed:/out -w /out \
  ghcr.io/ttys0/other-transcode:qsv-latest \
  /src/source_file.mkv

# NVidia Encoding HEVC
docker run --rm --gpus all -v \
   -v /mnt/nas1/video/rips:/src  -v /mnt/nas2/video/compressed:/out -w /out \ 
  ghcr.io/ttys0/other-transcode:nvidia-latest --hevc \
  /src/source_file.mkv

```

# About

[Don Melton](http://donmelton.com/) of [Video Transcoding](https://github.com/donmelton/video_transcoding) fame has brought his expertise to hardware accelerated transcoding in the form of [Other Video Transcoding](https://github.com/donmelton/other_video_transcoding). While Don covers the installation and usage of `other-transcode` for all normal desktop platforms, this repository's focus is using `other-transcode` as a Docker container.

I have leaned _heavily_ on [Julien Rottenberg's](https://github.com/jrottenberg) [ffmpeg](https://github.com/jrottenberg/ffmpeg) Dockerfiles. 
