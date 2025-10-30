# Guía de desarrollo y pruebas con Visual Studio Code

Esta guía explica cómo preparar, desarrollar y probar el monorepo de **Ligas Deportivas** en Visual Studio Code (VS Code) usando Windows 10/11 y Linux (Ubuntu y Arch Linux). Incluye los requisitos para el backend NestJS + Prisma, el frontend Flutter Web y la infraestructura opcional con Docker Compose.

Credenciales por defecto del administrador

Usuario (email): admin@ligas.local
Contraseña: Admin123

## 1. Preparación inicial común

### 1.1 Clonar el repositorio y abrirlo en VS Code
1. Instala Git (en Windows usa [Git for Windows](https://git-scm.com/download/win); en Linux, usa el gestor de paquetes).
2. Clona el proyecto y ábrelo en VS Code:
   ```bash
   git clone https://github.com/<tu-organizacion>/ligas-deportivas-V2.git
   code ligas-deportivas-V2
   ```

### 1.2 Extensiones recomendadas en VS Code
Instala las extensiones siguientes desde la Marketplace para una mejor experiencia:
- **ESLint** y **Prettier** para mantener el estilo del backend TypeScript.
- **Prisma** para resaltar y validar el esquema de base de datos.
- **Dart** y **Flutter** para trabajar con el frontend.
- **Thunder Client** o **REST Client** para probar endpoints REST.
- **Docker** (opcional) si vas a administrar contenedores desde VS Code.

### 1.3 Requisitos de software
El proyecto requiere como mínimo:
- Node.js 20 o superior.
- PostgreSQL 15 o superior.
- Flutter 3.19 o superior para el frontend web.
- Docker y Docker Compose (opcional) para levantar toda la pila localmente.【F:README.md†L14-L77】

### 1.4 Variables de entorno del backend
Copia el archivo `.env.example` dentro de `backend/` a `.env` y ajusta las variables según tu entorno (datos de PostgreSQL, secretos JWT, configuración SMTP y acceso a MinIO).【F:backend/.env.example†L1-L28】

### 1.5 Flujo general de backend y frontend
1. Instala dependencias del backend y genera el cliente de Prisma.
2. Ejecuta migraciones y datos de prueba.
3. Levanta el backend en modo `start:dev` para recarga en caliente.
4. Instala dependencias del frontend Flutter y ejecútalo en modo web.
5. Usa los scripts de pruebas y linting para validar la calidad del código.【F:README.md†L21-L61】【F:backend/package.json†L6-L75】

### 1.6 Limpiar la base de datos de desarrollo
Si necesitas vaciar los datos de prueba y dejar la base lista para volver a sembrar la información base:

1. Resetea la base manejada por Prisma desde el backend:
   ```bash
   cd backend
   npx prisma migrate reset --force
   ```
   Este comando elimina todas las tablas, vuelve a ejecutar las migraciones y corre automáticamente el `prisma/seed.ts` para restaurar los datos definidos en `src/prisma/base-seed.ts`.

2. Si trabajas con la infraestructura en Docker (`infra/docker-compose.yml`), puedes destruir el volumen persistente de PostgreSQL para empezar desde cero:
   ```bash
   cd infra
   docker compose down -v
   ```
   Al siguiente `docker compose up --build` se recreará un volumen limpio y Prisma volverá a sembrar los datos base cuando ejecutes el paso anterior.

## 2. Configuración en Windows 10/11

### 2.1 Instalación de dependencias
1. **Visual Studio Code**: instala la versión estable desde <https://code.visualstudio.com/>.
2. **Windows Terminal (opcional)**: facilita el uso de PowerShell y WSL.
3. **Node.js**: instala `nvm-windows` desde <https://github.com/coreybutler/nvm-windows> y ejecuta en PowerShell:
   ```powershell
   nvm install 20
   nvm use 20
   ```
4. **Flutter**:
   - Descarga el SDK desde <https://docs.flutter.dev/get-started/install/windows>.
   - Extrae el ZIP en `C:\src\flutter` y añade `C:\src\flutter\bin` al `PATH` de tu usuario.
   - Ejecuta `flutter doctor` en una terminal para verificar dependencias (instala Chrome si no está presente).
5. **PostgreSQL**:
   - Opción 1: instala [PostgreSQL](https://www.postgresql.org/download/windows/) y crea una base de datos `ligas`.
   - Opción 2: instala [Docker Desktop](https://www.docker.com/products/docker-desktop/) y usa `infra/docker-compose.yml`.
6. **Git**: instala [Git for Windows](https://git-scm.com/download/win) si no lo hiciste en la sección inicial.

### 2.2 Uso de Docker Compose (opcional)
Con Docker Desktop ejecutándose, abre una terminal en `infra/` y corre:
```powershell
cd infra
docker compose up --build
```
Esto levantará PostgreSQL, MinIO, Mailhog, el backend NestJS y el frontend compilado. Los puertos expuestos son 3000 (API), 8080 (frontend), 8025 (Mailhog) y 9001 (MinIO).【F:infra/docker-compose.yml†L1-L60】

### 2.3 Configurar la base de datos sin Docker
Si prefieres PostgreSQL nativo:
1. Crea un usuario `postgres` con contraseña `postgres` (o actualiza la cadena en `.env`).
2. Crea la base de datos `ligas`.
3. Asegura que el puerto 5432 esté disponible.

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
3. Configura un **task** de VS Code (opcional) que ejecute `npm run start:dev` usando el `type` `shell`.

### 2.5 Frontend Flutter Web
1. En otra terminal integrada:
   ```powershell
   cd frontend
   flutter pub get
   flutter run -d chrome
   ```
2. Para pruebas y análisis estático:
   ```powershell
   flutter test
   flutter analyze
   ```

### 2.6 Pruebas y linting del backend
Desde la carpeta `backend/` puedes ejecutar:
```powershell
npm run lint
npm test
npm run test:cov
```
Configura configuraciones de depuración (`launch.json`) si quieres depurar con el adaptador de Node.js.

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
Asegúrate de tener Google Chrome instalado (`sudo apt install -y google-chrome-stable` desde el repositorio de Google) para usar `flutter run -d chrome`.

### 3.4 PostgreSQL y Docker (opcional)
- Instala PostgreSQL nativo: `sudo apt install -y postgresql postgresql-contrib` y crea la base de datos `ligas`.
- Si prefieres contenedores, instala Docker siguiendo <https://docs.docker.com/engine/install/ubuntu/> y usa `docker compose` con el archivo en `infra/`.

### 3.5 Flujo en VS Code
Las mismas secuencias del backend y frontend descritas para Windows aplican en Ubuntu. Usa la terminal integrada (`Ctrl+Ñ` en teclado latinoamericano o `Ctrl+\`` en teclado US) para ejecutar los comandos de npm y Flutter.

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
- Instala Flutter desde los repositorios comunitarios: `sudo pacman -S --needed flutter`. Añade `export PATH="$PATH:/opt/flutter/bin"` a tu `~/.bashrc` o `~/.zshrc` si no se añade automáticamente.
- Ejecuta `flutter doctor` y, si usas Chromium, instala `chromium` con `sudo pacman -S chromium`.

### 4.4 PostgreSQL y Docker
- PostgreSQL: `sudo pacman -S postgresql` y sigue las instrucciones de inicialización (`sudo -iu postgres initdb --locale $LANG -D /var/lib/postgres/data` y `sudo systemctl enable --now postgresql`). Crea la base `ligas`.
- Docker: `sudo pacman -S docker docker-compose`. Habilita el servicio (`sudo systemctl enable --now docker`) y agrega tu usuario al grupo `docker` (`sudo usermod -aG docker $USER`). Reinicia la sesión antes de ejecutar `docker compose up`.

### 4.5 Trabajo diario en VS Code
Repite los comandos de backend (`npm install`, `npx prisma ...`, `npm run start:dev`) y frontend (`flutter pub get`, `flutter run -d chrome`) desde la terminal integrada. Asegúrate de que Prisma puede acceder al socket de PostgreSQL (`localhost:5432`).

## 5. Ejecución de pruebas y calidad

| Área        | Comando principal | Objetivo |
|-------------|------------------|----------|
| Backend     | `npm run lint`   | Ejecuta ESLint sobre `src/` para asegurar estilo consistente.【F:backend/package.json†L11-L12】|
| Backend     | `npm test`       | Corre la suite de pruebas unitarias con Jest.【F:backend/package.json†L16-L17】|
| Backend     | `npm run test:cov` | Genera reporte de cobertura con Jest.【F:backend/package.json†L18-L18】|
| Frontend    | `flutter test`   | Corre pruebas unitarias/widget del cliente Flutter. |
| Frontend    | `flutter analyze`| Analiza estáticamente el código Dart. |
| Infra       | `docker compose up --build` | Levanta toda la pila local para pruebas integradas.【F:infra/docker-compose.yml†L1-L60】|

## 6. Consejos adicionales
- Usa perfiles de VS Code (`F1 → Settings Profiles`) para separar configuraciones de backend y frontend si lo prefieres.
- Configura `launch.json` con el tipo `pwa-chrome` para depurar Flutter Web desde VS Code.
- Si cambias las credenciales de la base de datos, actualiza tanto `.env` como `prisma/schema.prisma` según corresponda antes de ejecutar `npx prisma migrate dev`.
- Mantén sincronizado el repositorio ejecutando `git pull` frecuentemente y usando ramas feature para tus cambios.

Con estas instrucciones podrás desarrollar y probar el proyecto en Windows, Ubuntu y Arch Linux utilizando Visual Studio Code como entorno principal.
