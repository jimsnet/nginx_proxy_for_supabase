#!/bin/sh
set -e

# Substitute environment variables in nginx config template
envsubst '${FRONTEND_DOMAIN},${ENABLE_LOCALHOST_CORS}' < /etc/nginx/nginx.conf.template > /etc/nginx/nginx.conf

# Start nginx in foreground
exec nginx -g "daemon off;"
