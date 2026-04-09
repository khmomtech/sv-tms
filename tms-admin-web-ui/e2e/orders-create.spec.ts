import { expect, test } from '@playwright/test';

import { mockAuthentication, TEST_USERS } from './helpers/auth.helper';

async function openAndSelectAddress(page: any, triggerTestId: string, searchValue: string, optionText: string) {
  await page.getByTestId(triggerTestId).click();
  const searchInput = page.locator('input[placeholder*="Search by name or address"]').last();
  await searchInput.fill(searchValue);
  await page.waitForResponse((response: any) => response.url().includes('/customer-addresses/search'));
  await page.locator('li').filter({ hasText: optionText }).first().click();
}

async function selectNgOption(page: any, testId: string, optionText: string) {
  await page.getByTestId(testId).click();
  const menu = page.getByTestId(testId).locator('.dispatch-selector-menu');
  await expect(menu).toBeVisible();
  await menu.locator('.dispatch-selector-option').filter({ hasText: optionText }).first().click();
}

async function searchAndSelectNgOption(
  page: any,
  testId: string,
  searchValue: string,
  optionText: string,
) {
  const root = page.getByTestId(testId);
  await root.click();
  const menu = root.locator('.dispatch-selector-menu');
  await expect(menu).toBeVisible();
  const searchInput = root.locator('input[type="text"]').first();
  await searchInput.fill(searchValue);
  await expect(
    menu.locator('.dispatch-selector-option').filter({ hasText: optionText }).first(),
  ).toBeVisible();
  await menu.locator('.dispatch-selector-option').filter({ hasText: optionText }).first().click();
}

test.describe('Orders Create', () => {
  test.beforeEach(async ({ page }) => {
    await mockAuthentication(page, TEST_USERS.admin);

    await page.route('**/api/public/counts/**', async (route) => {
      await route.fulfill({
        status: 200,
        contentType: 'application/json',
        body: JSON.stringify({ count: 0 }),
      });
    });

    await page.route('**/api/notifications/**', async (route) => {
      await route.fulfill({
        status: 200,
        contentType: 'application/json',
        body: JSON.stringify({ data: 0 }),
      });
    });

    await page.route('**/ws-sockjs/**', async (route) => {
      await route.fulfill({
        status: 200,
        contentType: 'application/json',
        body: JSON.stringify({}),
      });
    });

    await page.route('**/api/admin/customers/147', async (route) => {
      await route.fulfill({
        status: 200,
        contentType: 'application/json',
        body: JSON.stringify({
          data: {
            customer: {
              id: 147,
              name: 'SV Customer',
            },
            addresses: [],
          },
        }),
      });
    });

    await page.route('**/api/admin/transportorders/types', async (route) => {
      await route.fulfill({
        status: 200,
        contentType: 'application/json',
        body: JSON.stringify({ data: ['FTL'] }),
      });
    });

    await page.route('**/api/admin/transportorders/sellers', async (route) => {
      await route.fulfill({
        status: 200,
        contentType: 'application/json',
        body: JSON.stringify({ data: [] }),
      });
    });

    await page.route('**/api/admin/transportorders**', async (route) => {
      if (route.request().method() === 'GET') {
        await route.fulfill({
          status: 200,
          contentType: 'application/json',
          body: JSON.stringify({ data: { content: [] } }),
        });
        return;
      }

      await route.continue();
    });

    await page.route('**/api/admin/drivers/all**', async (route) => {
      await route.fulfill({
        status: 200,
        contentType: 'application/json',
        body: JSON.stringify({
          data: [
            {
              id: 5,
              name: 'Driver One',
              fullName: 'Driver One',
              phone: '012345678',
              licenseNumber: 'LIC-001',
              currentVehicleId: 8,
            },
          ],
        }),
      });
    });

    await page.route('**/api/admin/vehicles/all**', async (route) => {
      await route.fulfill({
        status: 200,
        contentType: 'application/json',
        body: JSON.stringify({
          data: [
            {
              id: 8,
              licensePlate: '3E-0293',
              type: 'TRUCK',
              model: 'Hino',
              status: 'ACTIVE',
            },
          ],
        }),
      });
    });

    await page.route('**/api/admin/customer-addresses/search**', async (route) => {
      const url = new URL(route.request().url());
      const query = (url.searchParams.get('name') || '').toLowerCase();
      const data =
        query.indexOf('pickup') >= 0
          ? [
              {
                id: 10,
                name: 'Pickup Warehouse',
                address: 'Street 1',
                postcode: '12000',
                country: 'KH',
              },
            ]
          : [
              {
                id: 20,
                name: 'Drop Warehouse',
                address: 'Street 2',
                postcode: '12000',
                country: 'KH',
              },
            ];

      await route.fulfill({
        status: 200,
        contentType: 'application/json',
        body: JSON.stringify({ data }),
      });
    });

    await page.route('**/api/admin/customer-bill-to-addresses**', async (route) => {
      await route.fulfill({
        status: 200,
        contentType: 'application/json',
        body: JSON.stringify({ data: { content: [] } }),
      });
    });

  });

  test('creates shipment order and dispatch together', async ({ page }) => {
    let orderPayload: any = null;
    let dispatchPayload: any = null;

    await page.route('**/api/admin/transportorders', async (route) => {
      if (route.request().method() !== 'POST') {
        await route.continue();
        return;
      }

      orderPayload = route.request().postDataJSON();
      await route.fulfill({
        status: 200,
        contentType: 'application/json',
        body: JSON.stringify({
          success: true,
          data: {
            id: 501,
            orderReference: orderPayload.orderReference || 'ORD-501',
          },
        }),
      });
    });

    await page.route('**/api/admin/dispatches', async (route) => {
      if (route.request().method() !== 'POST') {
        await route.continue();
        return;
      }

      dispatchPayload = route.request().postDataJSON();
      await route.fulfill({
        status: 200,
        contentType: 'application/json',
        body: JSON.stringify({
          success: true,
          data: {
            id: 9001,
          },
        }),
      });
    });

    await page.goto('/orders/create?customerId=147');

    await expect(page.getByText('Create Shipment Order')).toBeVisible();
    await expect(page.getByText('SV Customer')).toBeVisible();
    await page.locator('input[formcontrolname="deliveryDate"]').fill('2026-04-04');

    await openAndSelectAddress(page, 'order-pickup-search-0', 'Pickup', 'Pickup Warehouse');
    await openAndSelectAddress(page, 'order-drop-search-0', 'Drop', 'Drop Warehouse');

    await selectNgOption(page, 'order-create-driver-select', 'Driver One (LIC-001)');
    await expect(page.getByText('Auto-matched vehicle: 3E-0293')).toBeVisible();

    await expect(page.locator('[data-testid="order-create-submit"]')).toBeEnabled();
    await page.locator('[data-testid="order-create-submit"]').click();

    await expect(page).toHaveURL(/\/dispatch$/);
    await expect(page.locator('.mat-mdc-snack-bar-container')).toContainText(
      'Shipment order and dispatch created successfully.',
    );

    expect(orderPayload.customerId).toBe(147);
    expect(orderPayload.pickupAddresses[0].id).toBe(10);
    expect(orderPayload.dropAddresses[0].id).toBe(20);
    expect(dispatchPayload.transportOrderId).toBe(501);
    expect(dispatchPayload.driverId).toBe(5);
    expect(dispatchPayload.vehicleId).toBe(8);
  });

  test('redirects to edit order if dispatch creation fails after order save', async ({ page }) => {
    await page.route('**/api/admin/transportorders', async (route) => {
      if (route.request().method() !== 'POST') {
        await route.continue();
        return;
      }

      await route.fulfill({
        status: 200,
        contentType: 'application/json',
        body: JSON.stringify({
          success: true,
          data: {
            id: 501,
            orderReference: 'ORD-501',
          },
        }),
      });
    });

    await page.route('**/api/admin/dispatches', async (route) => {
      if (route.request().method() !== 'POST') {
        await route.continue();
        return;
      }

      await route.fulfill({
        status: 400,
        contentType: 'application/json',
        body: JSON.stringify({
          success: false,
          message: 'Failed to create dispatch',
          errors: {
            driverId: 'Driver must have a valid license number',
          },
        }),
      });
    });

    await page.goto('/orders/create?customerId=147');

    await expect(page.getByText('SV Customer')).toBeVisible();
    await page.locator('input[formcontrolname="deliveryDate"]').fill('2026-04-04');
    await openAndSelectAddress(page, 'order-pickup-search-0', 'Pickup', 'Pickup Warehouse');
    await openAndSelectAddress(page, 'order-drop-search-0', 'Drop', 'Drop Warehouse');
    await selectNgOption(page, 'order-create-driver-select', 'Driver One (LIC-001)');
    await expect(page.getByText('Auto-matched vehicle: 3E-0293')).toBeVisible();

    await expect(page.locator('[data-testid="order-create-submit"]')).toBeEnabled();
    await page.locator('[data-testid="order-create-submit"]').click();

    await expect(page).toHaveURL(/\/orders\/501\/edit$/);
    await expect(page.locator('.mat-mdc-snack-bar-container')).toContainText(
      'Dispatch could not be created.',
    );
  });

  test('sets selected values into the select box after search and click', async ({ page }) => {
    await page.goto('/orders/create?customerId=147');

    await expect(page.getByText('Create Shipment Order')).toBeVisible();

    await searchAndSelectNgOption(
      page,
      'order-create-driver-select',
      'LIC-001',
      'Driver One (LIC-001)',
    );

    await expect(
      page.locator('[data-testid="order-create-driver-select"] input[type="text"]'),
    ).toHaveValue('Driver One (LIC-001)');
    await expect(
      page.locator('[data-testid="order-create-vehicle-select"] input[type="text"]'),
    ).toHaveValue('3E-0293 (TRUCK)');
  });
});
