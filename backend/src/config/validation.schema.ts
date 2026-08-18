import * as Joi from 'joi';

export const validationSchema = Joi.object({
  DATABASE_URL: Joi.string().uri().required(),
  JWT_ACCESS_SECRET: Joi.string().min(16).required(),
  JWT_REFRESH_SECRET: Joi.string().min(16).required(),
  JWT_ACCESS_TTL: Joi.number().integer().min(60).default(900),
  JWT_REFRESH_TTL: Joi.number().integer().min(3600).default(604800),
  APP_URL: Joi.string().uri().default('http://localhost:3000'),
  FRONTEND_URL: Joi.string().uri().default('http://localhost:4200'),
  AUTO_REFRESH_INTERVAL: Joi.number().integer().min(1).default(10),
  STORAGE_BASE_URL: Joi.string().allow(''),
  STORAGE_BUCKET: Joi.string().allow(''),
  STORAGE_ACCESS_KEY: Joi.string().allow(''),
  STORAGE_SECRET_KEY: Joi.string().allow(''),
  DB_SCHEMA_ENFORCEMENT: Joi.string().valid('strict', 'soft').default('strict'),
  DNI_SCAN_DEBUG: Joi.boolean().optional(),
  SCAN_DEBUG: Joi.boolean().optional(),
  SCAN_DEBUG_KEEP_TMP: Joi.boolean().optional(),
  DNI_SCAN_DECODER_COMMAND: Joi.string().allow(''),
  SCAN_DEADLINE_MS: Joi.number().integer().min(1).optional(),
  SCAN_DECODER_TIMEOUT_MS: Joi.number().integer().min(1).optional(),
});
