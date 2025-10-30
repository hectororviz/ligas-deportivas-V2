# Guía de desarrollo y pruebas con Visual Studio Code

Esta guía reúne los pasos recomendados para preparar, desarrollar y probar el monorepo de **Ligas Deportivas** en Visual Studio Code (VS Code) desde Windows 10/11, Ubuntu y Arch Linux. Cubre requisitos, variables de entorno, comandos habituales y consejos para trabajar con la API NestJS, el frontend Flutter Web y la infraestructura en Docker.

Credenciales semilla del administrador

- Usuario (email): `admin@ligas.local`
- Contraseña: `Admin123`

Las credenciales pueden personalizarse antes de ejecutar el seed inicial mediante variables de entorno (`ADMIN_EMAIL`, `ADMIN_PASSWORD`). ([backend/src/prisma/base-seed.ts](backend/src/prisma/base-seed.ts))

## 1. Preparación inicial común

### 1.1 Clonar el repositorio y abrirlo en VS Code
1. Instala Git en tu sistema (en Windows usa [Git for Windows](https://git-scm.com/download/win); en Linux recurre al gestor de paquetes).
2. Clona el proyecto y ábrelo en VS Code:
   ```bash
   git clone https://github.com/<tu-organizacion>/ligas-deportivas-V2.git
   cd ligas-deportivas-V2
   code .
   ```

### 1.2 Extensiones recomendadas en VS Code
Instala las siguientes extensiones para mejorar la experiencia:
- **ESLint** y **Prettier** para el backend TypeScript.
- **Prisma** para destacar el esquema de base de datos.
- **Dart** y **Flutter** para el frontend.
- **REST Client** o **Thunder Client** para probar endpoints.
- **Docker** (opcional) si administras contenedores desde VS Code.

### 1.3 Requisitos de software
El proyecto requiere como mínimo:
- Node.js 20 o superior. ([README.md](README.md))
- PostgreSQL 15 o superior (instalación local o contenedor). ([README.md](README.md))
- Flutter 3.19 o superior para compilar el frontend web. ([README.md](README.md))
- Docker Desktop/Engine (opcional) para levantar la pila completa con `docker compose`. ([README.md](README.md))

### 1.4 Variables de entorno del backend
1. Copia `backend/.env` como base y ajusta la cadena de conexión, secretos JWT, credenciales SMTP y configuración de almacenamiento según tu entorno. ([README.md](README.md)) ([backend/.env](backend/.env))
2. Antes de sembrar datos, define (si lo necesitas) las variables `ADMIN_EMAIL`, `ADMIN_PASSWORD` y `SEED_RESET_ADMIN_PASSWORD` para personalizar el usuario administrador inicial. ([backend/.env](backend/.env)) ([backend/src/prisma/base-seed.ts](backend/src/prisma/base-seed.ts))

### 1.5 Flujo general de backend y frontend
1. Instala dependencias y genera el cliente de Prisma (`npm install`, `npx prisma generate`). ([README.md](README.md))
2. Ejecuta las migraciones y el seed base (`npx prisma migrate dev`, `npm run seed`). ([README.md](README.md))
3. Levanta la API en modo desarrollo con `npm run start:dev` para habilitar recarga en caliente y el prefijo `/api/v1`. ([README.md](README.md))
4. En otra terminal instala dependencias del frontend (`flutter pub get`, `flutter pub run build_runner build`). ([README.md](README.md))
5. Ejecuta la app web apuntando al backend local (`flutter run -d chrome --dart-define=API_BASE_URL=http://localhost:3000/api/v1`). ([README.md](README.md))

### 1.6 Restablecer la base de datos de desarrollo
- Para reiniciar el esquema y volver a cargar los datos base, usa `npx prisma migrate reset --force` desde `backend/`. Esto elimina todas las tablas, reaplica migraciones y ejecuta `npm run seed` automáticamente.
- Si trabajas con Docker, puedes eliminar el volumen persistente de PostgreSQL con `docker compose down -v` desde `infra/`; al reiniciar la pila, Prisma recreará el esquema al correr las migraciones. ([infra/docker-compose.yml](infra/docker-compose.yml))

## 2. Configuración en Windows 10/11

### 2.1 Instalación de dependencias
1. **Visual Studio Code**: instala la versión estable desde <https://code.visualstudio.com/>.
2. **Windows Terminal (opcional)** para administrar PowerShell y WSL.
3. **Node.js**: instala `nvm-windows` y, desde PowerShell, ejecuta:
   ```powershell
   nvm install 20
   nvm use 20
   ```
4. **Flutter**:
   - Descarga el SDK desde <https://docs.flutter.dev/get-started/install/windows>.
   - Extrae el ZIP (por ejemplo en `C:\src\flutter`) y agrega `C:\src\flutter\bin` al `PATH`.
   - Ejecuta `flutter doctor` para validar dependencias (Chrome incluido).
5. **PostgreSQL**:
   - Instala el paquete oficial y crea una base `ligas`, o
   - Usa Docker Desktop y el `docker-compose.yml` incluido para levantar la base rápidamente. ([infra/docker-compose.yml](infra/docker-compose.yml))
6. **Git**: instala [Git for Windows](https://git-scm.com/download/win) si aún no lo hiciste.

### 2.2 Uso de Docker Compose (opcional)
Con Docker Desktop activo, ejecuta en una terminal PowerShell:
```powershell
cd infra
docker compose up --build
```
Esto levantará PostgreSQL (puerto 5432), MinIO (9000/9001), Mailhog (8025), la API (3000) y el frontend (8080). ([infra/docker-compose.yml](infra/docker-compose.yml)) ([README.md](README.md))

### 2.3 Configurar la base sin Docker
Si prefieres PostgreSQL nativo:
1. Crea el usuario/contraseña indicados en tu `.env` (por defecto `postgres` / `postgres`). ([backend/.env](backend/.env))
2. Crea la base `ligas` y asegúrate de que el puerto 5432 esté libre.

### 2.4 Scripts del backend desde VS Code
1. Abre una terminal integrada (`Ctrl+ñ`).
2. Ejecuta:
   ```powershell
   cd backend
   npm install
   npx prisma generate
   npx prisma migrate dev
   npm run seed
   npm run start:dev
   ```
   Los scripts de lint y pruebas (`npm run lint`, `npm test`, `npm run test:cov`) también están disponibles para tareas automatizadas. ([README.md](README.md))

### 2.5 Frontend Flutter Web
1. En otra terminal integrada:
   ```powershell
   cd frontend
   flutter pub get
   flutter pub run build_runner build --delete-conflicting-outputs
   flutter run -d chrome --dart-define=API_BASE_URL=http://localhost:3000/api/v1
   ```
2. Para pruebas y análisis estático ejecuta `flutter test` y `flutter analyze`. ([README.md](README.md))

## 3. Configuración en Ubuntu

### 3.1 Paquetes base
```bash
sudo apt update
sudo apt install -y build-essential curl git libssl-dev pkg-config
```

### 3.2 Node.js con NVM
```bash
curl -fsSL https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash
source ~/.nvm/nvm.sh
nvm install 20
nvm use 20
```

### 3.3 Flutter
```bash
sudo snap install flutter --classic
flutter doctor
```
Instala Google Chrome (`sudo apt install google-chrome-stable`) o Chromium para poder ejecutar `flutter run -d chrome`.

### 3.4 PostgreSQL y Docker (opcional)
- PostgreSQL nativo: `sudo apt install -y postgresql postgresql-contrib` y crea la base `ligas` con un usuario acorde a tu `.env`.
- Docker: sigue la guía oficial <https://docs.docker.com/engine/install/ubuntu/> y utiliza `docker compose up --build` en la carpeta `infra/` cuando quieras levantar toda la pila. ([infra/docker-compose.yml](infra/docker-compose.yml))

### 3.5 Trabajo diario en VS Code
Los mismos comandos descritos para Windows aplican en Ubuntu. Usa la terminal integrada para ejecutar scripts del backend y frontend, y recuerda exportar `API_BASE_URL` cuando ejecutes `flutter run` si utilizas otro puerto/backend remoto. ([README.md](README.md))

## 4. Configuración en Arch Linux

### 4.1 Paquetes base
```bash
sudo pacman -Syu --needed base-devel git curl openssl pkgconf
```

### 4.2 Node.js con NVM
```bash
curl -fsSL https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash
source ~/.nvm/nvm.sh
nvm install 20
nvm use 20
```

### 4.3 Flutter
- Instala Flutter desde los repositorios comunitarios: `sudo pacman -S --needed flutter`.
- Agrega `/opt/flutter/bin` al `PATH` si no se añade automáticamente.
- Ejecuta `flutter doctor` para validar dependencias y asegúrate de tener `chromium` o Google Chrome instalado.

### 4.4 PostgreSQL y Docker
- PostgreSQL: `sudo pacman -S postgresql` y sigue las instrucciones de inicialización (`initdb`, habilitar servicio) antes de crear la base `ligas`.
- Docker: `sudo pacman -S docker docker-compose`, habilita el servicio (`sudo systemctl enable --now docker`) y agrega tu usuario al grupo `docker` antes de ejecutar `docker compose up` en `infra/`. ([infra/docker-compose.yml](infra/docker-compose.yml))

### 4.5 Trabajo diario en VS Code
Repite los comandos de backend (`npm install`, `npx prisma ...`, `npm run start:dev`) y frontend (`flutter pub get`, `flutter run ...`) desde la terminal integrada. Si la API corre en Docker u otra máquina, ajusta `API_BASE_URL` en el comando de Flutter para apuntar al host correcto. ([README.md](README.md))

## 5. Pruebas y calidad

| Área     | Comando principal | Objetivo |
|----------|------------------|----------|
| Backend  | `npm run lint`   | Ejecuta ESLint sobre `src/`. ([README.md](README.md))|
| Backend  | `npm test`       | Corre la suite de pruebas unitarias con Jest. ([README.md](README.md))|
| Backend  | `npm run test:cov` | Genera el reporte de cobertura de Jest. ([README.md](README.md))|
| Frontend | `flutter test`   | Ejecuta pruebas unitarias/widget del cliente Flutter. ([README.md](README.md))|
| Frontend | `flutter analyze`| Analiza estáticamente el código Dart. ([README.md](README.md))|
| Infra    | `docker compose up --build` | Levanta todos los servicios para pruebas integrales. ([README.md](README.md))|

## 6. Consejos adicionales

- Mantén sincronizado el repositorio (`git pull`) y utiliza ramas feature para cambios relevantes.
- Configura tareas (`tasks.json`) o perfiles de depuración en VS Code si deseas automatizar `npm run start:dev` o `flutter run`.
- Al generar fixtures o resultados, recuerda que la API expone los endpoints bajo `http://localhost:3000/api/v1`; puedes probarlos con Thunder Client antes de integrarlos al frontend. ([README.md](README.md))
- Si cambias las credenciales de la base, actualiza tanto `.env` como las variables de entorno del contenedor `backend` en `infra/docker-compose.yml` para mantener consistencia. ([backend/.env](backend/.env)) ([infra/docker-compose.yml](infra/docker-compose.yml))

Con estas pautas tendrás un entorno preparado para desarrollar y validar nuevas funcionalidades de la plataforma.
