#!/bin/bash
# Creates ping-pong (forward+reverse) versions of all test videos.
# Usage: ./create_ping_pong_videos.sh

VDIR="$(dirname "$0")/static/videos"

for f in "$VDIR"/test_*[0-9].mp4; do
  [ -f "$f" ] || continue
  base=$(basename "$f" .mp4)
  out="$VDIR/${base}_ping_pong.mp4"

  if [ -f "$out" ]; then
    echo "Skipping (already exists): ${base}_ping_pong.mp4"
    continue
  fi

  echo "Creating: ${base}_ping_pong.mp4"
  ffmpeg -y -i "$f" -vf reverse -an "/tmp/${base}_rev.mp4" 2>/dev/null
  ffmpeg -y -i "$f" -i "/tmp/${base}_rev.mp4" \
    -filter_complex "[0:v][1:v]concat=n=2:v=1:a=0[v]" \
    -map "[v]" -an "$out" 2>/dev/null
  rm -f "/tmp/${base}_rev.mp4"
done

echo "Done."
