#!/usr/bin/env bash
set -euo pipefail

VERSION="${1:-0.1.0}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(dirname "$(dirname "$SCRIPT_DIR")")"
BUILD_DIR="$(mktemp -d)"
trap 'rm -rf "$BUILD_DIR"' EXIT
PKG_DIR="$BUILD_DIR/gpger"

mkdir -p "$PKG_DIR/DEBIAN"
mkdir -p "$PKG_DIR/usr/lib/gpger/bin"
mkdir -p "$PKG_DIR/usr/lib/gpger/config"
mkdir -p "$PKG_DIR/usr/bin"

cp "$REPO_ROOT/bin/gpger" "$PKG_DIR/usr/lib/gpger/bin/gpger"
chmod 755 "$PKG_DIR/usr/lib/gpger/bin/gpger"

cp "$REPO_ROOT/config/config.default.yaml" "$PKG_DIR/usr/lib/gpger/config/config.default.yaml"
chmod 644 "$PKG_DIR/usr/lib/gpger/config/config.default.yaml"

ln -s ../lib/gpger/bin/gpger "$PKG_DIR/usr/bin/gpger"

sed "s/^Version:.*/Version: $VERSION/" "$SCRIPT_DIR/control" > "$PKG_DIR/DEBIAN/control"

OUT="$SCRIPT_DIR/gpger_${VERSION}_all.deb"
dpkg-deb --build --root-owner-group "$PKG_DIR" "$OUT"

echo "빌드 완료: $OUT"
