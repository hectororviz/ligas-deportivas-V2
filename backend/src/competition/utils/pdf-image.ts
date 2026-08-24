import { promisify } from 'node:util';
import { deflateSync } from 'node:zlib';
import sharp = require('sharp');

const SVG_TO_PNG = promisify(
  (svg: string, callback: (err: Error | null, buffer?: Buffer) => void) => {
    try {
      sharp(Buffer.from(svg))
        .flatten({ background: '#ffffff' })
        .png()
        .toBuffer()
        .then((buffer) => callback(null, buffer))
        .catch((error) => callback(error));
    } catch (error) {
      callback(error as Error);
    }
  },
);

export interface PdfImageObject {
  name: string;
  width: number;
  height: number;
  object: string;
}

/**
 * Construye un Image XObject a partir de un buffer PNG decodificado a píxeles
 * RGB crudos. Los píxeles se comprimen con FlateDecode (estándar en A4).
 */
export async function buildPngImageObject(png: Buffer): Promise<{
  width: number;
  height: number;
  object: string;
}> {
  const image = sharp(png).ensureAlpha().raw().toBuffer({ resolveWithObject: true });
  const { data, info } = await image;
  const width = info.width;
  const height = info.height;

  const rgb = Buffer.from(data); // RGBA
  const channels = 3;
  const rgbData = Buffer.alloc(width * height * channels);
  for (let i = 0; i < width * height; i += 1) {
    rgbData[i * 3] = rgb[i * 4];
    rgbData[i * 3 + 1] = rgb[i * 4 + 1];
    rgbData[i * 3 + 2] = rgb[i * 4 + 2];
  }

  const compressed = deflateSync(rgbData);
  const hex = `${compressed.toString('hex')}>`;
  const object = `<< /Type /XObject /Subtype /Image /Width ${width} /Height ${height} /ColorSpace /DeviceRGB /BitsPerComponent 8 /Filter [/ASCIIHexDecode /FlateDecode] /Length ${hex.length} >>\nstream\n${hex}\nendstream`;
  return { width, height, object };
}

export async function svgToPngBuffer(svg: string): Promise<Buffer> {
  return SVG_TO_PNG(svg);
}
