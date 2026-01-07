import { BadRequestException } from '@nestjs/common';

export function validateFlyerImage(file: Express.Multer.File) {
  validateImageDimensions(file, {
    width: 1080,
    height: 1920,
    label: 'flyer',
  });
}

export function validateLoginImage(file: Express.Multer.File) {
  validateImageDimensions(file, {
    width: 320,
    height: 250,
    label: 'login',
  });
}

function validateImageDimensions(
  file: Express.Multer.File,
  options: { width: number; height: number; label: 'flyer' | 'login' },
) {
  if (!file || !file.buffer) {
    throw new BadRequestException(`El archivo de ${options.label} es inválido.`);
  }

  const allowed = ['image/png', 'image/jpeg'];
  if (!allowed.includes(file.mimetype)) {
    throw new BadRequestException(`La imagen de ${options.label} debe ser un PNG o JPG.`);
  }

  const buffer = file.buffer;
  const { width, height } =
    file.mimetype === 'image/png' ? readPngDimensions(buffer) : readJpegDimensions(buffer);

  if (width !== options.width || height !== options.height) {
    throw new BadRequestException(
      `La imagen de ${options.label} debe medir exactamente ${options.width}x${options.height} píxeles.`,
    );
  }

  if (file.size > 5 * 1024 * 1024) {
    throw new BadRequestException(
      `La imagen de ${options.label} supera el tamaño máximo permitido de 5 MB.`,
    );
  }
}

function readPngDimensions(buffer: Buffer) {
  if (buffer.length < 24) {
    throw new BadRequestException('El archivo de flyer es demasiado pequeño.');
  }
  return {
    width: buffer.readUInt32BE(16),
    height: buffer.readUInt32BE(20),
  };
}

function readJpegDimensions(buffer: Buffer) {
  let offset = 2;
  while (offset + 9 < buffer.length) {
    if (buffer[offset] !== 0xff) {
      break;
    }
    const marker = buffer[offset + 1];
    const length = buffer.readUInt16BE(offset + 2);
    if (length < 2) {
      break;
    }
    if (marker >= 0xc0 && marker <= 0xcf && marker !== 0xc4 && marker !== 0xcc) {
      if (offset + 7 >= buffer.length) {
        break;
      }
      const height = buffer.readUInt16BE(offset + 5);
      const width = buffer.readUInt16BE(offset + 7);
      return { width, height };
    }
    offset += 2 + length;
  }
  throw new BadRequestException('No se pudo leer las dimensiones del flyer.');
}
