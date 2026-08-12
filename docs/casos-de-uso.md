# Casos de uso y flujo de trabajo

Este documento describe los flujos funcionales principales de la plataforma y cómo se encadenan entre sí. Complementa a [`architecture.md`](architecture.md) y [`api.md`](api.md).

## 1. Jerarquía de datos

```
Liga
 └── Torneo (instancia de una liga: anual / semestral / verano)
      └── Zona (2-4 por torneo, 8-12 clubes cada una)
           └── Fecha (jornada)
                └── Partido (cruce de dos clubes, con una o más categorías)
```

Un partido no es un único resultado: agrupa el cruce de dos clubes en **todas las categorías habilitadas** del torneo (Primera, Sub-15, Damas, etc.). Cada categoría tiene su propio marcador y sus propios goles.

## 2. Configuración inicial

1. **Ligas** (`/leagues`): registrar la organización (nombre, identificador, día de juego, color distintivo).
2. **Categorías** (`/categories`): definir categorías por rango de años, género y mínimo de jugadores, y marcarlas como obligatorias o promocionales.
3. **Clubes** (`/clubs`): registrar clubes (escudo, colores, ubicación, redes).
4. **Jugadores** (`/players`): registrar personas por tres vías:
   - **Manual**: formulario individual.
   - **Masivo**: tabla con 10 filas (agregables) y validación previa.
   - **Escanear DNI**: captura con cámara y lectura PDF417 del DNI.

## 3. Armar un torneo

1. **Crear torneo** (`/tournaments`): elegir liga, nombre, año, género, sistema de puntos y modo campeón.
2. **`Controlar jugadores`**: si está activo, el torneo gestiona jugadores, planteles y goles por jugador. Si está desactivado, todo lo relacionado con jugadores queda fuera del flujo (no se asocian jugadores, la carga de goles es solo por club).
3. **Seleccionar categorías**: un selector con tabla permite activar cada categoría, indicar si es **promocional** (no suma puntos para la tabla general) y fijar el **horario de juego**. El botón se habilita recién al elegir género.

## 4. Participación de clubes

1. En el detalle del club (`/club/[slug]`) se usa **Participar** para inscribirlo en un torneo. Al unirse, lo hace en **todas las categorías** del torneo.
2. Si el torneo **controla jugadores**, se asigna el plantel por categoría en `/clubs/[clubId]/roster` (buscar por DNI y agregar/quitar jugadores).

## 5. Zonas y fixture

1. **Crear zona** (`/zones`) asociada a un torneo (botón `+`).
2. **Asignar clubes** a la zona: al expandir la zona se listan los clubes en la zona y los disponibles. Solo se ofrecen clubes que no estén en otra zona del mismo torneo.
3. **Generar fixture** (por zona):
   - **Automático**: vista previa → confirmar. Al confirmar se finaliza la zona y se guarda el fixture (ida y vuelta).
   - **Manual**: constructor drag & drop. Los clubes se arrastran a los slots Local/Visitante; las infracciones (repetir local/visitante, cruces duplicados) se muestran como advertencias en amarillo, no bloquean el guardado. La segunda rueda se genera automáticamente invirtiendo local/visitante.
4. La generación valida que las categorías habilitadas tengan horario definido (o que el torneo no controle jugadores, en cuyo caso se omiten validaciones de jugadores).

## 6. Consulta del fixture

En `/fixtures`:
- **Selectores encadenados** Liga → Torneo → Zona (sin auto-selección).
- **Carrusel de fechas** con la fecha "actual" (en curso) preseleccionada y centrada.
- Cada **partido** muestra los puntos obtenidos en las **categorías no promocionales** (no la suma de goles).
- La selección se **persiste** en `localStorage` y se refleja en la URL (deep linking: `?league=..&torneo=..&zona=..&fecha=..`).

## 7. Carga de resultados

1. Al tocar un partido se abre la página de resultado (`/fixtures/partido/[matchId]`):
   - Cabecera con escudos, nombres y **puntos** de cada club (categorías no promocionales).
   - Tabla por categoría con marcador local/visitante. Cada celda se pinta por su propio resultado: **verde** si ganó, **rojo** si perdió, **amarillo** si empató.
2. Al tocar una categoría se abre el modal de **goles**:
   - Dos columnas (Local | Visitante) con la lista de jugadores fichados y un campo numérico de goles cada uno.
   - Fila **Otros** para goles de jugadores no listados.
   - Si el torneo **no controla jugadores**, solo se muestra "Otros".
   - El marcador se calcula automáticamente sumando los goles (la API valida que la suma coincida).
3. Al guardar se cierra la categoría y, al cerrarse todas, el partido pasa a finalizado y se recalculan las tablas.

## 8. Tablas y estadísticas

- `/standings`: posiciones por zona o por torneo.
- `/stats`: goleadores, vallas menos vencidas, equipos más goleadores, etc.

## 9. Eliminación de entidades

- **Zona**: se puede eliminar mientras esté en estado **Abierto** (sin partidos generados).
- **Torneo**: la eliminación es **física y en cascada** (zonas, partidos, goles, planteles, etc.). Requiere **confirmación con usuario y contraseña de administrador** (se valida que el usuario tenga rol `ADMIN`).

## 10. Configuración del sitio

- **Identidad del sitio** (`/settings/site-identity`): título, ícono, flyer, favicon y **paleta de colores**.
- **Paletas**: 36 combinaciones (claras, oscuras y temáticas MMA). La elección es **global**: se guarda en el backend y la ven todos los usuarios desde cualquier plataforma.
- **Usuarios y permisos** (`/settings/users`): listado de usuarios y asignación/remoción de roles.
