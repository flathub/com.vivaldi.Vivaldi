#!/usr/bin/bash

FFMPEG_VERSION=118356 # Chromium 131
FFMPEG_FOUND=NO
for FFMPEG_VERSION_CANDIDATE in 115541 "$FFMPEG_VERSION"; do
  if [ -e "$XDG_DATA_HOME/vivaldi-extra-libs/media-codecs-$FFMPEG_VERSION_CANDIDATE/libffmpeg.so" ]; then
    export LD_PRELOAD="$LD_PRELOAD${LD_PRELOAD:+:}$XDG_DATA_HOME/vivaldi-extra-libs/media-codecs-$FFMPEG_VERSION_CANDIDATE/libffmpeg.so"
    FFMPEG_FOUND=YES
    break
  fi
done
if [ "$FFMPEG_FOUND" = NO ]; then
  if [ -e "$XDG_DATA_HOME/vivaldi-update-ffmpeg-checked-$FFMPEG_VERSION" ]; then
    echo "'Proprietary media' support is not installed. Attempting to fix this for the next restart." >&2
    export VIVALDI_FFMPEG_FUTURE_PATH="$XDG_DATA_HOME/vivaldi-extra-libs/media-codecs-$FFMPEG_VERSION/libffmpeg.so"
    nohup sh -c "sleep 10; /app/vivaldi/update-ffmpeg --user" > /dev/null 2>&1 &
  else
    echo "'Proprietary media' support is not installed. Attempting to fix this now." >&2
    timeout 3s /app/vivaldi/update-ffmpeg --user 2> /dev/null
    if [ -e "$XDG_DATA_HOME/vivaldi-extra-libs/media-codecs-$FFMPEG_VERSION/libffmpeg.so" ]; then
      export LD_PRELOAD="$LD_PRELOAD${LD_PRELOAD:+:}$XDG_DATA_HOME/vivaldi-extra-libs/media-codecs-$FFMPEG_VERSION/libffmpeg.so"
    else
      export VIVALDI_FFMPEG_FUTURE_PATH="$XDG_DATA_HOME/vivaldi-extra-libs/media-codecs-$FFMPEG_VERSION/libffmpeg.so"
      nohup sh -c "sleep 7; /app/vivaldi/update-ffmpeg --user" > /dev/null 2>&1 &
    fi
    rm -f "$XDG_DATA_HOME/vivaldi-update-ffmpeg-checked-"*
    touch "$XDG_DATA_HOME/vivaldi-update-ffmpeg-checked-$FFMPEG_VERSION"
  fi
fi

if [ "$(uname -m)" = "aarch64" ]; then
  export LIBGL_DRIVERS_PATH=/usr/lib/aarch64-linux-gnu/GL/lib/dri
fi

exec cobalt "$@" --class=Vivaldi-flatpak --no-default-browser-check
