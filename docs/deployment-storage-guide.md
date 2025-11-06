# Opciones de despliegue y almacenamiento

Esta guía resume los escenarios de despliegue para la plataforma, describe cómo operar con almacenamiento local en el servidor y provee archivos `docker-compose` específicos para esa modalidad. También incluye una estimación orientativa de recursos para un VPS.

## 1. Elección de hosting

La aplicación no es un sitio estático: expone una API NestJS (Node.js 20+), depende de PostgreSQL, genera un frontend Flutter Web y utiliza servicios auxiliares como correo SMTP y almacenamiento de archivos. Para conservar control sobre versiones y servicios conviene optar por:

- **VPS o IaaS (EC2, Droplets, Compute Engine, etc.)** con acceso root: permite instalar Docker, definir versiones de Node/PostgreSQL y adjuntar almacenamiento local o discos adicionales.
- **Plataformas de contenedores** (ECS, Cloud Run, Fly.io, Railway, Render, etc.) que acepten imágenes personalizadas y ofrezcan bases de datos/almacenamiento gestionado.

Los hostings “compartidos” tradicionales rara vez permiten ejecutar contenedores, procesos Node dedicados o servicios auxiliares, por lo que resultan inadecuados.

### Componentes a provisionar en un VPS

1. **API (NestJS)**: contenedor o proceso Node.js 20 ejecutando `dist/main.js`.
2. **Base de datos**: PostgreSQL 15+ (puede ser administrada externamente o dentro del VPS con volúmenes persistentes).
3. **Almacenamiento de archivos**: carpeta local montada como volumen (ver sección 3) o servicio S3 compatible.
4. **Correo**: servicio SMTP real (reemplaza Mailhog de desarrollo).
5. **Frontend web**: archivos estáticos de Flutter servidos por Nginx/CDN u otro contenedor.

## 2. Ventajas de dockerizar la pila

El repositorio ya trae definiciones `docker-compose` que levantan cada componente en contenedores independientes (`db`, `backend`, `frontend`, etc.), replicando la arquitectura real.

- **Paridad entre entornos**: la misma composición funciona en desarrollo, staging y producción.
- **Aislamiento y reproducibilidad**: versiones de Node, PostgreSQL y dependencias quedan encapsuladas.
- **Escalado modular**: se puede escalar la API sin tocar base de datos o frontend.
- **Persistencia controlada**: los volúmenes garantizan que la base y los uploads sobreviven a recreaciones de contenedores.

## 3. Almacenamiento local de archivos

El backend guarda los ficheros directamente en `storage/` (subcarpetas `uploads/` y `avatars/`) relativa al directorio de ejecución del proceso. NestJS expone esa ruta como estático (`/storage/uploads/...`), por lo que basta con montar una carpeta persistente del host.

Para contenedores, dos opciones:

- **Volumen nombrado** (`backend-storage`): Docker gestiona la ruta en el host de forma transparente.
- **Montaje de carpeta del host**: permite decidir explícitamente dónde viven los archivos (por ejemplo `/srv/ligas/storage`).

La sección siguiente incluye dos archivos `docker-compose` listos para cada enfoque.

## 4. Archivos `docker-compose` para almacenamiento local

### 4.1 `infra/docker-compose.local-storage.yml`

Usa un volumen nombrado para persistir los uploads y avatares.

```
version: '3.9'
services:
  db:
    image: postgres:15-alpine
    container_name: ligas_db
    environment:
      POSTGRES_USER: postgres
      POSTGRES_PASSWORD: postgres
      POSTGRES_DB: ligas
    ports:
      - "5432:5432"
    volumes:
      - postgres-data:/var/lib/postgresql/data

  mailhog:
    image: mailhog/mailhog:latest
    ports:
      - "8025:8025"

  backend:
    build:
      context: ../backend
    environment:
      APP_URL: http://localhost:3000
      FRONTEND_URL: http://localhost:8080
      DATABASE_URL: postgres://postgres:postgres@db:5432/ligas
      JWT_ACCESS_SECRET: change-me-access
      JWT_REFRESH_SECRET: change-me-refresh
      SMTP_HOST: ${SMTP_HOST:-mailhog}
      SMTP_PORT: ${SMTP_PORT:-1025}
      SMTP_USER: ${SMTP_USER:-}
      SMTP_PASS: ${SMTP_PASS:-}
      SMTP_FROM: ${SMTP_FROM:-noreply@ligas.local}
    depends_on:
      - db
    ports:
      - "3000:3000"
    volumes:
      - backend-storage:/app/storage

  frontend:
    build:
      context: ../frontend
    ports:
      - "8080:80"
    depends_on:
      - backend

volumes:
  postgres-data:
  backend-storage:
```

### 4.2 `infra/docker-compose.local-storage.bind.yml`

Monta una ruta explícita del host (edita `/srv/ligas/storage` por la que prefieras). Útil en un VPS donde quieras controlar respaldos o usar un disco separado.

```
version: '3.9'
services:
  db:
    image: postgres:15-alpine
    container_name: ligas_db
    environment:
      POSTGRES_USER: postgres
      POSTGRES_PASSWORD: postgres
      POSTGRES_DB: ligas
    ports:
      - "5432:5432"
    volumes:
      - postgres-data:/var/lib/postgresql/data

  mailhog:
    image: mailhog/mailhog:latest
    ports:
      - "8025:8025"

  backend:
    build:
      context: ../backend
    environment:
      APP_URL: http://localhost:3000
      FRONTEND_URL: http://localhost:8080
      DATABASE_URL: postgres://postgres:postgres@db:5432/ligas
      JWT_ACCESS_SECRET: change-me-access
      JWT_REFRESH_SECRET: change-me-refresh
      SMTP_HOST: ${SMTP_HOST:-mailhog}
      SMTP_PORT: ${SMTP_PORT:-1025}
      SMTP_USER: ${SMTP_USER:-}
      SMTP_PASS: ${SMTP_PASS:-}
      SMTP_FROM: ${SMTP_FROM:-noreply@ligas.local}
    depends_on:
      - db
    ports:
      - "3000:3000"
    volumes:
      - /srv/ligas/storage:/app/storage

  frontend:
    build:
      context: ../frontend
    ports:
      - "8080:80"
    depends_on:
      - backend

volumes:
  postgres-data:
```

> **Nota:** si ya tienes una instancia SMTP real, puedes retirar el servicio `mailhog` y ajustar `SMTP_*` con tus credenciales.
> Puedes definirlas como variables de entorno al invocar `docker compose` o colocarlas en un archivo `.env` junto a los manifests en `infra/`.
> Los campos `SMTP_SECURE`, `SMTP_REQUIRE_TLS`, `SMTP_IGNORE_TLS` y `SMTP_TLS_REJECT_UNAUTHORIZED` permiten afinar el handshake TLS cuando usas un proveedor externo.

## 5. Ejecución

1. Selecciona el archivo deseado.
   - Volumen administrado por Docker: `docker compose -f infra/docker-compose.local-storage.yml up -d`
   - Carpeta del host: `docker compose -f infra/docker-compose.local-storage.bind.yml up -d`
2. El frontend quedará disponible en `http://localhost:8080`, la API en `http://localhost:3000` y la base en `localhost:5432`.
3. Los archivos subidos se persistirán según la estrategia elegida.

## 6. Estimación de recursos para un VPS

Los valores siguientes sirven como punto de partida para un entorno productivo pequeño (ligas amateurs, carga moderada):

- **CPU:** 2 vCPU dedicados.
- **Memoria RAM:** 4 GB (2 GB mínimos; 4 GB permiten headroom para Node, PostgreSQL y procesos batch).
- **Almacenamiento:** 40 GB SSD (20 GB para base + uploads + logs; el resto para sistema operativo y margen).
- **Ancho de banda:** 1 TB/mes suele ser suficiente para tráfico web moderado.

Para crecimiento sostenido o cargas superiores (múltiples torneos concurrentes, heavy media), considera escalar a 4 vCPU y 8 GB de RAM, además de mover la base o el almacenamiento a servicios gestionados.

## 7. Buenas prácticas adicionales

- Configura backups automáticos de la base y de la carpeta de almacenamiento.
- Usa HTTPS (reverse proxy Nginx/Caddy con certificados Let’s Encrypt).
- Centraliza logs (por ejemplo con Loki, CloudWatch o syslog remoto).
- En producción reemplaza Mailhog por un proveedor SMTP y considera un servicio tipo S3 si el volumen de archivos crece.

