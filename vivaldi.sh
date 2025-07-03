#!/usr/bin/bash

VIVALDI_VERSION_SHORT=7.5
FFMPEG_VERSIONS="120726"
FFMPEG_FOUND=NO
unset VIVALDI_FFMPEG_FUTURE_PATH

for FFMPEG_VERSION_CANDIDATE in $FFMPEG_VERSIONS; do
  if [ -e "$XDG_DATA_HOME/vivaldi-extra-libs/media-codecs-$FFMPEG_VERSION_CANDIDATE/libffmpeg.so" ]; then
    export LD_PRELOAD="$LD_PRELOAD${LD_PRELOAD:+:}$XDG_DATA_HOME/vivaldi-extra-libs/media-codecs-$FFMPEG_VERSION_CANDIDATE/libffmpeg.so"
    FFMPEG_FOUND=YES
    break
  fi
done
if [ "$FFMPEG_FOUND" = NO ]; then
  if [ -e "$XDG_DATA_HOME/vivaldi-update-ffmpeg-checked-$VIVALDI_VERSION_SHORT" ]; then
    echo "'Proprietary media' support is not installed. Attempting to fix this for the next restart." >&2
    export VIVALDI_FFMPEG_FUTURE_PATH="$XDG_DATA_HOME/vivaldi-extra-libs/media-codecs-$VIVALDI_VERSION_SHORT/libffmpeg.so"
    nohup sh -c "sleep 10; /app/vivaldi/update-ffmpeg --user" > /dev/null 2>&1 &
  else
    rm -f "$XDG_DATA_HOME/vivaldi-update-ffmpeg-checked-"*
    echo "'Proprietary media' support is not installed. Attempting to fix this now." >&2
    timeout 3s /app/vivaldi/update-ffmpeg --user 2> /dev/null
    if [ -e "$XDG_DATA_HOME/vivaldi-extra-libs/media-codecs-$VIVALDI_VERSION_SHORT/libffmpeg.so" ]; then
      export LD_PRELOAD="$LD_PRELOAD${LD_PRELOAD:+:}$XDG_DATA_HOME/vivaldi-extra-libs/media-codecs-$VIVALDI_VERSION_SHORT/libffmpeg.so"
    else
      export VIVALDI_FFMPEG_FUTURE_PATH="$XDG_DATA_HOME/vivaldi-extra-libs/media-codecs-$VIVALDI_VERSION_SHORT/libffmpeg.so"
      nohup sh -c "sleep 7; /app/vivaldi/update-ffmpeg --user" > /dev/null 2>&1 &
    fi
    rm -f "$XDG_DATA_HOME/vivaldi-update-ffmpeg-checked-"*
    mkdir -p "$XDG_DATA_HOME"
    touch "$XDG_DATA_HOME/vivaldi-update-ffmpeg-checked-$VIVALDI_VERSION_SHORT"
  fi
fi

if [ "$(uname -m)" = "aarch64" ]; then
  export LIBGL_DRIVERS_PATH=/usr/lib/aarch64-linux-gnu/GL/lib/dri
fi

exec cobalt "$@" --class=Vivaldi-flatpak --no-default-browser-check
