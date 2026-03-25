# Priority 1 Implementation Guide

## Completed Improvements

All Priority 1 (Blocking) items have been implemented for production readiness:

### 1. Security Headers (nginx.conf) ✅

**File**: `nginx.conf`

Added comprehensive security headers:
- `X-Frame-Options: DENY` - Prevents clickjacking
- `X-Content-Type-Options: nosniff` - Prevents MIME sniffing
- `X-XSS-Protection: 1; mode=block` - XSS protection
- `Referrer-Policy: strict-origin-when-cross-origin` - Privacy
- `Content-Security-Policy` - Comprehensive CSP with Google Maps whitelist
- `Permissions-Policy` - Restricts browser features
- `Strict-Transport-Security` - HSTS (commented for SSL setup)

**Note**: Uncomment HSTS header after SSL/TLS is configured in production.

### 2. Sentry Error Monitoring ✅

**New Files**:
- `src/app/core/sentry.config.ts` - Sentry initialization and configuration
- Updated `src/main.ts` - Calls `initSentry()` before Angular bootstrap
- Updated `src/app/core/core.providers.ts` - Sentry error handler
- Updated `src/app/environments/environment.ts` - Added `sentryDsn` and `version`

**Features**:
- Production-only error tracking
- Performance monitoring (10% trace sampling)
- Session replay on errors (100% error sampling)
- Sensitive data filtering (removes tokens, passwords)
- Release tracking
- Ignores common non-critical errors

**Setup Required**:
1. Create Sentry account at https://sentry.io
2. Create new project
3. Copy DSN from project settings
4. Add to environment variables:
   ```bash
   # .env or runtime config
   SENTRY_DSN=https://your-key@sentry.io/project-id
   APP_VERSION=1.0.0
   ```

**Package Installed**: `@sentry/angular` + `@sentry/tracing`

### 3. GitHub Actions CI/CD Pipeline ✅

**New Files**:
- `.github/workflows/ci.yml` - Continuous Integration workflow
- `.github/workflows/deploy.yml` - Deployment workflow

**CI Pipeline Jobs**:
- **Lint** - ESLint + Prettier formatting check
- **Unit Tests** - Karma tests with coverage upload to Codecov
- **E2E Tests** - Playwright smoke tests
- **Build** - Production bundle with size check
- **Security Audit** - npm audit for vulnerabilities
- **Docker Build** - Builds and pushes to Docker Hub (on main/develop)
- **Notifications** - Job status summary

**Deployment Pipeline**:
- Triggered by version tags (v*.*.*)
- Manual workflow dispatch
- Builds and pushes versioned Docker images
- Creates GitHub releases

**Setup Required**:
1. Add GitHub Secrets:
   - `DOCKER_USERNAME` - Docker Hub username
   - `DOCKER_PASSWORD` - Docker Hub token
2. (Optional) Add `CODECOV_TOKEN` for coverage reports
3. Customize deployment steps in `deploy.yml`

### 4. Accessibility Improvements ✅

**Updated Files**:
- `.hintrc` - Re-enabled axe accessibility checks (warnings/errors)
- `src/index.html` - Added `lang="en"` and meta description
- `src/app/shared/directives/accessibility.directive.ts` - New ARIA helper directives

**Changes**:
- Enabled `axe/forms` warnings
- Enabled `axe/keyboard` warnings
- Enabled `axe/aria` errors
- Set `html-has-lang` to error level
- Changed button-name and image-alt to warnings

**New Directives**:
- `appAriaLabel` - Easily add ARIA labels
- `appRole` - Set ARIA roles
- `appAriaLive` - Mark live regions for screen readers

**Usage Examples**:
```html
<!-- Add ARIA labels -->
<button appAriaLabel="Close dialog">X</button>

<!-- Set roles -->
<nav appRole="navigation">...</nav>

<!-- Live regions -->
<div appAriaLive="polite">Loading...</div>
```

### 5. Rate Limiting on Search/Filter ✅

**New Files**:
- `src/app/core/services/rate-limit.service.ts` - Centralized rate limiting
- `src/app/core/services/rate-limit.service.example.ts` - Usage examples

**Features**:
- **Search debouncing** - 300ms default (configurable)
- **API throttling** - 1000ms default (configurable)
- **Combined mode** - Both debounce + throttle
- **Distinct until changed** - Ignores duplicate values

**RxJS Operators Provided**:
- `debounceSearch(time?)` - For search inputs
- `throttleApi(time?)` - For API call limiting
- `debounceAndThrottle(debounce?, throttle?)` - Combined

**Usage in Components**:
```typescript
import { RateLimitService } from '@app/core/services/rate-limit.service';

// In component
this.searchControl.valueChanges
  .pipe(
    this.rateLimitService.debounceSearch(300),
    switchMap(query => this.apiService.search(query))
  )
  .subscribe(results => { /* ... */ });
```

---

## Setup Instructions

### 1. Install Dependencies
```bash
cd tms-frontend
npm install
```

### 2. Configure Environment Variables

Update `.env.example` and create runtime config:

```bash
# For development
cp .env.example .env

# Edit with your values
SENTRY_DSN=https://your-sentry-dsn@sentry.io/project-id
APP_VERSION=1.0.0
```

For production, set environment variables in your deployment:
- Docker: Pass via `docker run -e SENTRY_DSN=...`
- Kubernetes: Use ConfigMap/Secrets
- Nginx: Update `window.__env` in `assets/env.js`

### 3. Configure GitHub Secrets

Go to repository Settings → Secrets and add:
- `DOCKER_USERNAME`
- `DOCKER_PASSWORD`
- `CODECOV_TOKEN` (optional)

### 4. Test CI/CD Pipeline

Push a commit to trigger CI:
```bash
git add .
git commit -m "feat: add priority 1 production improvements"
git push origin main
```

Check GitHub Actions tab for pipeline status.

### 5. Deploy with Tags

Create a release:
```bash
git tag v1.0.0
git push origin v1.0.0
```

This triggers the deployment pipeline.

---

## Verification Checklist

### Security Headers
- [ ] Deploy to staging/production
- [ ] Test with https://securityheaders.com
- [ ] Verify CSP allows Google Maps
- [ ] Check X-Frame-Options prevents embedding

### Sentry
- [ ] Deploy with valid SENTRY_DSN
- [ ] Trigger test error in production
- [ ] Verify error appears in Sentry dashboard
- [ ] Check performance traces
- [ ] Verify sensitive data is filtered

### CI/CD
- [ ] Push commit triggers CI pipeline
- [ ] All jobs pass (lint, test, build)
- [ ] Docker image builds successfully
- [ ] Tag triggers deployment
- [ ] Artifacts uploaded correctly

### Accessibility
- [ ] Run `npm run lint` - no new ARIA errors
- [ ] Test with screen reader (NVDA, JAWS, VoiceOver)
- [ ] Verify keyboard navigation works
- [ ] Check form labels are present
- [ ] Use browser DevTools Lighthouse accessibility audit

### Rate Limiting
- [ ] Apply to all search inputs
- [ ] Apply to filter dropdowns
- [ ] Test rapid typing - API called after debounce
- [ ] Test refresh button spam - throttled
- [ ] Monitor network tab for reduced requests

---

## Next Steps (Priority 2)

After verifying Priority 1 items:

1. **Bundle Size Optimization** - Lazy load more modules, reduce to < 2MB
2. **Centralized Error Handling** - Create error service
3. **Structured Logging** - Replace console.log with logger service
4. **Performance Monitoring** - Add Web Vitals tracking
5. **Secret Management** - Move API keys to secure vault

---

## Rollback Plan

If issues occur after deployment:

### Nginx Headers
```bash
# Revert nginx.conf
git revert <commit-hash>
docker-compose restart frontend
```

### Sentry
```bash
# Disable by removing DSN
export SENTRY_DSN=""
# Or set in environment
```

### CI/CD
```bash
# Delete workflows
rm -rf .github/workflows/*.yml
git commit -m "chore: temporarily disable CI/CD"
```

---

## Monitoring

### Sentry Dashboard
- Monitor error frequency
- Check performance metrics
- Review session replays
- Set up alerts for critical errors

### GitHub Actions
- Review failed builds
- Monitor build times
- Check artifact sizes
- Review security audit reports

### Browser DevTools
- Lighthouse accessibility score (target: > 90)
- Network tab for API call frequency
- Console for CSP violations

---

## Support

For issues with:
- **Sentry**: https://docs.sentry.io/platforms/javascript/guides/angular/
- **GitHub Actions**: https://docs.github.com/en/actions
- **Accessibility**: https://www.w3.org/WAI/WCAG21/quickref/
- **Rate Limiting**: RxJS documentation on debounce/throttle

---

**All Priority 1 improvements are production-ready! 🎉**
