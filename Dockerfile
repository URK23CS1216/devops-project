# ================================
# Stage 1: Builder
# ================================
FROM node:20-alpine AS builder

LABEL maintainer="DevOps Demo Team"
LABEL org.opencontainers.image.source="https://github.com/your-org/devops-demo"
LABEL org.opencontainers.image.description="Production-grade Node.js DevOps Demo Application"

WORKDIR /app

# Copy package files first for better layer caching
COPY package.json package-lock.json* ./

# Install ALL dependencies (including dev for testing)
RUN npm ci --no-audit --no-fund

# Copy source code
COPY . .

# Run linting and tests
RUN npm run lint && npm test

# Remove dev dependencies for production image
RUN npm ci --omit=dev --no-audit --no-fund

# ================================
# Stage 2: Production
# ================================
FROM node:20-alpine AS production

# Security: add labels
LABEL org.opencontainers.image.title="devops-demo"
LABEL org.opencontainers.image.version="1.0.0"

# Install dumb-init for proper signal handling
RUN apk add --no-cache dumb-init

# Security: create non-root user
RUN addgroup -g 1001 -S appgroup && \
    adduser -S appuser -u 1001 -G appgroup

WORKDIR /app

# Copy only production artifacts from builder
COPY --from=builder --chown=appuser:appgroup /app/node_modules ./node_modules
COPY --from=builder --chown=appuser:appgroup /app/src ./src
COPY --from=builder --chown=appuser:appgroup /app/package.json ./

# Set environment variables
ENV NODE_ENV=production
ENV PORT=3000

# Build metadata (overridden at build time)
ARG BUILD_DATE=unknown
ARG COMMIT_SHA=unknown
ARG IMAGE_TAG=latest
ENV BUILD_DATE=${BUILD_DATE}
ENV COMMIT_SHA=${COMMIT_SHA}
ENV IMAGE_TAG=${IMAGE_TAG}

# Switch to non-root user
USER appuser

# Expose port
EXPOSE 3000

# Health check
HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
  CMD wget --no-verbose --tries=1 --spider http://localhost:3000/api/health || exit 1

# Use dumb-init as entrypoint for proper signal handling
ENTRYPOINT ["dumb-init", "--"]

# Start the application
CMD ["node", "src/server.js"]
