# ---- Build stage ----
FROM node:24-alpine AS builder

WORKDIR /app

RUN apk add --no-cache python3 make g++

# Install dependencies first so this layer caches across code changes.
COPY package.json package-lock.json* ./
RUN npm install --omit=dev

COPY . .

# ---- Runtime stage ----
FROM node:24-alpine

WORKDIR /app

COPY --from=builder /app ./

ENV NODE_ENV=production
ENV PORT=3000
EXPOSE 3000

RUN mkdir -p /usr/src/app/data && chown connexxiongroup:connexxiongroup /usr/src/app/data

USER connexxiongroup

CMD ["node", "src/server.js"]