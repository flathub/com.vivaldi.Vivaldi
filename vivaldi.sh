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
## Check that /etc/os-release or fallback /usr/lib/os-release are present and readable
ID=''
VERSION_ID=''
OS_RELEASE_FILE=''
if [ -r /etc/os-release ]; then
  OS_RELEASE_FILE="/etc/os-release"
elif [ -r /usr/lib/os-release ]; then
  OS_RELEASE_FILE="/usr/lib/os-release"
fi

## Parse os-release line by line because sourcing it is problematic on some distros
if [ -n "$OS_RELEASE_FILE" ]; then
  while IFS='=' read -r key value; do
    case "$key" in
      ID) ID="${value%\"}"; ID="${ID#\"}" ;;
      VERSION_ID) VERSION_ID="${value%\"}"; VERSION_ID="${VERSION_ID#\"}" ;;
    esac
  done < "$OS_RELEASE_FILE"
fi

## In cases where $ID and $VERSION_ID are not set provide sensible defaults
[ -z "${ID:-}" ] && ID=linux
[ -z "${VERSION_ID:-}" ] && VERSION_ID="$(uname -r | tr -cd 'A-Za-z0-9._-' | tr 'A-Z' 'a-z')"

## Export these values with less generic names
export VIVALDI_DISTRO_NAME="$ID"
export VIVALDI_DISTRO_VERSION_NUMBER="$VERSION_ID"

exec cobalt "$@" --class=Vivaldi-flatpak --no-default-browser-check
