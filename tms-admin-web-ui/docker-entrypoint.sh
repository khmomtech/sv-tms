#!/bin/sh
# Runtime environment configuration script for Docker deployments
# This script generates env.js from environment variables at container startup

set -e

# Output file path
ENV_FILE="/usr/share/nginx/html/assets/env.js"

echo "🔧 Generating runtime environment configuration..."

# Generate env.js from environment variables
cat > "$ENV_FILE" << EOF
(function(window) {
  window.__env = {
    production: ${ENVIRONMENT:-true},
    baseUrl: '${BASE_URL:-}',
    apiBaseUrl: '${API_BASE_URL:-/api}',
    wsSocketUrl: '${WS_SOCKET_URL:-/ws}',
    sockJsUrl: '${SOCKJS_URL:-/ws-sockjs}',
    telematicsWsSocketUrl: '${TELEMATICS_WS_SOCKET_URL:-/tele-ws}',
    telematicsSockJsUrl: '${TELEMATICS_SOCKJS_URL:-/tele-ws-sockjs}',
    useSockJs: ${USE_SOCKJS:-true},
    googleMapsApiKey: '${GOOGLE_MAPS_API_KEY:-}',
    firebase: {
      apiKey: '${FIREBASE_API_KEY:-}',
      authDomain: '${FIREBASE_AUTH_DOMAIN:-}',
      databaseURL: '${FIREBASE_DATABASE_URL:-}',
      projectId: '${FIREBASE_PROJECT_ID:-}',
      storageBucket: '${FIREBASE_STORAGE_BUCKET:-}',
      messagingSenderId: '${FIREBASE_MESSAGING_SENDER_ID:-}',
      appId: '${FIREBASE_APP_ID:-}',
      measurementId: '${FIREBASE_MEASUREMENT_ID:-}'
    },
    sentryDsn: '${SENTRY_DSN:-}',
    version: '${APP_VERSION:-0.0.0}',
    useServerPagingPartners: ${USE_SERVER_PAGING_PARTNERS:-false},
    useVendorApiPaths: ${USE_VENDOR_API_PATHS:-true},
    vendorDisplayTerm: '${VENDOR_DISPLAY_TERM:-Vendor}'
  };
})(window);
EOF

echo "Environment configuration generated successfully"

# Validate required secrets
validate_config() {
  local missing=0

  if [ -z "$GOOGLE_MAPS_API_KEY" ]; then
    echo "⚠️  WARNING: GOOGLE_MAPS_API_KEY not set - maps will not work"
    missing=$((missing + 1))
  fi

  if [ -z "$FIREBASE_API_KEY" ]; then
    echo "⚠️  WARNING: FIREBASE_API_KEY not set - authentication may fail"
    missing=$((missing + 1))
  fi

  if [ -z "$SENTRY_DSN" ]; then
    echo "ℹ️  INFO: SENTRY_DSN not set - error monitoring disabled"
  fi

  if [ $missing -gt 0 ]; then
    echo "⚠️  $missing required configuration(s) missing"
    echo "   Check docs/SECRET_MANAGEMENT.md for setup instructions"
  fi
}

validate_config

echo "🚀 Starting nginx..."
exec nginx -g 'daemon off;'
