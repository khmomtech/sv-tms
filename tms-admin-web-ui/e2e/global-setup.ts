/**
 * Global setup for Playwright tests
 * Verifies backend connectivity before running E2E tests
 */

async function globalSetup() {
  const apiBaseUrl = process.env.API_BASE_URL || 'http://localhost:8080';

  console.log('🔧 Global Setup: Checking backend connectivity...');
  console.log(`📡 API Base URL: ${apiBaseUrl}`);

  const skip = process.env.E2E_SKIP_HEALTH === '1';
  if (skip) {
    console.log('⏭️  Skipping backend health check due to E2E_SKIP_HEALTH=1');
  } else {
    const candidateEndpoints = [
      '/api/actuator/health',
      '/actuator/health',
      '/api/health',
      '/health'
    ];
    const authToken = process.env.API_TOKEN;
    let success = false;
    for (const ep of candidateEndpoints) {
      const url = apiBaseUrl.replace(/\/$/, '') + ep;
      try {
        const response = await fetch(url, {
          method: 'GET',
          headers: {
            'Accept': 'application/json',
            ...(authToken ? { 'Authorization': `Bearer ${authToken}` } : {})
          },
        });
        if (response.ok) {
          let status = 'UNKNOWN';
            try {
              const json = await response.json();
              status = (json && (json.status || json.components?.db?.status)) || 'UNKNOWN';
            } catch {}
          console.log(`Backend healthy via ${ep}: ${status}`);
          success = true;
          break;
        } else if ([401, 403].includes(response.status)) {
          console.warn(`⚠️  Protected health endpoint (${response.status}) at ${ep}; treating as non-fatal.`);
          // Do not mark success; try next endpoint, but it's not fatal.
        } else {
          console.warn(`⚠️  Health check ${ep} returned ${response.status}`);
        }
      } catch (err) {
        console.warn(`⚠️  Failed to reach ${ep}:`, err instanceof Error ? err.message : 'Unknown error');
      }
    }
    if (!success) {
      console.warn('⚠️  No healthy (200) health endpoint found. Proceeding with tests anyway.');
      console.warn('    If tests rely on backend responses, start backend or stub APIs.');
      console.warn('    To silence this, set E2E_SKIP_HEALTH=1');
    }
  }

  console.log('Global setup complete\n');
}

export default globalSetup;
