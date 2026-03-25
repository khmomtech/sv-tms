(function (window) {
  window.__env = {
    // Environment mode
    production: false,

    // API endpoints
    baseUrl: '',
    apiBaseUrl: '/api',
    wsSocketUrl: '/ws',
    sockJsUrl: '/ws-sockjs',
    useSockJs: true,

    // Google Maps API Key
    googleMapsApiKey: '',

    // Firebase Configuration
    firebase: {
      apiKey: '',
      authDomain: '',
      databaseURL: '',
      projectId: '',
      storageBucket: '',
      messagingSenderId: '',
      appId: '',
      measurementId: ''
    },

    // Sentry Error Monitoring
    sentryDsn: '',
    version: '0.0.0',

    // Feature Flags
    useServerPagingPartners: false,
    useVendorApiPaths: true,
    vendorDisplayTerm: 'Vendor'
  };
})(window);
