const removeTrailingSlash = (value: string) => value.replace(/\/$/, '');

const resolveStorageBaseUrl = () => {
  const explicitBaseUrl = process.env.STORAGE_BASE_URL;
  if (explicitBaseUrl && explicitBaseUrl.trim().length > 0) {
    return removeTrailingSlash(explicitBaseUrl.trim());
  }

  const appUrl = removeTrailingSlash(process.env.APP_URL ?? 'http://localhost:3000');
  return `${appUrl}/storage`;
};

const resolveCaptchaProvider = () => {
  const provider = (process.env.CAPTCHA_PROVIDER ?? 'turnstile').trim();
  return provider.length > 0 ? provider : 'turnstile';
};

export default () => ({
  app: {
    port: parseInt(process.env.PORT ?? '3000', 10),
    url: process.env.APP_URL ?? 'http://localhost:3000',
    frontendUrl: process.env.FRONTEND_URL ?? 'http://localhost:4200',
    autoRefreshInterval: parseInt(process.env.AUTO_REFRESH_INTERVAL ?? '10', 10)
  },
  database: {
    url: process.env.DATABASE_URL
  },
  auth: {
    accessSecret: process.env.JWT_ACCESS_SECRET ?? 'access-secret',
    refreshSecret: process.env.JWT_REFRESH_SECRET ?? 'refresh-secret',
    accessTtl: parseInt(process.env.JWT_ACCESS_TTL ?? '900', 10),
    refreshTtl: parseInt(process.env.JWT_REFRESH_TTL ?? '604800', 10)
  },
  captcha: {
    provider: resolveCaptchaProvider(),
    secret: process.env.CAPTCHA_SECRET?.trim() ?? ''
  },
  mail: {
    host: process.env.SMTP_HOST ?? 'localhost',
    port: parseInt(process.env.SMTP_PORT ?? '1025', 10),
    user: process.env.SMTP_USER ?? '',
    pass: process.env.SMTP_PASS ?? '',
    from: process.env.SMTP_FROM ?? 'noreply@ligas.local'
  },
  storage: {
    baseUrl: resolveStorageBaseUrl(),
    bucket: process.env.STORAGE_BUCKET ?? '',
    accessKey: process.env.STORAGE_ACCESS_KEY ?? '',
    secretKey: process.env.STORAGE_SECRET_KEY ?? ''
  }
});
