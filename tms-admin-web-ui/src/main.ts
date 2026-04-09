import { HttpClient, HttpClientModule, HTTP_INTERCEPTORS } from '@angular/common/http';
import { importProvidersFrom } from '@angular/core';
import { FormsModule, ReactiveFormsModule } from '@angular/forms';
import { bootstrapApplication } from '@angular/platform-browser';
import { provideAnimations } from '@angular/platform-browser/animations'; //  use this instead of async
import { provideRouter } from '@angular/router';
import { TranslateLoader, TranslateModule } from '@ngx-translate/core';
import { TranslateHttpLoader } from '@ngx-translate/http-loader';
import { ToastrModule } from 'ngx-toastr'; //  required

import { ApiModule } from './app/api/generated_openapi/api.module';
import { Configuration } from './app/api/generated_openapi/configuration';
import { AppComponent } from './app/app.component';
import { routes } from './app/app.routes';
import { initSentry } from './app/core/sentry.config';
import { PerformanceMonitoringService } from './app/core/services/performance-monitoring.service';
import { environment } from './app/environments/environment';
import { UiLanguageService } from './app/shared/services/ui-language.service';
import { AuthInterceptor } from './app/services/auth.interceptor';

// Initialize Sentry before Angular bootstrapping
initSentry();

import { appConfigWithResilience } from './app/app.config.resilience';

export function httpTranslateLoaderFactory(http: HttpClient): TranslateHttpLoader {
  return new TranslateHttpLoader(http, './assets/i18n/', '.json');
}

bootstrapApplication(AppComponent, {
  providers: [
    // Centralized app config with resilience (router, animations, HTTP interceptors)
    ...appConfigWithResilience.providers,
    importProvidersFrom(
      FormsModule,
      ReactiveFormsModule,
      HttpClientModule,
      // Register generated API module with base path from environment
      ApiModule.forRoot(() => new Configuration({ basePath: environment.apiBaseUrl || '/api' })),
      TranslateModule.forRoot({
        defaultLanguage: 'en',
        loader: {
          provide: TranslateLoader,
          useFactory: httpTranslateLoaderFactory,
          deps: [HttpClient],
        },
      }),
      ToastrModule.forRoot(),
    ),
  ],
})
  .then((appRef) => {
    const uiLanguage = appRef.injector.get(UiLanguageService);
    uiLanguage.init();

    // Initialize Web Vitals monitoring after bootstrap
    const perfMonitoring = appRef.injector.get(PerformanceMonitoringService);
    perfMonitoring.initWebVitals();
  })
  .catch((err) => console.error(err));
