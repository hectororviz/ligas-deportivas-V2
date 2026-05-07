# 🛡️ Punto de Restauración - Pre Cambios Mayores

## 📅 Fecha de Creación
2026-05-07 22:11:52 UTC

## 🏷️ Tag GitHub
**`v1.0.0-stable-20260507`**

🔗 https://github.com/hectororviz/ligas-deportivas-V2/releases/tag/v1.0.0-stable-20260507

## 💾 Backup Base de Datos
**Archivo:** `backup_pre_cambios_mayores_20260507_221152.sql`  
**Ubicación:** `/home/ubuntu/ligas-deportivas-V2/infra/backup_pre_cambios_mayores_20260507_221152.sql`  
**Tamaño:** 383 KB

## 📋 Información del Commit
- **Rama:** `dev2`
- **Commit:** `463f496`
- **Mensaje:** "config: mejora configuración de infraestructura"

## 🚀 Instrucciones de Restauración

### Opción 1: Restaurar solo código (Git)
```bash
# Volver al código estable
git checkout v1.0.0-stable-20260507

# Para volver al desarrollo actual después
git checkout dev2
```

### Opción 2: Restaurar código + base de datos completa
```bash
# 1. Detener servicios
cd /home/ubuntu/ligas-deportivas-V2/infra
docker compose down

# 2. Restaurar código
git checkout v1.0.0-stable-20260507

# 3. Levantar DB limpia
docker compose up -d db

# 4. Esperar a que DB esté healthy
docker compose ps

# 5. Restaurar backup
docker compose exec -T db psql -U postgres -d ligas < backup_pre_cambios_mayores_20260507_221152.sql

# 6. Levantar resto de servicios
docker compose up -d
```

### Opción 3: Solo base de datos (mantener código actual)
```bash
cd /home/ubuntu/ligas-deportivas-V2/infra

# Restaurar solo la base de datos
docker compose exec -T db psql -U postgres -d ligas < backup_pre_cambios_mayores_20260507_221152.sql
```

## ⚠️ Notas Importantes
- Este punto de restauración se creó ANTES de implementar cambios grandes
- El backup incluye TODOS los datos: ligas, clubes, jugadores, partidos, usuarios, etc.
- La aplicación estaba funcionando correctamente en este punto
- Los cambios de responsive design ya estaban aplicados y probados

## 📝 Estado de Servicios al momento del backup
- ✅ PostgreSQL 15 (Healthy)
- ✅ Backend NestJS
- ✅ Frontend Flutter Web
- ✅ Proxy Caddy
- ✅ MailHog
