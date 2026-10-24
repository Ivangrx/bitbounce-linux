#!/usr/bin/env bash
# Records docs/gameplay.gif (menu + OMARCHY level + live theme switches).
set -euo pipefail
root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$root"

GODOT_BIN="${GODOT:-}"
if [[ -z "$GODOT_BIN" ]] && command -v godot >/dev/null; then
  GODOT_BIN="$(command -v godot)"
fi
if [[ -z "$GODOT_BIN" ]]; then
  echo "Set GODOT to a Godot 4.5 binary." >&2
  exit 1
fi

frames="${GIF_FRAME_DIR:-/tmp/bitbounce-gif}"
rm -rf "$frames"
mkdir -p "$frames" docs
GIF_FRAME_DIR="$frames" BITBOUNCE_NO_OMARCHY=1 "$GODOT_BIN" --path "$root" res://tests/record_gif.tscn
ffmpeg -y -framerate 12 -i "$frames/frame_%04d.png" \
  -vf "scale=800:-1:flags=lanczos,split[s0][s1];[s0]palettegen=max_colors=96:stats_mode=diff[p];[s1][p]paletteuse=dither=bayer:bayer_scale=4" \
  docs/gameplay.gif
ls -lh docs/gameplay.gif
