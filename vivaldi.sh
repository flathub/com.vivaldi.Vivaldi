#!/usr/bin/bash

# Setup an alternative libffmpeg to handle a wider variety of media
VIVALDI_VERSION_SHORT=8.2
FFMPEG_VERSIONS="8.2-152-Z-20260911b"
FFMPEG_FOUND=NO
if [ ! -e "$XDG_DATA_HOME/vivaldi-update-ffmpeg-checked-$VIVALDI_VERSION_SHORT" ]; then
  # This clears any old versions
  rm -f "$XDG_DATA_HOME/vivaldi-update-ffmpeg-checked-"*
  # This will be very fast if the latest version is already present
  timeout 3s /app/vivaldi/update-ffmpeg --user 2> /dev/null
  mkdir -p "$XDG_DATA_HOME"
  touch "$XDG_DATA_HOME/vivaldi-update-ffmpeg-checked-$VIVALDI_VERSION_SHORT"
fi
for FFMPEG_VERSION_CANDIDATE in $FFMPEG_VERSIONS; do
  if [ -e "$XDG_DATA_HOME/vivaldi-extra-libs/media-codecs-$FFMPEG_VERSION_CANDIDATE/libffmpeg.so" ]; then
    export LD_PRELOAD="$LD_PRELOAD${LD_PRELOAD:+:}$XDG_DATA_HOME/vivaldi-extra-libs/media-codecs-$FFMPEG_VERSION_CANDIDATE/libffmpeg.so"
    FFMPEG_FOUND=YES
    break
  fi
done
# Prepare alternative libffmpeg for next restart
[ "$FFMPEG_FOUND" = NO ] && nohup /app/vivaldi/update-ffmpeg --user >/dev/null 2>&1 &

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

## Parse os-release line by line because sourcing it directly is problematic on some distros
if [ -n "$OS_RELEASE_FILE" ]; then
  while IFS='=' read -r osreleasekey osreleasevalue; do
    case "$osreleasekey" in
      ''|'#'*)
        continue
        ;;
      ID)
        # Strip any quoting of variables
        ID="${osreleasevalue%\"}"
        ID="${ID#\"}"
        ID="${ID%\'}"
        ID="${ID#\'}"
        ;;
      VERSION_ID)
        VERSION_ID="${osreleasevalue%\"}"
        VERSION_ID="${VERSION_ID#\"}"
        VERSION_ID="${VERSION_ID%\'}"
        VERSION_ID="${VERSION_ID#\'}"
        ;;
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
