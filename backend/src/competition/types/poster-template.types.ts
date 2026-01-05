export type PosterLayerType = 'text' | 'image' | 'shape';

export interface PosterTemplate {
  layers: PosterLayer[];
}

export interface PosterLayerBase {
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
