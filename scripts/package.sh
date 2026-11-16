#!/usr/bin/env bash
# Empaqueta dist/ en release/ como .tar.gz y .zip, con el número de versión
# de package.json, y genera las sumas SHA-256 para verificar la descarga.
set -euo pipefail

RAIZ="$(cd "$(dirname "$0")/.." && pwd)"
DIST="$RAIZ/dist"
REL="$RAIZ/release"
VERSION="$(node -p "require('$RAIZ/package.json').version")"
NOMBRE="perfil-esau-v$VERSION"

[ -f "$DIST/index.html" ] || { echo "No existe dist/: ejecuta 'npm run build' primero." >&2; exit 1; }

mkdir -p "$REL"
rm -f "$REL/$NOMBRE.tar.gz" "$REL/$NOMBRE.zip" "$REL/$NOMBRE.sha256"

echo "==> Empaquetando $NOMBRE"
tar -czf "$REL/$NOMBRE.tar.gz" -C "$DIST" .
(cd "$DIST" && zip -qr9 "$REL/$NOMBRE.zip" .)
(cd "$REL" && sha256sum "$NOMBRE.tar.gz" "$NOMBRE.zip" > "$NOMBRE.sha256")

echo
echo "==> Contenido del paquete"
tar -tzvf "$REL/$NOMBRE.tar.gz"
echo
ls -lh "$REL"
