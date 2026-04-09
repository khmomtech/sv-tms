import { defineConfig } from 'vite';
import angular from 'vite-plugin-angular';
import rollupNodePolyfills from 'rollup-plugin-node-polyfills';

const proxyTarget = process.env.API_PROXY_TARGET || 'http://localhost:8080';

export default defineConfig({
  plugins: [angular()],
  define: {
    global: 'globalThis', // 👈 Polyfill for `global` in the browser
  },
  server: {
    host: '0.0.0.0',
    // Use env-configurable proxy target:
    // - local:  API_PROXY_TARGET=http://localhost:8080 (default)
    // - docker: API_PROXY_TARGET=http://backend:8080
    proxy: {
      '/api': {
        target: proxyTarget,
        changeOrigin: true,
        secure: false,
      },
      '/ws-sockjs': {
        target: proxyTarget,
        changeOrigin: true,
        secure: false,
        ws: true,
      },
      '/uploads': {
        target: proxyTarget,
        changeOrigin: true,
        secure: false,
      },
    },
  },
  optimizeDeps: {
    include: ['sockjs-client'],
    noDiscovery: true,
  },
  build: {
    rollupOptions: {
      plugins: [rollupNodePolyfills()],
    },
  },
  resolve: {
    alias: {
      process: 'process/browser',
      buffer: 'buffer/',
    },
  },
});
