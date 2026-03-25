# Priority 2 Services - Quick Reference Card

Quick reference for ErrorHandlerService, LoggerService, and PerformanceMonitoringService.

---

## 🎯 ErrorHandlerService

Centralized error handling with user-friendly messages.

### Import
```typescript
import { ErrorHandlerService } from '@app/core/services/error-handler.service';
```

### Basic Usage
```typescript
constructor(private errorHandler: ErrorHandlerService) {}

this.http.get('/api/data').pipe(
  catchError(error => {
    this.errorHandler.handleError(error, { 
      component: 'MyComponent',
      operation: 'loadData'
    });
    return throwError(() => error);
  })
);
```

### Status Codes
- `0` - Network error
- `401` - Unauthorized
- `403` - Forbidden
- `404` - Not found
- `500` - Server error

---

## 📝 LoggerService

Structured logging with auto-sanitization.

### Import
```typescript
import { LoggerService } from '@app/core/services/logger.service';
```

### Usage
```typescript
constructor(private logger: LoggerService) {}

this.logger.debug('Debug info');      // DEV only
this.logger.info('User action');      // DEV only
this.logger.warn('Warning');          // Always
this.logger.error('Error', { err });  // Always + Sentry
```

### Recent Logs
```typescript
const logs = this.logger.getRecentLogs(50);
console.table(logs);
```

---

## 📊 PerformanceMonitoringService

Web Vitals and custom metrics.

### Import
```typescript
import { PerformanceMonitoringService } from '@app/core/services/performance-monitoring.service';
```

### Custom Metrics
```typescript
// Mark & measure
this.perf.markPerformance('start');
await doWork();
this.perf.measurePerformance('work', 'start', 'end');

// Track component render
const duration = performance.now() - start;
this.perf.trackComponentRender('MyComp', duration);

// Track API calls
this.perf.trackApiCall('/api/data', duration, 200);
```

---

## 🔒 Secret Management

Runtime configuration.

### Development Setup
```bash
cp src/assets/env.template.js src/assets/env.js
# Edit env.js with your keys
```

### Access in Code
```typescript
import { environment } from '@app/environments/environment';

const apiKey = environment.googleMapsApiKey;
const firebase = environment.firebase;
```

---

## 🚀 Commands

```bash
npm run lint              # Check code
npm run lighthouse        # Performance audit
npm run build             # Check bundle size
```

---

See **PRIORITY_2_IMPLEMENTATION_SUMMARY.md** for full details.
