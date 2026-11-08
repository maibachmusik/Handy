#!/usr/bin/env bash
# Install this fork for the current user on Linux (used on Mike's M2, Asahi aarch64), no root needed.
# Run after `bun install && bunx tauri build --bundles appimage` (the bundle step may fail at linuxdeploy on
# aarch64 — that's fine: the AppDir it assembles first is all this needs).
#
# Layout (Tauri finds resources at <exe>/../lib/Handy on Linux):
#   ~/.local/lib/handy-maibach/bin/handy         the app
#   ~/.local/lib/handy-maibach/lib/Handy/...     its resources (icons, sounds, default settings)
#   ~/.local/lib/handy-maibach/lib/*.so*         the speech engine libraries (libtranscribe, ggml)
#   ~/.local/bin/handy-maibach                   launcher (sets LD_LIBRARY_PATH); point autostart here
set -euo pipefail
here=$(cd "$(dirname "$0")/.." && pwd)
rel=$here/src-tauri/target/release
appdir=$rel/bundle/appimage/Handy.AppDir/usr
dest=$HOME/.local/lib/handy-maibach
libdir=$(dirname "$(find "$rel/build" -path '*transcribe-cpp-sys*/out/lib/libtranscribe.so.0.4' | head -1)")

[ -x "$rel/handy" ] || { echo "no release build at $rel/handy"; exit 1; }
[ -d "$appdir/lib/Handy" ] || { echo "no AppDir resources at $appdir/lib/Handy (run the appimage bundle step)"; exit 1; }
[ -d "$libdir" ] || { echo "speech libraries not found under $rel/build"; exit 1; }

mkdir -p "$dest/bin" "$dest/lib" "$HOME/.local/bin"
cp "$rel/handy" "$dest/bin/handy"
cp -a "$appdir/lib/Handy" "$dest/lib/"
cp -a "$libdir"/*.so* "$dest/lib/"

launcher=$HOME/.local/bin/handy-maibach
tmp=$(mktemp "$launcher.XXXXXX")
cat > "$tmp" <<EOF
#!/bin/sh
# Mike's Handy fork (maibachmusik/Handy)
export LD_LIBRARY_PATH=$dest/lib\${LD_LIBRARY_PATH:+:\$LD_LIBRARY_PATH}
exec $dest/bin/handy "\$@"
EOF
chmod +x "$tmp"
mv "$tmp" "$launcher"

missing=$(LD_LIBRARY_PATH=$dest/lib ldd "$dest/bin/handy" | grep -c "not found" || true)
echo "installed to $dest (unresolved libraries: $missing); launcher: $launcher"
echo "autostart: set Exec=$launcher in ~/.config/autostart/Handy.desktop"
