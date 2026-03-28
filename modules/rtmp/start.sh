#!/usr/bin/env bash
set -euo pipefail

RED='\033[0;31m'
BLUE='\033[0;34m'; BOLD_BLUE='\033[1;34m'
GREEN='\033[0;32m'; YELLOW='\033[0;33m'; NC='\033[0m'

header() {
  echo -e "${BLUE}───────────────────────────────────────────────${NC}"
  echo -e "${BOLD_BLUE}$1${NC}"
}

is_enabled() { [[ "$1" =~ ^(true|1)$ ]]; }

RTMP_STATUS="${RTMP_STATUS:-0}"
RTMP_PORT="${RTMP_PORT:-1935}"
RTMP_APPLICATION="${RTMP_APPLICATION:-live}"
RTMP_HLS_PATH="${RTMP_HLS_PATH:-/home/container/www/hls}"
RTMP_HLS_FRAGMENT="${RTMP_HLS_FRAGMENT:-3}"
RTMP_HLS_PLAYLIST_LENGTH="${RTMP_HLS_PLAYLIST_LENGTH:-60}"
RTMP_RECORD="${RTMP_RECORD:-0}"

header "[RTMP] Preparing RTMP/HLS configuration"

mkdir -p /home/container/modules-enabled /home/container/nginx/rtmp-enabled "$RTMP_HLS_PATH" /home/container/logs /home/container/tmp /home/container/www

if ! is_enabled "$RTMP_STATUS"; then
  rm -f /home/container/modules-enabled/50-rtmp.conf /home/container/nginx/rtmp-enabled/rtmp.conf
  echo -e "${YELLOW}[RTMP] RTMP module disabled by RTMP_STATUS.${NC}"
  exit 0
fi

if [ ! -f /usr/lib/nginx/modules/ngx_rtmp_module.so ]; then
  echo -e "${RED}[RTMP] Missing /usr/lib/nginx/modules/ngx_rtmp_module.so.${NC}"
  echo -e "${RED}[RTMP] Build and use the Docker image from this repo first.${NC}"
  exit 1
fi

printf '%s\n' 'load_module /usr/lib/nginx/modules/ngx_rtmp_module.so;' > /home/container/modules-enabled/50-rtmp.conf

if is_enabled "$RTMP_RECORD"; then
  RECORD_DIRECTIVE='record all;'
else
  RECORD_DIRECTIVE='record off;'
fi

cat > /home/container/nginx/rtmp-enabled/rtmp.conf <<EORTMP
rtmp {
    server {
        listen ${RTMP_PORT};
        chunk_size 4096;

        application ${RTMP_APPLICATION} {
            live on;
            ${RECORD_DIRECTIVE}
            hls on;
            hls_path ${RTMP_HLS_PATH};
            hls_fragment ${RTMP_HLS_FRAGMENT};
            hls_playlist_length ${RTMP_HLS_PLAYLIST_LENGTH};
        }
    }
}
EORTMP

echo -e "${GREEN}[RTMP] RTMP enabled on port ${RTMP_PORT} using app ${RTMP_APPLICATION}.${NC}"
