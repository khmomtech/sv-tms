import { Injectable } from '@angular/core';
import { environment } from '@env/environment';

// Thin wrapper around static environment for easier future runtime overrides / testing.
@Injectable({ providedIn: 'root' })
export class EnvironmentService {
  isProduction(): boolean {
    return !!environment.production;
  }
  apiBaseUrl(): string {
    return environment.apiBaseUrl;
  }
  wsSocketUrl(): string {
    return environment.wsSocketUrl;
  }
  sockJsUrl(): string {
    return environment.sockJsUrl;
  }
  googleMapsApiKey(): string {
    return environment.googleMapsApiKey;
  }
}
