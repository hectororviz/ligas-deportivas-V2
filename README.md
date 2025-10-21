# Ligas Deportivas

Plataforma integral para gestionar ligas, torneos, fixtures y resultados. Este repositorio contiene un monorepo con los proyectos de **backend (NestJS + Prisma)**, **frontend (Flutter Web)** y la configuración de infraestructura base en `infra/`.

## Estructura del repositorio

```
backend/   → API REST en Node.js + NestJS + Prisma
frontend/  → Aplicación Flutter Web (go_router + Riverpod)
infra/     → Docker Compose para entorno local (PostgreSQL, MinIO, Mailhog)
docs/      → Documentación funcional y técnica
```

## Requisitos

- Node.js 20+
- PostgreSQL 15+
- Flutter 3.19+ (para compilar el frontend)
- Docker (opcional, para levantar todo con `docker-compose`)

## Backend

1. Instalar dependencias y generar el cliente de Prisma:

   ```bash
   cd backend
   npm install
   npx prisma generate
   ```

2. Configurar las variables de entorno basadas en `.env.example` y ejecutar migraciones:

   ```bash
   npx prisma migrate dev
   npm run seed
   ```

3. Levantar la API en modo desarrollo:

   ```bash
   npm run start:dev
   ```

La API expone los endpoints bajo `http://localhost:3000/api/v1`. Incluye autenticación JWT, RBAC configurable, generación de fixture round-robin y cálculo de tablas.

## Frontend

1. Instalar dependencias (requiere Flutter 3.19 o superior):

   ```bash
   cd frontend
   flutter pub get
   ```

2. Ejecutar en modo web:

   ```bash
   flutter run -d chrome
   ```

El frontend utiliza Riverpod, go_router y un `NavigationRail` colapsable que respeta los permisos del usuario autenticado.

## Infraestructura con Docker

En la carpeta `infra/` se incluye un `docker-compose.yml` que levanta PostgreSQL, MinIO, Mailhog, el backend NestJS y el frontend compilado como sitio estático.

```bash
cd infra
docker-compose up --build
```

Los servicios quedarán disponibles en:

- API: `http://localhost:3000`
- Frontend web: `http://localhost:8080`
- Mailhog (correos de prueba): `http://localhost:8025`
- Consola MinIO: `http://localhost:9001`

## Documentación

- [Arquitectura y plan de implementación](docs/architecture.md)

La documentación describe el modelo de datos, reglas de negocio, matriz de permisos y roadmap evolutivo.
