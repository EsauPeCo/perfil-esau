#!/usr/bin/env bash
# Genera la versión optimizada del sitio en dist/:
#   1. CSS: une styles.css con sus @import (tokens y base) y lo minifica.
#   2. JS: minifica main.js.
#   3. Imágenes: redimensiona a 1600 px de ancho máximo y convierte PNG a WebP.
#   4. HTML: apunta a los archivos optimizados y lo minifica.
set -euo pipefail

RAIZ="$(cd "$(dirname "$0")/.." && pwd)"
SRC="$RAIZ/src"
DIST="$RAIZ/dist"
BIN="$RAIZ/node_modules/.bin"

if [ ! -x "$BIN/esbuild" ]; then
  echo "Faltan dependencias: ejecuta 'npm install' primero." >&2
  exit 1
fi
command -v magick >/dev/null || { echo "Se necesita ImageMagick (magick)." >&2; exit 1; }

echo "==> Limpiando dist/"
rm -rf "$DIST"
mkdir -p "$DIST/css" "$DIST/js" "$DIST/img"

echo "==> CSS: uniendo y minificando"
"$BIN/esbuild" "$SRC/css/styles.css" --bundle --minify --log-level=warning \
  --outfile="$DIST/css/styles.min.css"

echo "==> JS: minificando"
"$BIN/esbuild" "$SRC/js/main.js" --minify --target=es2019 --log-level=warning \
  --outfile="$DIST/js/main.min.js"

echo "==> Imágenes: PNG -> WebP (máx. 1600 px, calidad 80, sin metadatos)"
for png in "$SRC"/img/*.png; do
  nombre="$(basename "$png" .png)"
  magick "$png" -resize '1600x>' -strip -quality 80 -define webp:method=6 "$DIST/img/$nombre.webp"
done
cp "$SRC/img/favicon.svg" "$DIST/img/favicon.svg"

echo "==> HTML: rutas a los archivos optimizados y minificado"
sed -e 's#css/styles\.css#css/styles.min.css#' \
    -e 's#js/main\.js#js/main.min.js#' \
    -e 's#\(img/[a-z0-9-]*\)\.png#\1.webp#g' \
    "$SRC/index.html" > "$DIST/index.tmp.html"
"$BIN/html-minifier-terser" "$DIST/index.tmp.html" \
  --collapse-whitespace --remove-comments --remove-redundant-attributes \
  --remove-script-type-attributes --use-short-doctype --minify-css true --minify-js true \
  -o "$DIST/index.html"
rm "$DIST/index.tmp.html"

echo
echo "==> Comparativa de peso (original -> optimizado)"
tamano() { stat -c %s "$1"; }
reporta() {
  printf '  %-30s %9s B -> %8s B   -%s%%\n' "$1" "$2" "$3" "$(awk -v a="$2" -v b="$3" 'BEGIN { printf "%.1f", (1 - b / a) * 100 }')"
}
css_src=$(( $(tamano "$SRC/css/styles.css") + $(tamano "$SRC/css/tokens.css") + $(tamano "$SRC/css/base.css") ))
reporta "css (styles+tokens+base)" "$css_src" "$(tamano "$DIST/css/styles.min.css")"
reporta "js/main.js" "$(tamano "$SRC/js/main.js")" "$(tamano "$DIST/js/main.min.js")"
reporta "index.html" "$(tamano "$SRC/index.html")" "$(tamano "$DIST/index.html")"
for png in "$SRC"/img/*.png; do
  nombre="$(basename "$png" .png)"
  reporta "img/$nombre" "$(tamano "$png")" "$(tamano "$DIST/img/$nombre.webp")"
done
echo
echo "Listo: versión optimizada en dist/"
