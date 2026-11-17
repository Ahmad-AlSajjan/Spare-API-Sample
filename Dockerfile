FROM registry.access.redhat.com/hi/nodejs:24-builder AS builder

WORKDIR /app
COPY package.json package-lock.json ./
RUN npm ci --omit=dev

FROM registry.access.redhat.com/hi/nodejs:24

WORKDIR /app
COPY --from=builder /app/node_modules ./node_modules
COPY package.json ./
COPY src ./src

ENV NODE_ENV=production \
    PORT=8080

# Although the hardened image runs as non-privileged,  non-root UID is specified so it remains unpriviliged even on image change
USER 65532
EXPOSE 8080

# --format docker must be specified when using Podman, otherwise the check will not be included
HEALTHCHECK --interval=10s --timeout=3s --start-period=10s --retries=3 \
  CMD ["node", "-e", "fetch('http://127.0.0.1:8080/health').then(r=>process.exit(r.ok?0:1)).catch(()=>process.exit(1))"]

CMD ["node", "src/index.js"]
