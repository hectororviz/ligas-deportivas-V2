import { Prisma } from '@prisma/client';

export type PosterLayerType = 'text' | 'image' | 'shape';

export interface PosterTemplate extends Prisma.JsonObject {
  width?: number;
  height?: number;
  layers: PosterLayer[];
}

export interface PosterLayerBase extends Prisma.JsonObject {
  id: string;
  type: PosterLayerType;
  x: number;
  y: number;
  width: number;
  height: number;
  rotation?: number;
  opacity?: number;
  zIndex?: number;
  locked?: boolean;
}

export interface PosterTextLayer extends PosterLayerBase {
  type: 'text';
  text: string;
  fontSize?: number;
  fontFamily?: string;
  fontWeight?: number | string;
  fontStyle?: string;
  color?: string;
  align?: 'left' | 'center' | 'right';
  strokeColor?: string;
  strokeWidth?: number;
}

export interface PosterImageLayer extends PosterLayerBase {
  type: 'image';
  src: string;
  fit?: 'cover' | 'contain';
  isBackground?: boolean;
}

export interface PosterShapeLayer extends PosterLayerBase {
  type: 'shape';
  shape?: 'rect';
  fill?: string;
  strokeColor?: string;
  strokeWidth?: number;
  radius?: number;
}

export type PosterLayer = PosterTextLayer | PosterImageLayer | PosterShapeLayer;

const isJsonObject = (value: Prisma.JsonValue): value is Prisma.JsonObject =>
  typeof value === 'object' && value !== null && !Array.isArray(value);

export const ensurePosterTemplate = (
  value: Prisma.JsonValue,
  defaults: { width?: number; height?: number } = {},
): PosterTemplate => {
  if (!isJsonObject(value)) {
    throw new Error('La plantilla debe ser un objeto JSON.');
  }

  const layers = value.layers;
  if (!Array.isArray(layers)) {
    throw new Error('La plantilla debe incluir un listado de capas.');
  }

  const template: PosterTemplate = {
    ...value,
    layers: layers as PosterLayer[],
  };

  if (template.width == null && defaults.width != null) {
    template.width = defaults.width;
  }
  if (template.height == null && defaults.height != null) {
    template.height = defaults.height;
  }

  return template;
};
