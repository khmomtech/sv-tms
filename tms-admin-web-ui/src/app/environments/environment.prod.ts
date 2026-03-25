import { environment as baseEnvironment } from './environment';

const defaultProdBase = 'https://svtms.svtrucking.biz';

export const environment = {
  ...baseEnvironment,
  production: true,
  baseUrl: baseEnvironment.baseUrl || defaultProdBase,
  apiBaseUrl: baseEnvironment.apiBaseUrl || `${defaultProdBase}/api`,
  wsSocketUrl: baseEnvironment.wsSocketUrl || 'wss://svtms.svtrucking.biz/ws',
  sockJsUrl: baseEnvironment.sockJsUrl || 'https://svtms.svtrucking.biz/ws-sockjs',
};
