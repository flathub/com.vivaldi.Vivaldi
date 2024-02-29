#!/usr/bin/bash

case $(uname -m) in
  x86_64)
    FFMPEG_VERSION=114023
    VIVALDI_MAJOR_MINOR=6.6
    if [ -e "$XDG_DATA_HOME/vivaldi-extra-libs/media-codecs-$FFMPEG_VERSION/libffmpeg.so" ]; then
      export ZYPAK_LD_PRELOAD="$ZYPAK_LD_PRELOAD${ZYPAK_LD_PRELOAD:+:}$XDG_DATA_HOME/vivaldi-extra-libs/media-codecs-$FFMPEG_VERSION/libffmpeg.so"
    else
      if [ -e "$XDG_DATA_HOME/vivaldi-update-ffmpeg-checked-$VIVALDI_MAJOR_MINOR" ]; then
        echo "'Proprietary media' support is not installed. Attempting to fix this for the next restart." >&2
        nohup "/app/vivaldi/update-ffmpeg" --user > /dev/null 2>&1 &
      else
        rm -f "$XDG_DATA_HOME/vivaldi-update-ffmpeg-checked-"*
        echo "'Proprietary media' support is not installed. Attempting to fix this now." >&2
        timeout 3s "/app/vivaldi/update-ffmpeg" --user
        if [ -e "$XDG_DATA_HOME/vivaldi-extra-libs/media-codecs-$FFMPEG_VERSION/libffmpeg.so" ]; then
          export ZYPAK_LD_PRELOAD="$ZYPAK_LD_PRELOAD${ZYPAK_LD_PRELOAD:+:}$XDG_DATA_HOME/vivaldi-extra-libs/media-codecs-$FFMPEG_VERSION/libffmpeg.so"
        else
          nohup "/app/vivaldi/update-ffmpeg" --user > /dev/null 2>&1 &
        fi
        touch "$XDG_DATA_HOME/vivaldi-update-ffmpeg-checked-$VIVALDI_MAJOR_MINOR"
      fi
    fi
    ;;
  aarch64)
    export LIBGL_DRIVERS_PATH=/usr/lib/aarch64-linux-gnu/GL/lib/dri
    ;;
esac

export VIVALDI_FFMPEG_FOUND=YES # Prevents excessive warning for flatpak users

exec cobalt "$@" --no-default-browser-check
