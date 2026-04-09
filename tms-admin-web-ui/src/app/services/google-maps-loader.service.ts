import { Injectable } from '@angular/core';

import { environment } from '../environments/environment';

@Injectable({
  providedIn: 'root',
})
export class GoogleMapsLoaderService {
  private apiLoaded = false;

  load(): Promise<void> {
    return new Promise((resolve, reject) => {
      // Check if already loaded or available
      if (this.apiLoaded || (window as any).google?.maps?.Map) {
        resolve();
        return;
      }

      const scriptId = 'google-maps-script';
      const existingScript = document.getElementById(scriptId) as HTMLScriptElement;

      // If script already exists, listen to its load event
      if (existingScript) {
        existingScript.addEventListener('load', () => {
          this.apiLoaded = true;
          resolve();
        });
        return;
      }

      // Define the callback if not already set
      if (!(window as any).initGoogleMaps) {
        (window as any).initGoogleMaps = () => {
          this.apiLoaded = true;
          resolve();
        };
      }

      // Create the script tag dynamically
      const script = document.createElement('script');
      script.id = scriptId;
      script.src = `https://maps.googleapis.com/maps/api/js?key=${environment.googleMapsApiKey}&libraries=places,marker,drawing&v=weekly&callback=initGoogleMaps`;
      script.async = true;
      script.defer = true;

      // Handle script load failure
      script.onerror = (error) => {
        console.error('[Google Maps] Failed to load:', error);
        document.head.removeChild(script); // clean up bad script
        reject(error);
      };

      // Append to DOM
      document.head.appendChild(script);

      // Optional: Timeout safeguard (10s)
      setTimeout(() => {
        if (!this.apiLoaded) {
          reject('[Google Maps] Loading timeout.');
        }
      }, 10000);
    });
  }
}
