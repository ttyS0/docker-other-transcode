#!/usr/bin/bash

SRC_PATH="src/${POD_NAME:9:1}"

find ${SRC_PATH} -type f -name "*.mkv" -print0 | while IFS= read -r -d '' FILE; do

  CODEC=$(/usr/local/bin/ffprobe -v error -select_streams v:0 -show_entries stream=codec_name -of default=noprint_wrappers=1:nokey=1 "${FILE}")

  if [ "${CODEC}" = "vc1" ]; then
    /usr/local/bin/other-transcode --eac3 --pass-dts --main-audio 1=stereo --add-subtitle auto --burn-subtitle auto --preset veryslow "${FILE}" < /dev/null
  else
    /usr/local/bin/other-transcode --decode all --qsv-decoder --eac3 --pass-dts --main-audio 1=stereo --add-subtitle auto --burn-subtitle auto --preset veryslow "${FILE}" < /dev/null
  fi

  if [ ! -f "${FILE##*/}.log" ]; then
    echo "Something BAD happened! EXITING!"
    exit 1
  else
    rm -fv "${FILE}"
  fi

done


