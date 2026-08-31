# ---- Build stage ----
FROM node:20-alpine AS builder

WORKDIR /app

RUN apk add --no-cache python3 make g++

# Install dependencies first so this layer caches across code changes.
COPY package.json package-lock.json* ./
RUN npm install --omit=dev

COPY . .

# ---- Runtime stage ----
FROM node:20-alpine

WORKDIR /app

COPY --from=builder /app ./

ENV NODE_ENV=production
ENV PORT=3000
EXPOSE 3000

# -D = no password
RUN adduser -D connexxiongroup

# Pre-create the data directory with the right ownership
RUN mkdir -p /app/data && chown connexxiongroup:connexxiongroup /app/data

USER connexxiongroup

ENTRYPOINT ["node"]
CMD ["src/server.js"]