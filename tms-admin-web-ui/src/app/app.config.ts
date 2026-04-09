import type { ApplicationConfig } from '@angular/core';
import { provideRouter, withPreloading } from '@angular/router';
import { PreloadAllModules } from '@angular/router';
import { provideAnimations } from '@angular/platform-browser/animations';

import { routes } from './app.routes';
import { coreProviders } from './core/core.providers';

// Root application configuration: centralizes router + cross-cutting providers.
export const appConfig: ApplicationConfig = {
  providers: [
    provideRouter(routes, withPreloading(PreloadAllModules)),
    provideAnimations(), // Required for Angular Material components
    ...coreProviders,
  ],
};
