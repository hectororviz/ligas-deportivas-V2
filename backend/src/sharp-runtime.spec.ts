import * as sharp from 'sharp';

describe('sharp runtime interop', () => {
  it('reads metadata from an in-memory PNG buffer', async () => {
    const pngBuffer = await sharp({
      create: {
        width: 1,
        height: 1,
        channels: 4,
        background: { r: 255, g: 255, b: 255, alpha: 1 }
      }
    })
      .png()
      .toBuffer();

    const metadata = await sharp(pngBuffer).metadata();

    expect(metadata.format).toBe('png');
    expect(metadata.width).toBe(1);
    expect(metadata.height).toBe(1);
  });
});
