type FirebaseConfig = {
  apiKey?: string;
  authDomain?: string;
  databaseURL?: string;
  projectId?: string;
  storageBucket?: string;
  messagingSenderId?: string;
  appId?: string;
  measurementId?: string;
};

type RuntimeEnv = {
  production?: boolean | string;
  baseUrl?: string;
  apiBaseUrl?: string;
  apiUrl?: string;
  wsSocketUrl?: string;
  wsUrl?: string;
  sockJsUrl?: string;
  useSockJs?: boolean | string;
  googleMapsApiKey?: string;
  mapboxAccessToken?: string;
  firebase?: FirebaseConfig;
  firebaseConfig?: FirebaseConfig;
  enableDebugLogs?: boolean | string;
  // Legal URLs
  privacyPolicyUrl?: string;
  termsOfServiceUrl?: string;
  // Feature flags (string or boolean allowed for runtime override)
  useServerPagingPartners?: boolean | string;
  // Use vendor alias endpoints instead of partners
  useVendorApiPaths?: boolean | string;
  // Display term for vendor domain (e.g., 'Vendor' or 'Subcontractor')
  vendorDisplayTerm?: string;
  // Error monitoring
  sentryDsn?: string;
  version?: string;
};

// Declare global __env variable
declare const __env: RuntimeEnv | undefined;

const runtimeEnv: RuntimeEnv =
  (typeof (globalThis as any).__env !== 'undefined'
    ? ((globalThis as any).__env as RuntimeEnv)
    : {}) ?? {};

const toBool = (value: boolean | string | undefined, fallback: boolean): boolean => {
  if (typeof value === 'boolean') return value;
  if (typeof value === 'string') {
    const lowered = value.trim().toLowerCase();
    if (['true', '1', 'yes'].includes(lowered)) return true;
    if (['false', '0', 'no'].includes(lowered)) return false;
  }
  return fallback;
};

// Use empty fallback so all calls default to relative paths and pass through dev proxy.
// In Docker dev, proxy.conf.json routes /api and /ws-sockjs to backend service name.
const fallbackBaseUrl = '';

const firebaseRuntime = runtimeEnv.firebase ?? {};

export const environment = {
  production: toBool(runtimeEnv.production, false),
  baseUrl: runtimeEnv.baseUrl || fallbackBaseUrl || '',
  apiBaseUrl: runtimeEnv.apiBaseUrl || '/api',
  // Backwards-compatible alias used across services
  apiUrl: runtimeEnv.apiUrl || runtimeEnv.apiBaseUrl || '/api',
  wsSocketUrl: runtimeEnv.wsSocketUrl || '/ws',
  // Backwards-compatible websocket alias
  wsUrl: runtimeEnv.wsUrl || runtimeEnv.wsSocketUrl || '/ws',
  sockJsUrl: runtimeEnv.sockJsUrl || '/ws-sockjs',
  useSockJs: toBool(runtimeEnv.useSockJs, true),
  googleMapsApiKey: runtimeEnv.googleMapsApiKey || '',
  mapboxAccessToken: runtimeEnv.mapboxAccessToken || '',
  // Legal URLs
  privacyPolicyUrl: runtimeEnv.privacyPolicyUrl || 'https://svtms.svtrucking.biz/privacy',
  termsOfServiceUrl: runtimeEnv.termsOfServiceUrl || 'https://svtms.svtrucking.biz/terms',
  // Backwards-compatible flag
  enableDebugLogs:
    typeof runtimeEnv.enableDebugLogs !== 'undefined'
      ? toBool(runtimeEnv.enableDebugLogs, true)
      : !toBool(runtimeEnv.production, false),
  // Feature flags
  useServerPagingPartners: toBool(runtimeEnv.useServerPagingPartners, false),
  useVendorApiPaths: toBool(runtimeEnv.useVendorApiPaths, true),
  vendorDisplayTerm: (runtimeEnv.vendorDisplayTerm || 'Vendor') as string,
  // Error monitoring
  sentryDsn: runtimeEnv.sentryDsn || '',
  version: runtimeEnv.version || '0.0.0',
  firebase: {
    apiKey: firebaseRuntime.apiKey || '',
    authDomain: firebaseRuntime.authDomain || '',
    databaseURL: firebaseRuntime.databaseURL || '',
    projectId: firebaseRuntime.projectId || '',
    storageBucket: firebaseRuntime.storageBucket || '',
    messagingSenderId: firebaseRuntime.messagingSenderId || '',
    appId: firebaseRuntime.appId || '',
    measurementId: firebaseRuntime.measurementId || '',
  },
  // Backwards-compatible alias for older code
  firebaseConfig: {
    apiKey: firebaseRuntime.apiKey || '',
    authDomain: firebaseRuntime.authDomain || '',
    databaseURL: firebaseRuntime.databaseURL || '',
    projectId: firebaseRuntime.projectId || '',
    storageBucket: firebaseRuntime.storageBucket || '',
    messagingSenderId: firebaseRuntime.messagingSenderId || '',
    appId: firebaseRuntime.appId || '',
    measurementId: firebaseRuntime.measurementId || '',
  },
};
