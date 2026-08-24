import sharp = require('sharp');
import { ARUCO_DICT_4X4_50_BITS, ArucoId } from './template-v1.definitions';

const MODULE_COUNT = 6; // 4 interiores + 2 de borde

function arUcoPngBuffer(markerId: number, modulePixels: number): Promise<Buffer> {
  const bits = ARUCO_DICT_4X4_50_BITS[markerId];
  if (!bits) {
    throw new Error(`Marcador ArUco desconocido para TEMPLATE 1: ${markerId}`);
  }
  const side = MODULE_COUNT * modulePixels;
  const size = side * side;
  // RGB: blanco = 255, negro = 0
  const raw = Buffer.alloc(size * 3, 255);
  for (let row = 0; row < MODULE_COUNT; row += 1) {
    for (let col = 0; col < MODULE_COUNT; col += 1) {
      // El borde (fila/columna 0 o 5) siempre es negro.
      const isBorder =
        row === 0 || col === 0 || row === MODULE_COUNT - 1 || col === MODULE_COUNT - 1;
      const inner = !isBorder && bits[row - 1][col - 1] === 1;
      const isBlack = isBorder || !inner;
      if (isBlack) {
        for (let py = 0; py < modulePixels; py += 1) {
          for (let px = 0; px < modulePixels; px += 1) {
            const idx = ((row * modulePixels + py) * side + (col * modulePixels + px)) * 3;
            raw[idx] = 0;
            raw[idx + 1] = 0;
            raw[idx + 2] = 0;
          }
        }
      }
    }
  }
  return sharp(raw, { raw: { width: side, height: side, channels: 3 } })
    .png()
    .toBuffer();
}

export interface ArucoMarkerAsset {
  id: ArucoId;
  buffer: Buffer;
  pngWidth: number;
  pngHeight: number;
}

export async function generateArUcoMarkers(modulePixels = 8): Promise<ArucoMarkerAsset[]> {
  const ids = [ArucoId.TOP_LEFT, ArucoId.TOP_RIGHT, ArucoId.BOTTOM_RIGHT, ArucoId.BOTTOM_LEFT];
  const assets: ArucoMarkerAsset[] = [];
  for (const id of ids) {
    const buffer = await arUcoPngBuffer(id, modulePixels);
    assets.push({
      id,
      buffer,
      pngWidth: MODULE_COUNT * modulePixels,
      pngHeight: MODULE_COUNT * modulePixels,
    });
  }
  return assets;
}
