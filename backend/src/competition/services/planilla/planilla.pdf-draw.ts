import { A4_HEIGHT } from './template-v1.definitions';

/**
 * Generador de comandos de contenido PDF (graphics operators) con origen de
 * coordenadas en la esquina superior izquierda y con soporte para insertar
 * imágenes PNG. Reutilizado exclusivamente para la planilla TEMPLATE 1.
 */
export class PlanillaPdfDraw {
  private commands: string[] = ['0.4 w'];

  rectTop(x: number, topY: number, width: number, height: number) {
    this.commands.push(
      `${this.f(x)} ${this.f(this.toPdfY(topY + height))} ${this.f(width)} ${this.f(height)} re S`,
    );
  }

  line(x1: number, y1: number, x2: number, y2: number) {
    this.commands.push(
      `${this.f(x1)} ${this.f(this.toPdfY(y1))} m ${this.f(x2)} ${this.f(this.toPdfY(y2))} l S`,
    );
  }

  setDash(pattern: string) {
    this.commands.push(pattern);
  }

  setLineWidth(width: number) {
    this.commands.push(`${this.f(width)} w`);
  }

  text(value: string, x: number, topY: number, size: number, bold = false) {
    const normalized = this.normalizeText(value);
    if (!normalized) {
      return;
    }
    const y = this.toPdfY(topY + size);
    this.commands.push(
      `BT /F1 ${bold ? this.f(size + 0.2) : this.f(size)} Tf ${this.f(x)} ${this.f(y)} Td (${normalized}) Tj ET`,
    );
  }

  textCentered(value: string, x: number, topY: number, width: number, size: number, bold = false) {
    const normalized = this.normalizeText(value);
    if (!normalized) {
      return;
    }
    const approxWidth = normalized.length * size * 0.48;
    const left = x + Math.max(0, (width - approxWidth) / 2);
    this.text(normalized, left, topY, size, bold);
  }

  textRight(value: string, rightX: number, topY: number, size: number, bold = false) {
    const normalized = this.normalizeText(value);
    if (!normalized) {
      return;
    }
    const approxWidth = normalized.length * size * 0.48;
    this.text(normalized, rightX - approxWidth, topY, size, bold);
  }

  image(name: string, x: number, topY: number, width: number, height: number) {
    const y = this.toPdfY(topY + height);
    this.commands.push(
      `q ${this.f(width)} 0 0 ${this.f(height)} ${this.f(x)} ${this.f(y)} cm /${name} Do Q`,
    );
  }

  build() {
    return this.commands.join('\n');
  }

  private toPdfY(topValue: number) {
    return A4_HEIGHT - topValue;
  }

  private f(value: number) {
    return value.toFixed(2);
  }

  private normalizeText(value: string) {
    return value
      .replace(/[\u2018\u2019]/g, "'")
      .replace(/[\u201C\u201D]/g, '"')
      .replace(/[–—]/g, '-')
      .replace(/á/g, 'a')
      .replace(/é/g, 'e')
      .replace(/í/g, 'i')
      .replace(/ó/g, 'o')
      .replace(/ú/g, 'u')
      .replace(/Á/g, 'A')
      .replace(/É/g, 'E')
      .replace(/Í/g, 'I')
      .replace(/Ó/g, 'O')
      .replace(/Ú/g, 'U')
      .replace(/ñ/g, 'n')
      .replace(/Ñ/g, 'N')
      .replace(/º/g, 'o')
      .replace(/[\r\n\t]/g, ' ')
      .replace(/\\/g, '\\\\')
      .replace(/\(/g, '\\(')
      .replace(/\)/g, '\\)')
      .trim();
  }
}
