import { test, expect, Page } from '@playwright/test';
import { mockAuthentication, TEST_USERS } from './helpers/auth.helper';

// In-memory stubbed data for partners
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

async function setupPartnerRoutes(page: Page) {
  const partners: any[] = [makePartner(1)];

  const respond = (data: any, status = 200) => ({
    status,
    contentType: 'application/json',
    body: JSON.stringify({ data }),
  });

    await page.route(/\/api\/(partners|vendors).*/, async (route, request) => {
    const url = new URL(request.url());
    const method = request.method();
    const path = url.pathname;

    // GET /api/partners or with query
      if (method === 'GET' && path.match(/\/api\/(partners|vendors)(\/)??$/)) {
      return route.fulfill(respond(partners));
    }

    // POST /api/partners
      if (method === 'POST' && path.match(/\/api\/(partners|vendors)(\/)??$/)) {
      const body = request.postDataJSON() as any;
      const id = partners.length ? Math.max(...partners.map((p) => p.id || 0)) + 1 : 1;
      const created = makePartner(id, body);
      partners.push(created);
      return route.fulfill(respond(created, 201));
    }

    // PUT /api/(partners|vendors)/:id
    const putMatch = path.match(/\/api\/(partners|vendors)\/(\d+)$/);
    if (method === 'PUT' && putMatch) {
      const id = Number(putMatch[2]);
      const idx = partners.findIndex((p) => p.id === id);
      const body = request.postDataJSON() as any;
      if (idx >= 0) {
        partners[idx] = { ...partners[idx], ...body };
        return route.fulfill(respond(partners[idx]));
      }
      return route.fulfill(respond(null, 404));
    }

    // PATCH /api/(partners|vendors)/:id/deactivate
    const deactMatch = path.match(/\/api\/(partners|vendors)\/(\d+)\/deactivate$/);
    if (method === 'PATCH' && deactMatch) {
      const id = Number(deactMatch[2]);
      const idx = partners.findIndex((p) => p.id === id);
      if (idx >= 0) {
        partners[idx] = { ...partners[idx], status: 'INACTIVE' };
        return route.fulfill(respond(partners[idx]));
      }
      return route.fulfill(respond(null, 404));
    }

    // DELETE /api/(partners|vendors)/:id
    const delMatch = path.match(/\/api\/(partners|vendors)\/(\d+)$/);
    if (method === 'DELETE' && delMatch) {
      const id = Number(delMatch[2]);
      const idx = partners.findIndex((p) => p.id === id);
      if (idx >= 0) {
        partners.splice(idx, 1);
        return route.fulfill(respond(null));
      }
      return route.fulfill(respond(null, 404));
    }

    // Fallback
    return route.fulfill(respond({}));
  });
}

async function waitForToast(page: Page, text: RegExp | string) {
  const toast = page.locator('.toast-banner');
  await expect(toast).toBeVisible();
  await expect(toast).toContainText(text);
}

async function openCreateModal(page: Page) {
  await page.getByRole('button', { name: /add partner/i }).click();
  await expect(page.locator('.modal-card')).toBeVisible();
}

async function submitModal(page: Page) {
  await page.locator('.modal-card').getByRole('button', { name: /save/i }).click();
}

test.describe('Partners CRUD (stubbed)', () => {
  test.beforeEach(async ({ page }) => {
    await mockAuthentication(page, TEST_USERS.admin);
    // Always auto-accept confirm dialogs
    await page.addInitScript(() => {
      // @ts-ignore
      window.confirm = () => true;
    });

    // Ignore websocket noise and non-critical errors
    page.on('console', (msg) => {
      if (msg.type() === 'error') {
        const t = msg.text();
        if (/WebSocket|EventSource|favicon|SourceMap/i.test(t)) return;
        // Log for visibility while not failing test here
        console.warn('Console error:', t);
      }
    });

    await setupPartnerRoutes(page);
  });

  test('create, edit, deactivate, delete partner via modal', async ({ page }) => {
    await page.goto('/partners');

    // Create
    await openCreateModal(page);
    await page.fill('#companyName', 'Acme Logistics');
    await submitModal(page);
    await waitForToast(page, /created/i);
    await expect(page.locator('table')).toContainText('Acme Logistics');

    // Edit first row
    const firstRow = page.locator('tbody tr').first();
    await firstRow.getByRole('button', { name: /edit/i }).click();
    await expect(page.locator('.modal-card')).toBeVisible();
    await page.fill('#companyName', 'Acme Logistics Updated');
    await submitModal(page);
    await waitForToast(page, /updated/i);
    await expect(page.locator('table')).toContainText('Acme Logistics Updated');

    // Deactivate
    // confirm browser confirm dialog (register listener BEFORE click)
    await firstRow.getByRole('button', { name: /deactivate/i }).click();
    // Wait until status updates to INACTIVE, then assert toast
    await expect(firstRow).toContainText('INACTIVE');
    await waitForToast(page, /deactivated/i);

    // Delete
    await firstRow.getByRole('button', { name: /delete/i }).click();
    await waitForToast(page, /deleted/i);
  });
});
