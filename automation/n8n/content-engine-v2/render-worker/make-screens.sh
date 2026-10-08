#!/usr/bin/env bash
# Builds the screen-clip library (render-worker/files/screens/*.mp4) from the
# approved CEFFLO product captures in website/img. Replace with real screen
# recordings of the production app when available.
set -euo pipefail
FF=${FFMPEG:-ffmpeg}; HERE=$(cd "$(dirname "$0")" && pwd); IMG="$HERE/../../../../website/img"; OUT="$HERE/files/screens"; mkdir -p "$OUT"
for pair in vendor_orders:s_v_orders vendor_zones:s_v_zones vendor_riders:s_v_drivers vendor_today:s_v_today driver_run:s_d_run \
            driver_stops:s_d_stops driver_pod:s_d_pod customer_tracking:s_c_done storefront:s_sf_warung; do
  n=${pair%%:*}; s=${pair##*:}
  "$FF" -y -loglevel error -loop 1 -i "$IMG/$s.webp" -t 6 -filter_complex \
    "color=c=0xF2F5FA:s=1080x1920:d=6[bg];[0:v]scale=900:-1,format=rgba[p];[bg][p]overlay=x=90:y='(1920-h)/2+40-t*12'" \
    -r 30 -c:v libx264 -pix_fmt yuv420p "$OUT/$n.mp4"
done
mkdir -p "$HERE/files/persona/kak_zee" && cp "$HERE/../persona/kak_zee/"[0-9]*.jpg "$HERE/files/persona/kak_zee/"
echo "screens: $(ls "$OUT" | wc -l)"
