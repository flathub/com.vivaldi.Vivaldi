#!/usr/bin/bash

FFMPEG_VERSION=114023
if [ -e "$XDG_DATA_HOME/vivaldi-extra-libs/media-codecs-$FFMPEG_VERSION/libffmpeg.so" ]; then
  export ZYPAK_LD_PRELOAD="$ZYPAK_LD_PRELOAD${ZYPAK_LD_PRELOAD:+:}$XDG_DATA_HOME/vivaldi-extra-libs/media-codecs-$FFMPEG_VERSION/libffmpeg.so"
fi

case $(uname -m) in
  x86_64)
    if [ ! -e "$XDG_DATA_HOME/vivaldi-extra-libs/media-codecs-$FFMPEG_VERSION/libffmpeg.so" ]; then
      if [ -e "$XDG_DATA_HOME/vivaldi-update-ffmpeg-checked-$FFMPEG_VERSION" ]; then
        echo "'Proprietary media' support is not installed. Attempting to fix this for the next restart." >&2
        nohup "/app/vivaldi/update-ffmpeg" --user > /dev/null 2>&1 &
      else
        echo "'Proprietary media' support is not installed. Attempting to fix this now." >&2
        timeout 3s "/app/vivaldi/update-ffmpeg" --user > /dev/null 2>&1
        if [ -e "$XDG_DATA_HOME/vivaldi-extra-libs/media-codecs-$FFMPEG_VERSION/libffmpeg.so" ]; then
          export ZYPAK_LD_PRELOAD="$ZYPAK_LD_PRELOAD${ZYPAK_LD_PRELOAD:+:}$XDG_DATA_HOME/vivaldi-extra-libs/media-codecs-$FFMPEG_VERSION/libffmpeg.so"
        else
          nohup "/app/vivaldi/update-ffmpeg" --user > /dev/null 2>&1 &
        fi
        rm -f "$XDG_DATA_HOME/vivaldi-update-ffmpeg-checked-"*
        touch "$XDG_DATA_HOME/vivaldi-update-ffmpeg-checked-$FFMPEG_VERSION"
      fi
    fi
    ;;
  aarch64)
    export LIBGL_DRIVERS_PATH=/usr/lib/aarch64-linux-gnu/GL/lib/dri
    ;;
esac

export VIVALDI_FFMPEG_FOUND=YES # Prevents excessive warning for flatpak users

exec cobalt "$@" --no-default-browser-check
