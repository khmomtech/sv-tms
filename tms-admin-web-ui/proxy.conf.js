// Dynamic proxy config: choose target from `API_PROXY_TARGET` env var.
// Defaults to http://localhost:8080 for local dev, can be overridden
// when running inside Docker (set API_PROXY_TARGET=http://backend:8080).
const target = process.env.API_PROXY_TARGET || 'http://localhost:8080';
const telematicsTarget = process.env.TELEMATICS_PROXY_TARGET || 'http://localhost:8082';

module.exports = {
  '/api/admin/geofences': {
    target: telematicsTarget,
    secure: false,
    changeOrigin: true,
    logLevel: 'info',
    timeout: 30000,
    proxyTimeout: 30000,
  },
  '/api/admin/telematics': {
    target: telematicsTarget,
    secure: false,
    changeOrigin: true,
    logLevel: 'info',
    timeout: 30000,
    proxyTimeout: 30000,
  },
  '/api': {
    target,
    secure: false,
    changeOrigin: true,
    logLevel: 'info',
    timeout: 30000,
    proxyTimeout: 30000,
  },
  '/ws-sockjs': {
    target,
    secure: false,
    changeOrigin: true,
    ws: true,
    logLevel: 'warn',
    timeout: 0,
    proxyTimeout: 0,
  },
  '/tele-ws-sockjs': {
    target: telematicsTarget,
    secure: false,
    changeOrigin: true,
    ws: true,
    logLevel: 'warn',
    timeout: 0,
    proxyTimeout: 0,
  },
  '/tele-ws': {
    target: telematicsTarget,
    secure: false,
    changeOrigin: true,
    ws: true,
    logLevel: 'warn',
    timeout: 0,
    proxyTimeout: 0,
  },
  '/uploads': {
    target,
    secure: false,
    changeOrigin: true,
    logLevel: 'info',
    timeout: 30000,
    proxyTimeout: 30000,
  },
};
