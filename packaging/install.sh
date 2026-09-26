#!/usr/bin/env bash
# Installs Bitbounce for the current user (no root needed).
# Works from an extracted release tarball or from a repo checkout after ./packaging/build.sh.
set -euo pipefail

here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

binary=""
for candidate in "$here/bitbounce.x86_64" "$here/../build/linux/bitbounce.x86_64"; do
  if [[ -f "$candidate" ]]; then
    binary="$candidate"
    break
  fi
done
if [[ -z "$binary" ]]; then
  echo "bitbounce.x86_64 not found. Download a release or run ./packaging/build.sh first." >&2
  exit 1
fi

data_home="${XDG_DATA_HOME:-$HOME/.local/share}"
app_dir="$data_home/bitbounce/app"
bin_dir="$HOME/.local/bin"
apps_dir="$data_home/applications"
icon_dir="$data_home/icons/hicolor/256x256/apps"

mkdir -p "$app_dir" "$bin_dir" "$apps_dir" "$icon_dir"

install -m 755 "$binary" "$app_dir/bitbounce.x86_64"
ln -sf "$app_dir/bitbounce.x86_64" "$bin_dir/bitbounce"
install -m 644 "$here/bitbounce.png" "$icon_dir/bitbounce.png"
sed "s|^Exec=.*|Exec=$app_dir/bitbounce.x86_64|" "$here/bitbounce.desktop" > "$apps_dir/bitbounce.desktop"

command -v update-desktop-database >/dev/null && update-desktop-database -q "$apps_dir" || true
command -v gtk-update-icon-cache >/dev/null && gtk-update-icon-cache -q -t "$data_home/icons/hicolor" || true

echo "Bitbounce installed."
echo "  launch: bitbounce  (or search \"Bitbounce\" in your app launcher)"
case ":$PATH:" in
  *":$bin_dir:"*) ;;
  *) echo "  note: $bin_dir is not in your PATH" ;;
esac
