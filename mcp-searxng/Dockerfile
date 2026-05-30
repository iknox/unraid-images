FROM node:lts-alpine AS builder

WORKDIR /app

# Clone the mcp-searxng fork at a pinned version
ARG MCP_SEARXNG_VERSION=main
RUN apk add --no-cache git && \
    git clone --depth 1 --branch ${MCP_SEARXNG_VERSION} \
    https://github.com/iknox/mcp-searxng.git /app && \
    rm -rf .git && \
    apk del git

RUN npm ci --ignore-scripts
RUN npm run build

FROM node:lts-alpine AS release

RUN apk update && apk upgrade

WORKDIR /app

COPY --from=builder /app/dist /app/dist
COPY --from=builder /app/package.json /app/package.json
COPY --from=builder /app/package-lock.json /app/package-lock.json

ENV NODE_ENV=production

RUN npm ci --ignore-scripts --omit=dev && npm cache clean --force

HEALTHCHECK --interval=30s --timeout=5s --start-period=5s --retries=3 \
  CMD node -e "require('http').get('http://localhost:${MCP_HTTP_PORT:-3000}/health', (r) => {process.exit(r.statusCode === 200 ? 0 : 1)})"

ENTRYPOINT ["node", "dist/index.js"]