# Secret Management Guide

This guide explains how to manage sensitive configuration and API keys in the TMS Frontend application.

## Overview

The application uses **runtime environment configuration** to externalize secrets and configuration from the codebase. This approach:

- Keeps secrets out of version control
- Allows different configurations per environment (dev, staging, production)
- Enables configuration changes without rebuilding the application
- Supports container deployments with environment variables

## How It Works

### 1. Runtime Configuration Loading

The application loads configuration at runtime from `window.__env` object, which is set by loading `env.js` in `index.html`:

```html
<!-- Load runtime environment before app bootstrap -->
<script src="assets/env.js"></script>
```

### 2. Configuration Flow

```
env.template.js (template) 
  → env.js (your actual config, git-ignored)
    → window.__env (runtime object)
      → environment.ts (Angular environment)
        → Application services
```

## Setup Instructions

### Development Environment

1. **Copy the template file:**
   ```bash
   cd tms-frontend/src/assets
   cp env.template.js env.js
   ```

2. **Edit `env.js` with your actual values:**
   ```javascript
   (function (window) {
     window.__env = {
       production: false,
       apiBaseUrl: 'http://localhost:8080',
       googleMapsApiKey: 'AIza...your-key-here',
       firebase: {
         apiKey: 'AIza...your-firebase-key',
         authDomain: 'your-project.firebaseapp.com',
         projectId: 'your-project-id',
         // ... other Firebase config
       },
       sentryDsn: 'https://...@sentry.io/...',
       version: '1.0.0'
     };
   })(window);
   ```

3. **The file is git-ignored** - it won't be committed to version control

### Production/Docker Environment

For production deployments, you can:

#### Option 1: Inject at Build Time

Create `env.js` during Docker build using ARG/ENV:

```dockerfile
# Dockerfile
ARG GOOGLE_MAPS_API_KEY
ARG FIREBASE_API_KEY
ARG SENTRY_DSN

RUN echo "(function(window){window.__env={production:true,googleMapsApiKey:'${GOOGLE_MAPS_API_KEY}',firebase:{apiKey:'${FIREBASE_API_KEY}'},sentryDsn:'${SENTRY_DSN}'};})(window);" > dist/tms-frontend/assets/env.js
```

#### Option 2: Inject at Runtime (Recommended)

Replace `env.js` at container startup using environment variables:

```bash
#!/bin/sh
# entrypoint.sh

# Generate env.js from environment variables
cat > /usr/share/nginx/html/assets/env.js << EOF
(function(window) {
  window.__env = {
    production: true,
    apiBaseUrl: '${API_BASE_URL}',
    googleMapsApiKey: '${GOOGLE_MAPS_API_KEY}',
    firebase: {
      apiKey: '${FIREBASE_API_KEY}',
      authDomain: '${FIREBASE_AUTH_DOMAIN}',
      projectId: '${FIREBASE_PROJECT_ID}',
      storageBucket: '${FIREBASE_STORAGE_BUCKET}',
      messagingSenderId: '${FIREBASE_MESSAGING_SENDER_ID}',
      appId: '${FIREBASE_APP_ID}',
      measurementId: '${FIREBASE_MEASUREMENT_ID}'
    },
    sentryDsn: '${SENTRY_DSN}',
    version: '${APP_VERSION}'
  };
})(window);
EOF

# Start nginx
nginx -g 'daemon off;'
```

Then in docker-compose:

```yaml
services:
  tms-frontend:
    image: tms-frontend:latest
    environment:
      - API_BASE_URL=https://api.example.com
      - GOOGLE_MAPS_API_KEY=${GOOGLE_MAPS_API_KEY}
      - FIREBASE_API_KEY=${FIREBASE_API_KEY}
      - SENTRY_DSN=${SENTRY_DSN}
    env_file:
      - .env.production
```

## Configuration Reference

### Required Secrets

| Variable | Description | Example | Required |
|----------|-------------|---------|----------|
| `googleMapsApiKey` | Google Maps JavaScript API key | `AIzaSyB...` | Yes (for maps) |
| `firebase.apiKey` | Firebase API key | `AIzaSyC...` | Yes (for auth) |
| `firebase.projectId` | Firebase project ID | `tms-prod-123` | Yes |
| `sentryDsn` | Sentry error tracking DSN | `https://abc@sentry.io/123` | Recommended |

### Optional Configuration

| Variable | Description | Default | Notes |
|----------|-------------|---------|-------|
| `apiBaseUrl` | Backend API base URL | `/api` | Use proxy in dev |
| `wsSocketUrl` | WebSocket endpoint | `/ws` | For real-time tracking |
| `production` | Production mode flag | `false` | Enables optimizations |
| `version` | App version for tracking | `0.0.0` | Shown in UI/logs |
| `useServerPagingPartners` | Enable server-side pagination | `false` | Feature flag |
| `useVendorApiPaths` | Use vendor endpoints | `true` | API path selection |
| `vendorDisplayTerm` | Display term for vendors | `Vendor` | UI customization |

## Security Best Practices

### DO

- **Keep `env.js` out of version control** - it's in `.gitignore`
- **Use environment-specific values** - different keys for dev/staging/prod
- **Rotate keys regularly** - especially API keys
- **Use restricted API keys** - limit by domain/IP/referrer
- **Store secrets in CI/CD secrets** - GitHub Secrets, AWS Secrets Manager, etc.
- **Use runtime injection** - don't bake secrets into Docker images

### ❌ DON'T

- ❌ **Never commit `env.js`** to version control
- ❌ **Don't hardcode secrets** in environment.ts
- ❌ **Don't use production keys in development**
- ❌ **Don't share secrets via email/Slack**
- ❌ **Don't log secrets** - they're sanitized by LoggerService

## Verifying Configuration

### Check Loaded Configuration

Open browser console:

```javascript
// View current configuration
console.log(window.__env);

// Check if secrets are loaded (don't log the actual values!)
console.log('Maps API:', !!window.__env.googleMapsApiKey);
console.log('Firebase:', !!window.__env.firebase?.apiKey);
console.log('Sentry:', !!window.__env.sentryDsn);
```

### Validate in Code

The `EnvironmentService` provides runtime access to configuration:

```typescript
import { EnvironmentService } from '@app/core/environment.service';

constructor(private envService: EnvironmentService) {
  // Check if Firebase is configured
  if (!this.envService.get('firebase.apiKey')) {
    console.warn('Firebase not configured');
  }
}
```

## CI/CD Integration

### GitHub Actions

Add secrets to repository settings, then use in workflow:

```yaml
# .github/workflows/deploy.yml
- name: Generate runtime config
  run: |
    cat > dist/tms-frontend/assets/env.js << EOF
    (function(window){
      window.__env = {
        production: true,
        googleMapsApiKey: '${{ secrets.GOOGLE_MAPS_API_KEY }}',
        firebase: {
          apiKey: '${{ secrets.FIREBASE_API_KEY }}',
          authDomain: '${{ secrets.FIREBASE_AUTH_DOMAIN }}',
          projectId: '${{ secrets.FIREBASE_PROJECT_ID }}'
        },
        sentryDsn: '${{ secrets.SENTRY_DSN }}'
      };
    })(window);
    EOF
```

## Troubleshooting

### Issue: Configuration not loading

**Symptoms:** App shows blank maps, Firebase errors, "undefined" configurations

**Solutions:**
1. Check `env.js` exists in `src/assets/`
2. Verify `index.html` loads `env.js` before app bootstrap
3. Check browser console for `window.__env` object
4. Verify no JavaScript errors blocking script execution

### Issue: Wrong environment values

**Symptoms:** Dev using prod keys, or vice versa

**Solutions:**
1. Check which `env.js` is deployed
2. Verify environment variable injection in CI/CD
3. Clear browser cache and hard reload (Cmd+Shift+R)
4. Check Docker volume mounts aren't overwriting `env.js`

### Issue: Secrets exposed in logs

**Symptoms:** API keys visible in console/Sentry

**Solutions:**
1. LoggerService automatically sanitizes passwords/tokens/keys
2. Never `console.log()` raw config objects
3. Use `logger.debug()` instead, which filters secrets
4. Review Sentry breadcrumbs configuration

## Migration from Hardcoded Secrets

If you have hardcoded secrets in `environment.ts` or `environment.prod.ts`:

1. **Identify all secrets:**
   ```bash
   grep -r "apiKey\|secret\|token" src/app/environments/
   ```

2. **Move to `env.template.js`:**
   - Add entries to template
   - Update `environment.ts` to read from `window.__env`

3. **Test locally:**
   ```bash
   cp src/assets/env.template.js src/assets/env.js
   # Edit env.js with real values
   npm start
   ```

4. **Update deployments:**
   - Add environment variables to CI/CD
   - Update Docker configs
   - Test in staging first

5. **Remove from codebase:**
   ```bash
   # Clear Git history (optional, advanced)
   git filter-branch --force --index-filter \
     "git rm --cached --ignore-unmatch src/assets/env.js" \
     --prune-empty --tag-name-filter cat -- --all
   ```

## Related Files

- `src/assets/env.template.js` - Template with empty values
- `src/assets/env.js` - Your actual config (git-ignored)
- `src/app/environments/environment.ts` - Reads from `window.__env`
- `src/index.html` - Loads `env.js` at runtime
- `.gitignore` - Excludes `env.js` from version control
- `nginx.conf` - Serves `env.js` with no-cache headers

## Support

For questions or issues with secret management:
1. Check this guide first
2. Review `environment.ts` implementation
3. Check Docker/CI logs for injection issues
4. Open an issue with "Secret Management" tag
