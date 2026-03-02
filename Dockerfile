# Dockerfile

FROM nginx:alpine

# ENV FRONTEND_DOMAIN=frontend_url_placeholder
# ENV ENABLE_LOCALHOST_CORS=0

# Install envsubst (comes with gettext)
RUN apk add --no-cache gettext

# Remove default config
RUN rm /etc/nginx/conf.d/default.conf || true

# Copy nginx template
COPY fgs-nginx.conf /etc/nginx/nginx.conf.template

# Copy entrypoint script
COPY docker-entrypoint.sh /docker-entrypoint.sh
RUN chmod +x /docker-entrypoint.sh

# Expose port 8080
EXPOSE 8080

# Run entrypoint script
ENTRYPOINT ["/docker-entrypoint.sh"]
