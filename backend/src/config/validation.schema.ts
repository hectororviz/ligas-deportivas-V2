import * as Joi from 'joi';

export const validationSchema = Joi.object({
  DATABASE_URL: Joi.string().uri().required(),
  JWT_ACCESS_SECRET: Joi.string().min(16).required(),
  JWT_REFRESH_SECRET: Joi.string().min(16).required(),
  JWT_ACCESS_TTL: Joi.number().integer().min(60).default(900),
  JWT_REFRESH_TTL: Joi.number().integer().min(3600).default(604800),
  CAPTCHA_PROVIDER: Joi.string().valid('hcaptcha', 'turnstile').default('turnstile'),
  CAPTCHA_SECRET: Joi.string().allow(''),
  SMTP_HOST: Joi.string().default('localhost'),
  SMTP_PORT: Joi.number().integer().default(1025),
  SMTP_USER: Joi.string().allow(''),
  SMTP_PASS: Joi.string().allow(''),
  SMTP_FROM: Joi.string().email({ tlds: false }).default('noreply@ligas.local'),
  APP_URL: Joi.string().uri().default('http://localhost:3000'),
  FRONTEND_URL: Joi.string().uri().default('http://localhost:4200'),
  AUTO_REFRESH_INTERVAL: Joi.number().integer().min(1).default(10),
  STORAGE_BASE_URL: Joi.string().allow(''),
  STORAGE_BUCKET: Joi.string().allow(''),
  STORAGE_ACCESS_KEY: Joi.string().allow(''),
  STORAGE_SECRET_KEY: Joi.string().allow('')
});
