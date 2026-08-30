# ---- Build stage ----
FROM node:20-alpine AS builder

WORKDIR /app

RUN apk add --no-cache python3 make g++

# Install dependencies first so this layer caches across code changes.
COPY package.json package-lock.json* ./
RUN npm install --omit=dev
RUN useradd -m connexxiongroup

COPY . .

# ---- Runtime stage ----
FROM node:20-alpine

WORKDIR /app

COPY --from=builder /app ./

ENV NODE_ENV=production
ENV PORT=3000
EXPOSE 3000

USER connexxiongroup

CMD ["node", "src/server.js"]