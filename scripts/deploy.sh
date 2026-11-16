#!/usr/bin/env bash
# Simula la subida al servidor: descomprime el paquete en el directorio que
# Nginx sirve (servidor/www/perfil) y levanta el contenedor de Nginx.
set -euo pipefail

RAIZ="$(cd "$(dirname "$0")/.." && pwd)"
VERSION="$(node -p "require('$RAIZ/package.json').version")"
PAQUETE="$RAIZ/release/perfil-esau-v$VERSION.tar.gz"
DESTINO="$RAIZ/servidor/www/perfil"

[ -f "$PAQUETE" ] || { echo "No existe $PAQUETE: ejecuta 'npm run release' primero." >&2; exit 1; }

echo "==> Verificando la suma SHA-256 del paquete"
(cd "$RAIZ/release" && sha256sum -c --ignore-missing "perfil-esau-v$VERSION.sha256")

echo "==> Publicando v$VERSION en $DESTINO"
# Se vacía el contenido sin borrar la carpeta: Docker monta la carpeta por su
# inodo, y si se borra y se vuelve a crear, el contenedor sigue viendo la vieja
# (vacía) y Nginx responde 403/404.
mkdir -p "$DESTINO"
find "$DESTINO" -mindepth 1 -delete
tar -xzf "$PAQUETE" -C "$DESTINO"

echo "==> Validando la configuración y levantando Nginx"
docker compose -f "$RAIZ/docker-compose.yml" run --rm --no-deps nginx nginx -t
docker compose -f "$RAIZ/docker-compose.yml" up -d
docker compose -f "$RAIZ/docker-compose.yml" ps

echo
echo "Sitio disponible en http://localhost/perfil/"
