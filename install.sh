#!/bin/sh
# Instala la última versión de Mote en /Applications (o ~/Applications si no se puede escribir ahí).
# Descarga con curl, que no marca el archivo con cuarentena: macOS no lo trata como una descarga de navegador
# y no muestra el aviso de «Apple no pudo verificar…» de las apps sin notarizar.
# MOTE_DEST cambia el destino y MOTE_NO_OPEN=1 evita abrir la app (pruebas).
set -eu

[ "$(uname -m)" = arm64 ] || { echo "Mote solo funciona en Macs con Apple Silicon." >&2; exit 1; }

TMP=$(mktemp -d)
MNT=$TMP/mnt
trap 'hdiutil detach -quiet "$MNT" 2>/dev/null || true; rm -rf "$TMP"' EXIT INT TERM

echo "Descargando Mote…"
curl -fL --progress-bar -o "$TMP/Mote.dmg" https://github.com/Andss-ye/mote-releases/releases/latest/download/Mote.dmg
mkdir "$MNT"
hdiutil attach -quiet -nobrowse -readonly -mountpoint "$MNT" "$TMP/Mote.dmg" </dev/null

min=$(/usr/libexec/PlistBuddy -c "Print :LSMinimumSystemVersion" "$MNT/Mote.app/Contents/Info.plist")
if [ "$(printf '%s\n%s\n' "$min" "$(sw_vers -productVersion)" | sort -V | head -n 1)" != "$min" ]; then
  echo "Mote necesita macOS $min o posterior." >&2
  exit 1
fi

DEST=${MOTE_DEST:-/Applications}
if [ ! -w "$DEST" ]; then
  DEST=$HOME/Applications
  mkdir -p "$DEST"
fi

pkill -x Mote 2>/dev/null || true
rm -rf "$DEST/Mote.app"
ditto "$MNT/Mote.app" "$DEST/Mote.app"
xattr -dr com.apple.quarantine "$DEST/Mote.app" 2>/dev/null || true
echo "Mote instalada en $DEST"
[ "${MOTE_NO_OPEN:-}" = 1 ] || open "$DEST/Mote.app"
