# Despliegue en EasyPanel (Flutter Web PWA)

Pasos para desplegar la carpeta `frondend/` como PWA en EasyPanel usando Docker:

1. Preparar el repositorio
   - Subir (o tener) la carpeta `frondend/` en el repositorio raíz.

2. Archivos incluidos
   - `frondend/Dockerfile` — Docker multi-stage que construye la web y la sirve con Nginx.
   - `frondend/nginx.conf` — configuración de Nginx optimizada para SPA/PWA.
   - `frondend/.dockerignore` — reduce el contexto de build.

3. Variables/puertos en EasyPanel
   - Puerto del contenedor: `80` (exponer en panel como puerto interno 80).
   - No se requieren variables de entorno para el build web en este Dockerfile.

4. Si necesitas apuntar la app a un backend diferente
   - Para compilar con una URL de API distinta, usa `--dart-define` en la etapa de build:

```
flutter build web --release --dart-define=API_BASE_URL=https://api.midominio.com
```

Para usar esto en EasyPanel, modifica el `Dockerfile` build step o exporta `FLUTTER_BUILD_ARGS` y adapta el `Dockerfile`.

5. Deploy desde EasyPanel (Deploy from Git)
   - Crea un nuevo servicio: Deploy → From Git.
   - Selecciona el repo y la rama que contiene `frondend/`.
   - Establece el Build Context (Path) en `/frondend` (importante).
   - El `Dockerfile` por defecto en esa carpeta será usado.
   - Puerto interno: `80`.

6. Dominio y HTTPS
   - Asigna un dominio desde EasyPanel y habilita HTTPS con el botón (Let's Encrypt).

7. Rebuild / Rollback
   - Para forzar rebuild, usa "Redeploy" o cambia la variable/commit.

8. Verificar imágenes en producción
   - Abre la PWA en el navegador (https://tu-dominio).
   - Abre DevTools → Network y verifica las URLs de imágenes.
   - Si las URLs para imágenes son relativas (empiezan con `/uploads/...`) deben apuntar al backend. Si la PWA está en un dominio distinto, las imágenes podrían fallar (404).

9. Corrección aplicada en el cliente (Flutter)
   - Se normalizan las URLs: si la URL de imagen es relativa (por ejemplo `/uploads/..`), la app la convertirá a absoluta usando `ApiConfig.baseUrl`.
   - Esto permite que las imágenes subidas por el backend (que devuelven rutas relativas) se muestren correctamente en la PWA aun cuando frontend y backend estén en dominios distintos.

10. Probar localmente

Construir y ejecutar localmente con Docker (desde la carpeta `frondend/`):

```
docker build -t fulltech-pwa .
docker run -p 8080:80 fulltech-pwa

# Abrir http://localhost:8080
```

11. Logs y debugging
   - EasyPanel muestra logs del contenedor; revisar `nginx` y salida del contenedor.
   - Si las imágenes siguen fallando, comprobar en DevTools si son 404 o bloqueadas por CORS.

12. Notas finales y recomendaciones
   - Es recomendable usar almacenamiento remoto (Cloud R2 / S3) con `R2_PUBLIC_URL` / `STORAGE_PUBLIC_URL` configurado en el backend para que el backend devuelva URLs absolutas.
   - Si prefieres, el backend puede devolver siempre URLs absolutas (más robusto).
