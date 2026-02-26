# Guía técnica para crear un bot usando endpoints públicos y privados

Este documento explica cómo iniciar el desarrollo de un bot contra la API de **Ligas Deportivas V2**, diferenciando rutas públicas y privadas, con flujos técnicos, recomendaciones de seguridad y ejemplos listos para usar.

> Base API: `https://<dominio>/api/v1`

---

## 1) Qué puede hacer un bot con esta API

Un bot típico puede:

- **Leer información pública** sin autenticarse (ligas, torneos, zonas, clubes, partidos, tablas).
- **Ejecutar acciones privadas** autenticándose por JWT (crear/editar entidades, registrar resultados, generar fixtures), siempre que el usuario tenga permisos RBAC.
- **Automatizar tareas periódicas**: sincronización, alertas, resúmenes, validación de datos y publicación en canales externos.

---

## 2) Tipos de endpoint: público vs privado

## 2.1 Endpoints públicos (sin `Authorization`)

Útiles para bots de lectura y monitoreo.

Ejemplos frecuentes:

- `GET /leagues`
- `GET /tournaments`
- `GET /tournaments/:tournamentId/zones`
- `GET /zones/:id`
- `GET /zones/:zoneId/matches`
- `GET /zones/:zoneId/standings`
- `GET /matches/:matchId/categories/:categoryId/result`

### Ejemplo `curl` (público)

```bash
curl -sS "https://<dominio>/api/v1/leagues"
```

---

## 2.2 Endpoints privados (JWT + permisos)

Requieren:

1. Token JWT en header `Authorization: Bearer <accessToken>`.
2. Que el usuario autenticado tenga permisos en el módulo/acción correspondiente.

Ejemplos frecuentes:

- `POST /clubs`
- `PATCH /players/:id`
- `POST /matches/:matchId/categories/:categoryId/result`
- `POST /zones/:zoneId/fixture`

### Ejemplo `curl` (privado)

```bash
curl -sS -X POST "https://<dominio>/api/v1/zones/12/fixture" \
  -H "Authorization: Bearer <accessToken>" \
  -H "Content-Type: application/json" \
  -d '{"mode":"single_round_robin"}'
```

---


### Ejemplo para bot: zonas con equipos por torneo

Endpoint público:

- `GET /tournaments/:tournamentId/zones`

Respuesta ejemplo:

```json
[
  {
    "id": 11,
    "name": "Zona A",
    "teams": [
      {
        "id": 5,
        "name": "Club Soler",
        "shortName": "Soler",
        "slug": "club-soler"
      },
      {
        "id": 9,
        "name": "San Martín",
        "shortName": "San Martin",
        "slug": "san-martin"
      }
    ]
  }
]
```

Con este payload el bot puede renderizar mensajes del estilo: `Zona A: Soler, San Martín`.

---

## 3) Flujo de autenticación para bots privados

## 3.1 Login

Endpoint:

- `POST /auth/login`

Request:

```json
{
  "email": "bot@dominio.com",
  "password": "<SECRETO>"
}
```

Respuesta esperada:

```json
{
  "user": { "id": 10, "email": "bot@dominio.com" },
  "accessToken": "eyJ...",
  "refreshToken": "123.token-largo"
}
```

## 3.2 Refresh automático

Cuando un request privado retorna `401`, refrescar sesión:

- `POST /auth/refresh`

Body:

```json
{
  "refreshToken": "123.token-largo"
}
```

## 3.3 Logout técnico

Si el bot rota credenciales o termina ejecución controlada:

- `POST /auth/logout` con el `refreshToken`.

---

## 4) Arquitectura recomendada del bot

## 4.1 Módulos mínimos

1. **ApiClient**
   - Encapsula base URL, headers, timeouts y reintentos.
2. **AuthManager**
   - Gestiona login, refresh y almacenamiento seguro de tokens.
3. **Scheduler/Worker**
   - Ejecuta jobs por cron o intervalos (polling de endpoints públicos / privados).
4. **Domain services**
   - Ejemplo: `StandingsService`, `MatchesService`, `RosterService`.
5. **Observabilidad**
   - Logs estructurados, métricas de latencia, ratio de errores 401/403/5xx.

## 4.2 Estrategia de reintentos sugerida

- `429` o `5xx`: backoff exponencial con jitter.
- `401`: refresh token + reintento único.
- `403`: no reintentar automáticamente (problema de permisos).
- `4xx` de validación: registrar detalle y enviar a cola de revisión.

---

## 5) Ejemplos de implementación

## 5.1 Ejemplo Node.js (axios) con refresh

```ts
import axios from 'axios';

const api = axios.create({
  baseURL: 'https://<dominio>/api/v1',
  timeout: 15000,
});

let accessToken: string | null = null;
let refreshToken: string | null = null;

async function login() {
  const { data } = await api.post('/auth/login', {
    email: process.env.BOT_EMAIL,
    password: process.env.BOT_PASSWORD,
  });

  accessToken = data.accessToken;
  refreshToken = data.refreshToken;
}

async function refresh() {
  const { data } = await api.post('/auth/refresh', { refreshToken });
  accessToken = data.accessToken;
  refreshToken = data.refreshToken;
}

api.interceptors.request.use((config) => {
  if (accessToken) config.headers.Authorization = `Bearer ${accessToken}`;
  return config;
});

api.interceptors.response.use(
  (res) => res,
  async (err) => {
    const original = err.config;
    if (err.response?.status === 401 && !original._retry && refreshToken) {
      original._retry = true;
      await refresh();
      original.headers.Authorization = `Bearer ${accessToken}`;
      return api(original);
    }
    throw err;
  },
);

async function run() {
  await login();

  // Público
  const leagues = await api.get('/leagues');
  console.log('Ligas:', leagues.data?.length ?? 0);

  // Privado (ejemplo)
  // await api.post('/zones/12/fixture', { mode: 'single_round_robin' });
}

run().catch(console.error);
```

## 5.2 Ejemplo Python (requests) para endpoints públicos

```python
import requests

BASE_URL = "https://<dominio>/api/v1"

r = requests.get(f"{BASE_URL}/zones/5/standings", timeout=15)
r.raise_for_status()

data = r.json()
print("Equipos en tabla:", len(data.get("data", data)))
```

---

## 6) Casos de uso iniciales para “MVP bot”

1. **Bot de resultados:**
   - Lee `GET /zones/:zoneId/matches`.
   - Publica alertas por partido pendiente/finalizado.
2. **Bot de standings:**
   - Consume `GET /zones/:zoneId/standings` cada X minutos.
   - Detecta cambios y envía resumen.
3. **Bot operativo interno (privado):**
   - Registra resultados vía `POST /matches/:matchId/categories/:categoryId/result`.
   - Requiere usuario con permisos explícitos.

---

## 7) Seguridad y buenas prácticas

- Guardar secretos en variables de entorno y/o un secret manager.
- No hardcodear tokens en código ni en repositorios.
- Implementar rotación de credenciales del usuario bot.
- Usar cuenta de bot con **mínimos privilegios** (principio de menor privilegio).
- Loguear `requestId`/timestamp/endpoint/status para trazabilidad.
- Para endpoints multipart (avatar/logo/adjuntos), validar tamaño y tipo antes de enviar.

---

## 8) Checklist técnico antes de pasar a producción

- [ ] Flujo login/refresh probado con expiración real de JWT.
- [ ] Reintentos con backoff para 429/5xx.
- [ ] Manejo diferenciado de 401 vs 403 vs 422.
- [ ] Timeouts definidos por operación.
- [ ] Métricas y alertas de error configuradas.
- [ ] Modo “dry run” para probar automatizaciones sin escritura.
- [ ] Documentación interna de permisos requeridos por cada acción privada.

---

## 9) Referencias internas del proyecto

Para ampliar este documento con detalle endpoint por endpoint:

- `docs/api.md` (catálogo de rutas actual).
- `backend/src/main.ts` (prefijo global y configuración principal).
- `backend/src/auth/strategies/jwt.strategy.ts` (autenticación bearer).
- `backend/src/rbac/permissions.guard.ts` (autorización por permisos).

