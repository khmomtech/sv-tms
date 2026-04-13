// Default local development targets match LOCAL_DEVELOPMENT.md.
// Override with env vars when routing through gateway or Docker.
const gatewayTarget = process.env.API_GATEWAY_PROXY_TARGET || 'http://127.0.0.1:8086';
const coreTarget = process.env.CORE_API_PROXY_TARGET || 'http://127.0.0.1:8080';
const authTarget = process.env.AUTH_API_PROXY_TARGET || 'http://127.0.0.1:8083';
const driverTarget = process.env.DRIVER_API_PROXY_TARGET || 'http://127.0.0.1:8084';
const telematicsTarget = process.env.TELEMATICS_PROXY_TARGET || 'http://127.0.0.1:8082';
const target = process.env.API_PROXY_TARGET || gatewayTarget;

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
  '/api/auth': {
    target,
    secure: false,
    changeOrigin: true,
    logLevel: 'info',
    timeout: 30000,
    proxyTimeout: 30000,
  },
  '/api/driver/device': {
    target: authTarget,
    secure: false,
    changeOrigin: true,
    logLevel: 'info',
    timeout: 30000,
    proxyTimeout: 30000,
  },
  '/api/driver/chat': {
    target: coreTarget,
    secure: false,
    changeOrigin: true,
    logLevel: 'info',
    timeout: 30000,
    proxyTimeout: 30000,
  },
  '/api/driver-app': {
    target: driverTarget,
    secure: false,
    changeOrigin: true,
    logLevel: 'info',
    timeout: 30000,
    proxyTimeout: 30000,
  },
  '/api/driver': {
    target: driverTarget,
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
  // SockJS starts with a plain HTTP `/info` probe before upgrading transports.
  // Angular dev-server can fail that probe when it is handled by a ws-enabled rule.
  '/ws-sockjs/info': {
    target: coreTarget,
    secure: false,
    changeOrigin: true,
    logLevel: 'info',
    timeout: 30000,
    proxyTimeout: 30000,
  },
  '/ws-sockjs': {
    target: coreTarget,
    secure: false,
    changeOrigin: true,
    ws: true,
    logLevel: 'warn',
    timeout: 0,
    proxyTimeout: 0,
  },
  '/ws': {
    target: coreTarget,
    secure: false,
    changeOrigin: true,
    ws: true,
    logLevel: 'warn',
    timeout: 0,
    proxyTimeout: 0,
  },
  '/tele-ws-sockjs/info': {
    target: telematicsTarget,
    secure: false,
    changeOrigin: true,
    logLevel: 'info',
    timeout: 30000,
    proxyTimeout: 30000,
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
