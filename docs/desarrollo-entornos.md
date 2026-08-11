# Guía de desarrollo

Esta guía reúne los pasos para preparar, desarrollar y probar el monorepo de **Ligas Deportivas**. Cubre requisitos, variables de entorno, comandos habituales y consejos para trabajar con la API NestJS, el frontend SvelteKit y la infraestructura en Docker.

Credenciales semilla del administrador:

- Usuario (email): `admin@ligas.local`
- Contraseña: `Admin123!`

Las credenciales pueden personalizarse antes de ejecutar el seed mediante variables de entorno (`ADMIN_EMAIL`, `ADMIN_PASSWORD`).

## 1. Requisitos de software

- Node.js 20 o superior.
- PostgreSQL 15 o superior (local o en contenedor).
- Docker Engine (opcional) para levantar la pila completa.

## 2. Preparación inicial

### 2.1 Clonar el repositorio
```bash
git clone git@github.com:hectororviz/ligas-deportivas-V2.git
cd ligas-deportivas-V2
```

### 2.2 Backend
```bash
cd backend
npm install
npx prisma generate
npx prisma migrate dev
npm run seed
npm run start:dev
```
La API queda disponible en `http://localhost:3000/api/v1`.

### 2.3 Frontend SvelteKit
```bash
cd frontend-svelte
npm install
npm run dev -- --open
```
El frontend se abre en `http://localhost:5173` y se comunica con la API mediante el proxy configurado en `vite.config.ts`. Para desarrollo, define `PUBLIC_API_BASE_URL=http://localhost:3000/api/v1` en `.env`.

### 2.4 Infraestructura con Docker
Para levantar todo en contenedores:
```bash
cd infra
cp .env.example .env  # editar con tus valores
docker compose up -d
```

## 3. Scripts principales

| Área | Comando | Objetivo |
|---|---|---|
| Backend | `npm test` | Pruebas unitarias con Jest |
| Backend | `npm run lint` | ESLint sobre `src/` |
| Backend | `npm run seed` | Datos base (roles, admin) |
| Backend | `npx prisma migrate dev` | Aplicar migraciones |
| Frontend | `npm run check` | Type-check con svelte-check |
| Frontend | `npm run build` | Build de producción con adapter-node |
| Frontend | `npm run dev` | Servidor de desarrollo con HMR |
| Infra | `./deploy.sh --seed` | Despliegue completo con seed |

## 4. Variables de entorno

Copiar `infra/.env.example` como `infra/.env` y configurar:

```
POSTGRES_PASSWORD=<password>
JWT_ACCESS_SECRET=<secret>
JWT_REFRESH_SECRET=<secret>
APP_URL=https://ligas.csdsoler.com.ar
FRONTEND_URL=https://ligas.csdsoler.com.ar
ADMIN_EMAIL=admin@ligas.local
ADMIN_PASSWORD=Admin123!
IMAGE_TAG=latest
```

## 5. Restablecer la base de datos

```bash
# Reset completo
npx prisma migrate reset --force

# Solo re-seed (no borra datos)
cd infra && ./deploy.sh --seed
```

## 6. Calidad y CI/CD

- GitHub Actions ejecuta automáticamente tests del backend y type-check del frontend en cada push a `main`, `Dev` o `dev2`.
- Las imágenes Docker se publican en `ghcr.io/hectororviz/ligas-deportivas-v2` con tags por SHA, rama y `latest`.
- El despliegue en el VPS se realiza con `./infra/deploy.sh`.
