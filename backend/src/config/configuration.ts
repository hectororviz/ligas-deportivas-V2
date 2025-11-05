const removeTrailingSlash = (value: string) => value.replace(/\/$/, '');

const normalizeOptionalString = (value?: string) => {
  if (value === undefined || value === null) {
    return '';
  }

  const trimmed = value.trim();
  if (trimmed.length === 0) {
    return '';
  }

  const lowered = trimmed.toLowerCase();
  if (['null', 'undefined', 'false', '0', 'off', 'no'].includes(lowered)) {
    return '';
  }

  return trimmed;
};

const normalizeString = (value?: string, fallback = '') => {
  if (value === undefined || value === null) {
    return fallback;
  }

  const trimmed = value.trim();
  if (trimmed.length === 0) {
    return fallback;
  }

  return trimmed;
};

const removeInlineComment = (value: string) => {
  const commentIndex = value.indexOf('#');
  if (commentIndex === -1) {
    return value;
  }

  return value.slice(0, commentIndex).trim();
};

const resolveStorageBaseUrl = () => {
  const explicitBaseUrl = process.env.STORAGE_BASE_URL;
  if (explicitBaseUrl && explicitBaseUrl.trim().length > 0) {
    return removeTrailingSlash(explicitBaseUrl.trim());
  }

  const appUrl = removeTrailingSlash(process.env.APP_URL ?? 'http://localhost:3000');
  return `${appUrl}/storage`;
};

const resolveCaptchaProvider = () => {
  const provider = normalizeString(process.env.CAPTCHA_PROVIDER, 'turnstile');
  return provider.length > 0 ? provider : 'turnstile';
};

const resolveCaptchaSecret = () => normalizeOptionalString(process.env.CAPTCHA_SECRET);

const captchaSecret = resolveCaptchaSecret();

type MailServiceProvider = 'custom' | 'gmail';

const resolveMailService = (): MailServiceProvider => {
  const service = normalizeString(process.env.SMTP_SERVICE, 'custom').toLowerCase();
  return service === 'gmail' ? 'gmail' : 'custom';
};

const resolveMailHost = (service: MailServiceProvider) => {
  const host = process.env.SMTP_HOST;
  if (host) {
    const normalized = removeInlineComment(host).trim();
    if (normalized.length > 0) {
      return normalized;
    }
  }

  if (service === 'gmail') {
    return 'smtp.gmail.com';
  }

  return 'localhost';
};

const resolveMailPort = (service: MailServiceProvider) => {
  const port = normalizeString(process.env.SMTP_PORT);
  if (port.length > 0) {
    const parsed = parseInt(port, 10);
    if (Number.isFinite(parsed)) {
      return parsed;
    }
  }

  if (service === 'gmail') {
    return 465;
  }

  return 1025;
};

const resolveOptionalBoolean = (value?: string) => {
  if (value === undefined || value === null) {
    return undefined;
  }

  const normalized = value.trim().toLowerCase();
  if (normalized.length === 0) {
    return undefined;
  }

  if (['true', '1', 'yes', 'on'].includes(normalized)) {
    return true;
  }

  if (['false', '0', 'no', 'off'].includes(normalized)) {
    return false;
  }

  return undefined;
};

export default () => {
  const mailServiceProvider = resolveMailService();

  return {
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
      secret: captchaSecret,
      enabled: captchaSecret.length > 0
    },
    mail: {
      service: mailServiceProvider,
      host: resolveMailHost(mailServiceProvider),
      port: resolveMailPort(mailServiceProvider),
      user: process.env.SMTP_USER ?? '',
      pass: process.env.SMTP_PASS ?? '',
      from: process.env.SMTP_FROM ?? 'noreply@ligas.local',
      secure:
        resolveOptionalBoolean(process.env.SMTP_SECURE) ??
        (mailServiceProvider === 'gmail' ? true : undefined),
      requireTls: resolveOptionalBoolean(process.env.SMTP_REQUIRE_TLS),
      ignoreTls: resolveOptionalBoolean(process.env.SMTP_IGNORE_TLS),
      rejectUnauthorized: resolveOptionalBoolean(process.env.SMTP_TLS_REJECT_UNAUTHORIZED)
    },
    storage: {
      baseUrl: resolveStorageBaseUrl(),
      bucket: process.env.STORAGE_BUCKET ?? '',
      accessKey: process.env.STORAGE_ACCESS_KEY ?? '',
      secretKey: process.env.STORAGE_SECRET_KEY ?? ''
    }
  };
};
