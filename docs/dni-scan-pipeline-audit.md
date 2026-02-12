# Auditoría pipeline escaneo DNI (PDF417)

## Frontend (Flutter Web)

### Flujo real
1. `captureDniImage()` delega en implementación web (`dni_capture_web.dart`).
2. Se usa `html.FileUploadInputElement` con `accept=image/*` y `capture=environment`.
3. El archivo seleccionado se lee con `FileReader.readAsArrayBuffer(file)`.
4. El upload se arma con `MultipartFile.fromBytes(image.bytes, filename, contentType)` y se envía a `POST /players/dni/scan`.

### ¿Se comprime/reescala/recomprime?
No. El flujo usa bytes directos del archivo (`ArrayBuffer`) sin canvas, sin `toDataUrl`, sin `toBlob`, sin `imageQuality`, sin `maxWidth/maxHeight` y sin librerías de compresión.

### Instrumentación agregada
- Logs técnicos (sin PII):
  - `filename`
  - `mime`
  - `bytes`
  - dimensiones detectadas (`width x height`)
  - indicación explícita de `base64Length=not_used(raw_upload)`
- Verificación de dimensiones antes de subir con `ui.instantiateImageCodec`.
- Upload explícito en modo **raw** con `contentType` preservado del archivo original.

## Backend (NestJS)

### Endpoint `/players/dni/scan`
- `multer` usa `memoryStorage()`.
- Límite: `8MB`.
- El archivo se procesa desde `file.buffer`.

### Logs técnicos agregados
- En cada request de escaneo:
  - `mimetype`
  - `size`
  - `width/height` (detectado con `sharp(...).metadata()`)

### Modo debug temporal (`SCAN_DEBUG=1`)
- Si `SCAN_DEBUG=1` (o `DNI_SCAN_DEBUG=true` por compatibilidad):
  - guarda archivo recibido en `/tmp/dni-scan-<uuid>.<ext>`
  - lo borra al final del request (`finally`)
  - loguea save/remove y errores de cleanup

## Decoder PDF417 actual

### Implementación real
- No hay librería Node de PDF417 integrada en el backend.
- Se invoca un **comando externo** configurado por `DNI_SCAN_DECODER_COMMAND` vía `spawn`.
- Entrada: imagen por `stdin` (bytes del buffer).
- Salida esperada: payload PDF417 por `stdout`.

### Parámetros / soporte de formatos
- El backend no fija formato PDF417 en código: depende 100% del binario externo configurado.
- Si el comando no está configurado, responde `422`.
- Soporte real de formatos también depende de ese binario externo (no del backend).

### Preprocesado antes de decodificar
Se generan estrategias múltiples con `sharp`:
- rotaciones: `0/90/180/270`
- `raw`
- `grayscale`
- `threshold`
- `upscale_x2`
- `upscale_x3`

Y se prueban en secuencia hasta éxito.

### Instrumentación de decoder agregada
- Por estrategia:
  - tiempo de decode (`elapsedMs`)
  - estrategia
  - rotación
  - error real del decoder (`stderr` + exit code si falla)
- No se imprime contenido decodificado.

## Endpoint interno de diagnóstico (dev/debug)

Nuevo endpoint: `POST /players/dni/scan/diagnostic`
- Requiere archivo imagen.
- Solo habilitado con `SCAN_DEBUG=1`.
- Ejecuta todas las estrategias listadas.
- Devuelve JSON con:
  - `decoderCommand`
  - `mimetype`
  - `size`
  - `report[]` con éxito/error/tiempo por estrategia

## Causas probables de `422` con imagen visualmente correcta

1. **Decoder externo ausente o mal configurado** (`DNI_SCAN_DECODER_COMMAND`).
2. **Decoder externo no soporta bien PDF417 de DNI argentino** o requiere flags distintos.
3. **Ninguna estrategia de preprocesado + rotación logra decode**.
4. **Decodifica, pero parser falla** (`dni-pdf417-parser`) por formato inesperado:
   - pocos tokens
   - campos faltantes
   - sexo/fecha/dni inválidos

## Recomendación de reemplazo (gratis) y plan

Si el binario actual es inestable:
1. Probar `zxing-cpp` CLI o wrapper mantenido para PDF417 (open source).
2. Estandarizar comando en contenedor backend para evitar diferencias entre entornos.
3. Definir contrato fijo de salida (payload plano UTF-8).
4. Mantener endpoint diagnóstico para comparar tasas de éxito por estrategia.
5. Agregar set de imágenes de test anonimizado para regresión de decode.
