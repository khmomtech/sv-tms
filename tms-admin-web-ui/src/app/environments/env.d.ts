declare const __env:
  | {
      production?: boolean | string;
      baseUrl?: string;
      apiBaseUrl?: string;
      wsSocketUrl?: string;
      sockJsUrl?: string;
      useSockJs?: boolean | string;
      googleMapsApiKey?: string;
      firebase?: {
        apiKey?: string;
        authDomain?: string;
        databaseURL?: string;
        projectId?: string;
        storageBucket?: string;
        messagingSenderId?: string;
        appId?: string;
        measurementId?: string;
      };
    }
  | undefined;
