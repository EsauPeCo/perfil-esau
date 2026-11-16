# Perfil de Esaú Pérez

Página personal de presentación de José Esaú Pérez Coronel, estudiante de Ingeniería en Desarrollo de Software en la UVEG. Es un sitio estático (HTML, CSS y JavaScript sin frameworks) que se optimiza, se empaqueta y se despliega en un servidor **Nginx** para quedar accesible en:

```
http://localhost/perfil/
```

Proyecto realizado para el Reto 2 «Prepara y lanza tu aplicación web» del módulo Despliegue de aplicaciones web y móviles.

## Estructura

```
perfil-esau/
├── src/                  código fuente legible
│   ├── index.html
│   ├── css/              styles.css + tokens.css + base.css
│   ├── js/               main.js (filtro de proyectos, navegación activa)
│   └── img/              imágenes originales en PNG y favicon.svg
├── dist/                 versión optimizada que se sube al servidor
│   ├── index.html        (minificado)
│   ├── css/styles.min.css
│   ├── js/main.min.js
│   └── img/*.webp
├── scripts/
│   ├── build.sh          src/ -> dist/ (minificación y optimización)
│   ├── package.sh        dist/ -> release/*.tar.gz y *.zip
│   └── deploy.sh         release/ -> servidor/www/perfil + Nginx
├── nginx/perfil.conf     Server Block de Nginx
├── docker-compose.yml    entorno de simulación del servidor
└── package.json          versión y scripts de npm
```

## Requisitos

- Node.js 18 o superior y npm
- ImageMagick 7 (`magick`)
- Docker con Docker Compose (para el servidor Nginx)

## 1. Preparación: optimizar y minificar

```bash
npm install
npm run build
```

`scripts/build.sh` hace cuatro cosas:

1. **CSS:** esbuild une `styles.css` con sus `@import` y lo minifica en `dist/css/styles.min.css`.
2. **JS:** esbuild minifica `main.js` en `dist/js/main.min.js`.
3. **Imágenes:** ImageMagick reduce cada PNG a un máximo de 1600 px de ancho, borra los metadatos y lo convierte a WebP con calidad 80.
4. **HTML:** cambia las rutas a los archivos optimizados y lo minifica con html-minifier-terser.

Resultado de la versión 1.0.1:

| Archivo | Original | Optimizado | Ahorro |
| --- | ---: | ---: | ---: |
| CSS (styles + tokens + base) | 17 020 B | 13 900 B | 18.3 % |
| js/main.js | 2 919 B | 1 540 B | 47.2 % |
| index.html | 7 569 B | 6 392 B | 15.6 % |
| img/monolito-tonalli-render | 1 502 591 B | 11 436 B | 99.2 % |
| img/sol-obsidiana-hud | 353 945 B | 72 650 B | 79.5 % |
| img/sol-obsidiana-menu | 429 328 B | 92 046 B | 78.6 % |

El sitio completo pasó de unos 2.3 MB a 198 KB.

## 2. Empaquetado

```bash
npm run package
```

Genera en `release/` el paquete listo para subir al servidor, con la versión tomada de `package.json`:

- `perfil-esau-v1.0.1.tar.gz`
- `perfil-esau-v1.0.1.zip`
- `perfil-esau-v1.0.1.sha256` (sumas para verificar que el paquete llegó completo)

Los paquetes se publican como archivos de cada versión en [Releases](../../releases) del repositorio, por eso `release/` no se versiona.

## 3. Versionamiento

- Un commit por cada cambio, con el formato `tipo: descripción` (`feat`, `style`, `build`, `fix`, `docs`, `chore`, `assets`).
- La versión sigue el versionado semántico (`MAYOR.MENOR.PARCHE`) en `package.json`.
- Cada entrega se marca con una etiqueta anotada (`git tag -a v1.0.0`) y una *release* de GitHub que lleva los paquetes.

| Versión | Cambio |
| --- | --- |
| v1.0.0 | Primera versión: sitio optimizado, empaquetado y Server Block de Nginx |
| v1.0.1 | `deploy.sh` vacía la carpeta publicada en lugar de borrarla, para que el contenedor no pierda el montaje |

```bash
git log --oneline
git tag -n
```

## 4. Servidor web: Nginx

El servidor corre en un contenedor (`nginx:1.27.3-alpine`) como entorno de simulación.

```bash
npm run deploy
```

`scripts/deploy.sh` verifica la suma SHA-256 del paquete, lo descomprime en `servidor/www/perfil` (como si se subiera al servidor), valida la configuración con `nginx -t` y levanta el contenedor.

### Puertos

| Dónde | Puerto |
| --- | --- |
| Nginx dentro del contenedor (`listen 80;` y `listen [::]:80;`) | 80 |
| Equipo anfitrión, solo en 127.0.0.1 (`ports: "127.0.0.1:80:80"` en docker-compose.yml) | 80 |

El puerto se publica solo en la interfaz local (127.0.0.1), así que el sitio no es accesible desde otros equipos de la red.

### Mapeo de directorios

| Equipo | Contenedor | Uso |
| --- | --- | --- |
| `nginx/perfil.conf` | `/etc/nginx/conf.d/default.conf` | Server Block |
| `servidor/www/perfil/` | `/var/www/sitios/perfil/` | archivos del sitio |

Con `root /var/www/sitios;` Nginx añade la ruta pedida al directorio raíz:

| URL | Archivo |
| --- | --- |
| `http://localhost/perfil/` | `/var/www/sitios/perfil/index.html` |
| `http://localhost/perfil/css/styles.min.css` | `/var/www/sitios/perfil/css/styles.min.css` |
| `http://localhost/perfil` | redirección 301 a `/perfil/` |
| `http://localhost/` | redirección 302 a `/perfil/` |

Además, el Server Block comprime con gzip el CSS, el JS y el SVG, y pide al navegador guardar en caché los recursos estáticos por 30 días.

### Comprobación

```bash
curl -I http://localhost/perfil/
docker compose logs nginx
docker compose down        # detener el servidor
```

## Licencia

Código bajo licencia MIT. Las imágenes de Sol de Obsidiana son trabajo original del autor.
