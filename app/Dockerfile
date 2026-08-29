# Small, official base image; alpine keeps the image lean for this lab.
FROM node:20-alpine

WORKDIR /usr/src/app

# Install dependencies first so this layer caches across code changes.
COPY package.json package-lock.json* ./
RUN npm install --omit=dev

COPY . .

ENV NODE_ENV=production
ENV PORT=3000
EXPOSE 3000

# Runs as the non-root "node" user baked into the official image —
# avoids running the app as root inside the container.
USER node

CMD ["node", "src/server.js"]
