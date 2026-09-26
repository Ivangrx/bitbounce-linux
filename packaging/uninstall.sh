#!/usr/bin/env bash
# Removes a user install of Bitbounce. Pass --purge to also delete saves.
set -euo pipefail

data_home="${XDG_DATA_HOME:-$HOME/.local/share}"

rm -rf "$data_home/bitbounce/app"
rm -f "$HOME/.local/bin/bitbounce"
rm -f "$data_home/applications/bitbounce.desktop"
rm -f "$data_home/icons/hicolor/256x256/apps/bitbounce.png"

if [[ "${1:-}" == "--purge" ]]; then
  rm -rf "$data_home/bitbounce"
  echo "Bitbounce and its save data removed."
else
  rmdir "$data_home/bitbounce" 2>/dev/null || true
  echo "Bitbounce removed. Saves kept in $data_home/bitbounce (use --purge to delete)."
fi

command -v update-desktop-database >/dev/null && update-desktop-database -q "$data_home/applications" || true
