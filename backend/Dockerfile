# --- builder ---
FROM node:20-bookworm-slim AS builder
WORKDIR /app
RUN apt-get update && apt-get install -y --no-install-recommends \
  openssl \
  ca-certificates \
  && rm -rf /var/lib/apt/lists/*

COPY package*.json ./
RUN npm ci

COPY prisma ./prisma
RUN npx prisma generate

COPY . .
RUN npm run build

# --- runtime ---
FROM node:20-bookworm-slim
WORKDIR /app

# Prisma/engines necesitan OpenSSL disponible
RUN apt-get update && apt-get install -y --no-install-recommends \
  openssl \
  ca-certificates \
  fontconfig \
  fonts-dejavu-core \
  fonts-liberation \
  && rm -rf /var/lib/apt/lists/* \
  && fc-cache -f

COPY --from=builder /app/package*.json ./
COPY --from=builder /app/node_modules ./node_modules
COPY --from=builder /app/prisma ./prisma
COPY --from=builder /app/dist ./dist
COPY --from=builder /app/entrypoint-backend.sh ./entrypoint-backend.sh
COPY --from=builder /app/entrypoint-migrate.sh ./entrypoint-migrate.sh

RUN npm prune --omit=dev

RUN chmod +x /app/entrypoint-backend.sh /app/entrypoint-migrate.sh

ENTRYPOINT ["/app/entrypoint-backend.sh"]
CMD ["node", "dist/main.js"]
