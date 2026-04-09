import { importProvidersFrom } from '@angular/core';
import { FormsModule, ReactiveFormsModule } from '@angular/forms';
import { bootstrapApplication } from '@angular/platform-browser';
import { ToastrModule } from 'ngx-toastr'; //  required
import { ApiModule } from './app/api/generated_openapi/api.module';
import { Configuration } from './app/api/generated_openapi/configuration';
import { AppComponent } from './app/app.component';
import { initSentry } from './app/core/sentry.config';
import { PerformanceMonitoringService } from './app/core/services/performance-monitoring.service';
import { environment } from './app/environments/environment';
// Initialize Sentry before Angular bootstrapping
initSentry();
import { appConfigWithResilience } from './app/app.config.resilience';
bootstrapApplication(AppComponent, {
    providers: [
        // Centralized app config with resilience (router, animations, HTTP interceptors)
        ...appConfigWithResilience.providers,
        importProvidersFrom(FormsModule, ReactiveFormsModule, 
        // Register generated API module with base path from environment
        ApiModule.forRoot(() => new Configuration({ basePath: environment.apiBaseUrl || '/api' })), ToastrModule.forRoot()),
    ],
})
    .then((appRef) => {
    // Initialize Web Vitals monitoring after bootstrap
    const perfMonitoring = appRef.injector.get(PerformanceMonitoringService);
    perfMonitoring.initWebVitals();
})
    .catch((err) => console.error(err));
