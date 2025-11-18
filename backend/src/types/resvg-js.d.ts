declare module '@resvg/resvg-js' {
  export class Resvg {
    constructor(svg: string, options?: unknown);
    render(): { asPng(): Uint8Array };
  }
}
