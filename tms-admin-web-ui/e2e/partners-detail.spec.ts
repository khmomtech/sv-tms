import { test, expect, Page } from '@playwright/test';
import { mockAuthentication, TEST_USERS } from './helpers/auth.helper';

function makePartner(id: number, overrides: Partial<any> = {}) {
  return {
    id,
    companyCode: `PC${id.toString().padStart(3, '0')}`,
    companyName: `Partner ${id}`,
    partnershipType: 'DRIVER_FLEET',
    contactPerson: 'John Doe',
    email: `p${id}@example.com`,
    phone: '+1 555 000 0000',
    commissionRate: 5,
    creditLimit: 10000,
    status: 'ACTIVE',
    address: 'Street, City',
    businessLicense: 'BL-000',
    ...overrides,
  };
}

async function setupRoutes(page: Page) {
  const partner = makePartner(1);

  const respond = (data: any, status = 200) => ({
    status,
    contentType: 'application/json',
    body: JSON.stringify({ data }),
  });

  await page.route(/\/api\/(partners|vendors).*/, async (route, request) => {
    const url = new URL(request.url());
    const method = request.method();
    const path = url.pathname;

    // GET list
    if (method === 'GET' && path.match(/\/api\/(partners|vendors)(\/)??$/)) {
      return route.fulfill(respond([partner]));
    }

    // GET by id
    const getMatch = path.match(/\/api\/(partners|vendors)\/(\d+)$/);
    if (method === 'GET' && getMatch) {
      const id = Number(getMatch[2]);
      if (id === partner.id) return route.fulfill(respond(partner));
      return route.fulfill(respond(null, 404));
    }

    return route.fulfill(respond({}));
  });
}

 test.describe('Partner Detail navigation (stubbed)', () => {
  test.beforeEach(async ({ page }) => {
    await mockAuthentication(page, TEST_USERS.admin);
    await setupRoutes(page);
  });

  test('navigates from list to detail and back', async ({ page }) => {
    await page.goto('/vendors');

    const firstRow = page.locator('tbody tr').first();
    await expect(firstRow).toBeVisible();
    await firstRow.getByRole('button', { name: /view/i }).click();

    await expect(page).toHaveURL(/\/(partners|vendors)\/1$/);
    await expect(page.getByRole('heading', { name: 'Partner 1' })).toBeVisible();

    // Ensure button is not obscured by sticky elements; use force as fallback
    const backBtn = page.getByRole('button', { name: /back/i });
    await backBtn.scrollIntoViewIfNeeded();
    await backBtn.click({ trial: true }).catch(() => {});
    await backBtn.click({ force: true });
    await expect(page).toHaveURL(/\/(partners|vendors)\/?$/);
    await expect(page.locator('table')).toBeVisible();
  });
});
