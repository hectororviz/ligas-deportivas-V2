import { MatchFlyerService } from './match-flyer.service';

describe('MatchFlyerService template rendering', () => {
  const service = new MatchFlyerService({} as any, {} as any);

  it('replaces encoded braces before parsing the template', () => {
    const template = 'Torneo &#123;&#123;tournament.name&#125;&#125;';
    const context = { tournament: { name: 'Apertura 2024' } } as any;

    const result = (service as any).renderTemplate(template, context);

    expect(result).toBe('Torneo Apertura 2024');
  });

  it('supports triple encoded braces for raw variables', () => {
    const template = '<image href="&#123;&#123;&#123;assets.homeLogo&#125;&#125;&#125;" />';
    const context = { assets: { homeLogo: 'data:image/png;base64,abc123' } } as any;

    const result = (service as any).renderTemplate(template, context);

    expect(result).toContain('data:image/png;base64,abc123');
    expect(result.includes('&#123;')).toBe(false);
  });
});
