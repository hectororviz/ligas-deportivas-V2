# Placeholders para plantilla de posters

Usa estos tokens en capas de texto o imágenes dentro del JSON de la plantilla.

## Texto
- `{{league.name}}`
- `{{tournament.name}}`
- `{{match.round}}`
- `{{match.matchday}}`
- `{{match.date}}`
- `{{match.dayName}}`
- `{{tournament.timeSlots}}` (lista por línea, formato `HH:mm Hs - Categoría`)
- `{{homeClub.name}}`
- `{{awayClub.name}}`
- `{{venue.name}}` (si aplica)
- `{{venue.address}}` (si aplica)

## Imágenes (logos)
- `{{homeClub.logoUrl}}`
- `{{awayClub.logoUrl}}`

## Notas
- Los logos se resuelven desde el backend y se embeben como data URL en el render final.
- Si un token no tiene datos disponibles (por ejemplo, venue), se reemplaza por texto vacío.
