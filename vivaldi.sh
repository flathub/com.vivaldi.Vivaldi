#!/usr/bin/bash

VIVALDI_VERSION_SHORT=7.6
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

# Detect distro and distro version and export as $DISTRO_NAME $DISTRO_VERSION_NUMBER

# Cleanup in case the user exported these variable names already (since they are quite generic in their naming)
unset ID
unset VERSION_ID

# Source the system file os-release, which should correctly set $ID and $VERSION_ID
if [ -r /etc/os-release ]; then
  . /etc/os-release
elif [ -r /usr/lib/os-release ]; then
  . /usr/lib/os-release
fi

# In cases where $ID and $VERSION_ID are not set provide sensible defaults
[ -z "${ID:-}" ] && ID=linux
[ -z "${VERSION_ID:-}" ] && VERSION_ID="$(uname -r | tr -cd '[:alnum:]._-')"

# Export these values with less generic names
export VIVALDI_DISTRO_NAME="$ID"
export VIVALDI_DISTRO_VERSION_NUMBER="$VERSION_ID"

exec cobalt "$@" --class=Vivaldi-flatpak --no-default-browser-check
