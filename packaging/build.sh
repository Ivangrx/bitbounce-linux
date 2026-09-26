#!/usr/bin/env bash
# Builds the Linux release binary and tarball.
#   ./packaging/build.sh            export + package
#   ./packaging/build.sh --test     run headless tests only
# Uses $GODOT if set, otherwise `godot` on PATH, otherwise downloads Godot into tools/.
set -euo pipefail

GODOT_VERSION="4.5.1"
GODOT_TAG="${GODOT_VERSION}-stable"
root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$root"

version="${BITBOUNCE_VERSION:-$(git describe --tags --always 2>/dev/null || echo dev)}"
version="${version#v}"

find_godot() {
  if [[ -n "${GODOT:-}" ]]; then
    echo "$GODOT"
  elif [[ -x "tools/godot/Godot_v${GODOT_TAG}_linux.x86_64" ]]; then
    echo "$root/tools/godot/Godot_v${GODOT_TAG}_linux.x86_64"
  elif command -v godot >/dev/null && godot --version 2>/dev/null | grep -q "^${GODOT_VERSION}"; then
    command -v godot
  else
    echo "Downloading Godot ${GODOT_TAG}..." >&2
    mkdir -p tools/godot
    curl -fsSL -o /tmp/godot.zip \
      "https://github.com/godotengine/godot/releases/download/${GODOT_TAG}/Godot_v${GODOT_TAG}_linux.x86_64.zip"
    unzip -oq /tmp/godot.zip -d tools/godot
    rm /tmp/godot.zip
    echo "$root/tools/godot/Godot_v${GODOT_TAG}_linux.x86_64"
  fi
}

ensure_templates() {
  local dir="${XDG_DATA_HOME:-$HOME/.local/share}/godot/export_templates/${GODOT_VERSION}.stable"
  [[ -f "$dir/linux_release.x86_64" ]] && return
  echo "Downloading Godot export templates..." >&2
  mkdir -p "$dir"
  curl -fsSL -o /tmp/templates.tpz \
    "https://github.com/godotengine/godot/releases/download/${GODOT_TAG}/Godot_v${GODOT_TAG}_export_templates.tpz"
  unzip -oq -j /tmp/templates.tpz \
    templates/linux_release.x86_64 templates/linux_debug.x86_64 templates/version.txt -d "$dir"
  rm /tmp/templates.tpz
}

godot_bin="$(find_godot)"

# First run imports assets so scripts/resources resolve.
"$godot_bin" --headless --path . --import >/dev/null 2>&1 || true

run_tests() {
  "$godot_bin" --headless --path . -s tests/smoke_test.gd 2>&1 | tee /tmp/bitbounce-smoke.log
  grep -q SMOKE_OK /tmp/bitbounce-smoke.log
  "$godot_bin" --headless --path . res://tests/auto_playtest.tscn 2>&1 | tee /tmp/bitbounce-auto.log
  grep -q AUTO_OK /tmp/bitbounce-auto.log
}

if [[ "${1:-}" == "--test" ]]; then
  run_tests
  exit 0
fi

ensure_templates
mkdir -p build/linux
"$godot_bin" --headless --path . --export-release Linux build/linux/bitbounce.x86_64
[[ -f build/linux/bitbounce.x86_64 ]]

tarball="bitbounce-linux-x86_64.tar.gz"
stage="build/bitbounce"
rm -rf "$stage"
mkdir -p "$stage"
cp build/linux/bitbounce.x86_64 "$stage/"
cp packaging/bitbounce.desktop packaging/bitbounce.png packaging/install.sh packaging/uninstall.sh "$stage/"
cp LICENSE README.md CREDITS.md "$stage/"
echo "$version" > "$stage/VERSION"
tar -C build -czf "build/$tarball" bitbounce
(cd build && sha256sum "$tarball" > "$tarball.sha256")
echo "Built build/$tarball (version $version)"
