import { expect, test } from '@playwright/test';

const ALL_FUNCTIONS = ['all_functions'];

test.describe.configure({ timeout: 45000 });
test.use({ trace: 'off', video: 'off' });

function buildToken(roles: string[]) {
  const header = Buffer.from(JSON.stringify({ alg: 'HS256', typ: 'JWT' })).toString('base64');
  const payload = Buffer.from(
    JSON.stringify({
      exp: Math.floor(Date.now() / 1000) + 3600,
      iat: Math.floor(Date.now() / 1000),
      sub: 'e2e-admin',
      roles,
    }),
  ).toString('base64');
  return `${header}.${payload}.fake-signature`;
}

async function mockAuth(page: any) {
  const roles = ['ADMIN', 'SUPERADMIN'];
  await page.addInitScript(
    ({ token, permissions, roles: userRoles }) => {
      localStorage.setItem('token', token);
      localStorage.setItem(
        'user',
        JSON.stringify({
          id: 1,
          username: 'e2e-admin',
          email: 'e2e-admin@example.com',
          roles: userRoles,
          permissions,
          companyId: 1,
        }),
      );
      localStorage.setItem('permissions', JSON.stringify(permissions));
    },
    { token: buildToken(roles), permissions: ALL_FUNCTIONS, roles },
  );
}

test.describe('Live Map address state', () => {
  test.beforeEach(async ({ page }) => {
    await mockAuth(page);

    await page.route('**/api/admin/user-permissions/me/effective', async (route) => {
      await route.fulfill({
        json: {
          userId: 1,
          permissions: ALL_FUNCTIONS,
          permissionMatrix: {},
        },
      });
    });

    await page.route('**/api/admin/drivers/all', async (route) => {
      await route.fulfill({
        json: {
          success: true,
          data: [
            {
              id: 101,
              name: 'Pending Resolve Driver',
              phone: '012345678',
              latitude: 11.552366,
              longitude: 104.857584,
              lastUpdated: '2026-04-13T15:00:00Z',
              isOnline: true,
              status: 'online',
              currentVehiclePlate: '3B-7617',
              logs: [],
            },
            {
              id: 102,
              name: 'Offline Unknown Driver',
              phone: '098765432',
              latitude: 11.560001,
              longitude: 104.900001,
              lastUpdated: '2026-04-13T13:00:00Z',
              isOnline: false,
              status: 'offline',
              currentVehiclePlate: '3A-2452',
              logs: [],
            },
            {
              id: 103,
              name: 'Online Resolving Driver',
              phone: '090000000',
              latitude: 11.570001,
              longitude: 104.910001,
              lastUpdated: '2026-04-13T15:01:00Z',
              isOnline: true,
              status: 'online',
              currentVehiclePlate: '3B-9386',
              logs: [],
            },
          ],
        },
      });
    });

    await page.route('**/api/admin/drivers/live-drivers**', async (route) => {
      await route.fulfill({
        json: {
          success: true,
          data: [
            {
              driverId: 101,
              latitude: 11.552366,
              longitude: 104.857584,
              isOnline: true,
              geocodeStatus: 'pending',
              lastSeenEpochMs: Date.now() - 5000,
              lastSeenSeconds: 5,
              ingestLagSeconds: 2,
            },
            {
              driverId: 102,
              latitude: 11.560001,
              longitude: 104.900001,
              isOnline: false,
              geocodeStatus: 'failed',
              lastSeenEpochMs: Date.now() - 600000,
              lastSeenSeconds: 600,
              ingestLagSeconds: 600,
            },
            {
              driverId: 103,
              latitude: 11.570001,
              longitude: 104.910001,
              isOnline: true,
              geocodeStatus: 'pending',
              lastSeenEpochMs: Date.now() - 4000,
              lastSeenSeconds: 4,
              ingestLagSeconds: 1,
            },
          ],
        },
      });
    });

    await page.route('**/api/admin/drivers/101/latest-location', async (route) => {
      await route.fulfill({
        json: {
          success: true,
          data: {
            driverId: 101,
            latitude: 11.552366,
            longitude: 104.857584,
            locationName: 'Sangkat Boeung Kak, Phnom Penh',
            geocodeStatus: 'resolved',
            isOnline: true,
            updatedAt: '2026-04-13T15:02:00Z',
            lastSeenEpochMs: Date.now() - 2000,
            lastSeenSeconds: 2,
            ingestLagSeconds: 1,
          },
        },
      });
    });

    await page.route('**/api/admin/drivers/102/latest-location', async (route) => {
      await route.fulfill({
        json: {
          success: true,
          data: {
            driverId: 102,
            latitude: 11.560001,
            longitude: 104.900001,
            geocodeStatus: 'failed',
            isOnline: false,
            updatedAt: '2026-04-13T13:00:00Z',
            lastSeenEpochMs: Date.now() - 600000,
            lastSeenSeconds: 600,
            ingestLagSeconds: 600,
          },
        },
      });
    });

    await page.route('**/api/admin/drivers/103/latest-location', async (route) => {
      await route.fulfill({
        json: {
          success: true,
          data: {
            driverId: 103,
            latitude: 11.570001,
            longitude: 104.910001,
            geocodeStatus: 'pending',
            isOnline: true,
            updatedAt: '2026-04-13T15:01:00Z',
            lastSeenEpochMs: Date.now() - 3000,
            lastSeenSeconds: 3,
            ingestLagSeconds: 1,
          },
        },
      });
    });

    await page.route('**/api/admin/geofences**', async (route) => {
      await route.fulfill({ json: [] });
    });

    await page.route('**/api/public/counts/**', async (route) => {
      await route.fulfill({ json: { success: true, data: {} } });
    });

    await page.route('**/api/notifications/**', async (route) => {
      await route.fulfill({ json: { success: true, data: [] } });
    });
  });

  test('hydrates latest resolved address when selecting a driver', async ({ page }) => {
    await page.goto('/live/map', { waitUntil: 'domcontentloaded' });

    const driverList = page.locator('#driverList');
    const detailPane = page.locator('main');

    await expect(driverList.getByText('Pending Resolve Driver', { exact: true })).toBeVisible({ timeout: 15000 });
    await driverList.getByText('Pending Resolve Driver', { exact: true }).click({ noWaitAfter: true });

    await expect(detailPane.getByText('Latest location').first()).toBeVisible();
    await expect(detailPane.getByText('Sangkat Boeung Kak, Phnom Penh').first()).toBeVisible();
  });

  test('renders pending and failed address states clearly', async ({ page }) => {
    await page.goto('/live/map', { waitUntil: 'domcontentloaded' });

    const driverList = page.locator('#driverList');
    const detailPane = page.locator('main');

    await expect(driverList.getByText('Online Resolving Driver', { exact: true })).toBeVisible({ timeout: 15000 });

    await driverList.getByText('Online Resolving Driver', { exact: true }).click({ noWaitAfter: true });
    await expect(detailPane.getByText('Resolving address...').first()).toBeVisible();

    await driverList.getByText('Offline Unknown Driver', { exact: true }).click({ noWaitAfter: true });
    await expect(detailPane.getByText('Address unavailable').first()).toBeVisible();
  });
});
