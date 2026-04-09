import { ErrorHandler } from '@angular/core';

import { environment } from '../environments/environment';
import { createSentryErrorHandler } from './sentry.config';
import { ErrorHandlerService } from './services/error-handler.service';
import { LoggerService } from './services/logger.service';
import { PerformanceMonitoringService } from './services/performance-monitoring.service';

import { EnvironmentService } from './environment.service';

// Centralized list of application-wide providers (singletons).
// NOTE: HTTP interceptors are configured in app.config.resilience.ts to avoid circular dependencies
export const coreProviders = [
  {
    provide: ErrorHandler,
    useFactory: () => {
      if (environment.production && environment.sentryDsn) {
        return createSentryErrorHandler();
      }
      return new ErrorHandlerService();
    },
  },
  EnvironmentService,
  LoggerService,
  ErrorHandlerService,
  PerformanceMonitoringService,
];
