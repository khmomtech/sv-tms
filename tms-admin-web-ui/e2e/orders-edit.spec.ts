import { expect, test } from '@playwright/test';

import { mockAuthentication, TEST_USERS } from './helpers/auth.helper';

test.describe('Orders Edit', () => {
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
        body: JSON.stringify({ data: [{ id: 1, fullName: 'Seller A' }] }),
      });
    });

    await page.route('**/api/admin/customer-bill-to-addresses**', async (route) => {
      await route.fulfill({
        status: 200,
        contentType: 'application/json',
        body: JSON.stringify({
          data: [
            {
              id: 901,
              name: 'HQ Billing',
              address: 'Phnom Penh HQ',
            },
          ],
        }),
      });
    });
  });

  test('prefills existing order data and updates the order successfully', async ({ page }) => {
    let updatePayload: any = null;

    await page.route('**/api/admin/transportorders/134', async (route) => {
      const method = route.request().method();

      if (method === 'GET') {
        await route.fulfill({
          status: 200,
          contentType: 'application/json',
          body: JSON.stringify({
            data: {
              id: 134,
              orderReference: 'ORD-2825',
              customerId: 147,
              customerName: 'SV Customer',
              billToAddressId: 901,
              orderDate: '2026-04-01',
              deliveryDate: '2026-04-04',
              shipmentType: 'FTL',
              status: 'PENDING',
              sellerId: 1,
              pickupAddresses: [
                {
                  id: 10,
                  name: 'Pickup Warehouse',
                  address: 'Street 1',
                  contactName: 'P Contact',
                  contactPhone: '012345678',
                },
              ],
              dropAddresses: [
                {
                  id: 20,
                  name: 'Drop Warehouse',
                  address: 'Street 2',
                  contactName: 'D Contact',
                  contactPhone: '098765432',
                },
              ],
              items: [
                {
                  id: 77,
                  itemId: 3001,
                  itemCode: 'CPD000136',
                  itemName: 'EXPREZ MELON PET 300ML ORD',
                  quantity: 1,
                  unitOfMeasurement: 'Case',
                  weight: 1000,
                  palletType: 'Standard',
                  size: '300ML',
                  fromDestination: 'KB',
                  toDestination: 'PP',
                  warehouse: 'WH-A',
                  department: 'Sales',
                },
              ],
            },
          }),
        });
        return;
      }

      if (method === 'PUT') {
        updatePayload = route.request().postDataJSON();
        await route.fulfill({
          status: 200,
          contentType: 'application/json',
          body: JSON.stringify({
            success: true,
            data: {
              id: 134,
              orderReference: 'ORD-2825',
            },
          }),
        });
        return;
      }

      await route.continue();
    });

    await page.goto('/orders/134/edit');

    await expect(page.getByRole('heading', { name: /edit order/i })).toBeVisible();
    await expect(page.locator('input[formcontrolname="orderReference"]')).toHaveValue('ORD-2825');
    await expect(page.locator('.customer-selection-name')).toContainText('SV Customer');
    await expect(page.locator('input[formcontrolname="deliveryDate"]')).toHaveValue('2026-04-04');
    await expect(page.locator('input[formcontrolname="name"]').first()).toHaveValue(
      'Pickup Warehouse',
    );
    await expect(page.getByText('EXPREZ MELON PET 300ML ORD')).toBeVisible();

    await page.locator('input[formcontrolname="deliveryDate"]').fill('2026-04-09');
    await page.locator('[data-testid="order-create-submit"]').click();

    await expect(page).toHaveURL(/\/orders$/);
    await expect(page.locator('.mat-mdc-snack-bar-container')).toContainText(
      'Order updated successfully.',
    );

    expect(updatePayload).toBeTruthy();
    expect(updatePayload.orderReference).toBe('ORD-2825');
    expect(updatePayload.customerId).toBe(147);
    expect(updatePayload.billToAddressId ?? updatePayload.billTo).toBe(901);
    expect(updatePayload.deliveryDate).toBe('2026-04-09');
    expect(updatePayload.pickupAddresses[0].id).toBe(10);
    expect(updatePayload.dropAddresses[0].id).toBe(20);
    expect(updatePayload.pickupLocations[0].id).toBe(10);
    expect(updatePayload.dropLocations[0].id).toBe(20);
    expect(updatePayload.items[0].itemName).toBe('EXPREZ MELON PET 300ML ORD');
  });
});
