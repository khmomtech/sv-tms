import { expect, test } from '@playwright/test';
import ExcelJS from 'exceljs';

import { mockAuthentication, TEST_USERS } from './helpers/auth.helper';

async function buildWorkbookBuffer(
  rows: Array<Array<string | number | Date>>,
): Promise<Buffer<ArrayBufferLike>> {
  const workbook = new ExcelJS.Workbook();
  const worksheet = workbook.addWorksheet('Orders');
  worksheet.addRow([
    'DeliveryDate',
    'CustomerCode',
    'TrackingNo',
    'TripNo',
    'TruckNumber',
    'TruckTripCount',
    'FromDestination',
    'ToDestination',
    'ItemCode',
    'ItemName',
    'Qty',
    'UoM',
    'UoMPallet',
    'LoadingPlace',
    'Status',
  ]);

  for (const row of rows) {
    worksheet.addRow(row);
  }

  const buffer = await workbook.xlsx.writeBuffer();
  return Buffer.from(buffer);
}

test.describe('Orders Upload', () => {
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

    await page.route('**/api/**', async (route) => {
      await route.fulfill({
        status: 200,
        contentType: 'application/json',
        body: JSON.stringify({ data: [] }),
      });
    });
  });

  test('uploads a valid workbook successfully', async ({ page }) => {
    await page.route('**/api/admin/transportorders/import-bulk', async (route) => {
      await route.fulfill({
        status: 200,
        contentType: 'application/json',
        body: JSON.stringify({
          success: true,
          message: 'Bulk upload completed successfully.',
          data: {
            ORD0001: 'ORD0001-A',
          },
        }),
      });
    });

    const fileBuffer = await buildWorkbookBuffer([
      [
        '27.01.2026',
        'C1000023',
        'CA227.01.2026',
        '1',
        '3E-0293',
        '1',
        'KB',
        'CA2',
        'CPD000011',
        'CAMBODIA WATER PET 1500ML',
        528,
        'Cases',
        8,
        'KB',
        'PENDING',
      ],
    ]);

    await page.goto('/orders/upload');
    await expect(page.getByTestId('orders-upload-dropzone')).toBeVisible();

    await page.getByTestId('orders-upload-input').setInputFiles({
      name: 'valid-orders.xlsx',
      mimeType: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
      buffer: fileBuffer,
    });

    await expect(page.getByText('Selected: valid-orders.xlsx')).toBeVisible();
    await expect(page.getByTestId('orders-upload-file-card')).toContainText('valid-orders.xlsx');
    await expect(page.getByTestId('orders-upload-file-card')).toContainText('Ready to upload');
    await expect(page.getByText('Total Rows:')).toBeVisible();
    await expect(page.getByTestId('orders-upload-guidance')).toContainText(
      'Preview looks valid. Upload will still run a stricter backend validation before saving.',
    );
    await expect(page.getByTestId('orders-upload-action-hint')).toContainText(
      'Validation passed. Upload can proceed.',
    );

    await page.getByTestId('orders-upload-submit').click();

    await expect(page.getByTestId('orders-upload-success')).toContainText(
      'Bulk upload completed successfully.',
    );
    await expect(page.getByTestId('orders-upload-success-summary')).toContainText('Rows: 1');
    await expect(page.getByTestId('orders-upload-success-summary')).toContainText('Groups: 1');
    await expect(page.getByText('Auto-suffixed order references:')).toBeVisible();
  });

  test('shows readable backend validation errors', async ({ page }) => {
    await page.route('**/api/admin/transportorders/import-bulk', async (route) => {
      await route.fulfill({
        status: 422,
        contentType: 'application/json',
        body: JSON.stringify({
          success: false,
          message: 'Import blocked. 2 issue(s) found. Nothing was saved.',
          data: [
            {
              row: 2,
              groupKey: '27.01.2026_C1000023_CA2_1',
              field: 'customerCode',
              value: 'C1000023',
              message: 'Customer not found',
            },
            {
              row: 2,
              groupKey: '27.01.2026_C1000023_CA2_1',
              field: 'truckNumber',
              value: '3E-0293',
              message: 'Vehicle not found',
            },
          ],
        }),
      });
    });

    const fileBuffer = await buildWorkbookBuffer([
      [
        '27.01.2026',
        'C1000023',
        'CA227.01.2026',
        '1',
        '3E-0293',
        '1',
        'KB',
        'CA2',
        'CPD000011',
        'CAMBODIA WATER PET 1500ML',
        528,
        'Cases',
        8,
        'KB',
        'PENDING',
      ],
    ]);

    await page.goto('/orders/upload');
    await page.getByTestId('orders-upload-input').setInputFiles({
      name: 'server-error-orders.xlsx',
      mimeType: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
      buffer: fileBuffer,
    });

    await page.getByTestId('orders-upload-submit').click();

    await expect(page.getByTestId('orders-upload-error')).toContainText(
      'Import blocked. 2 issue(s) found. Nothing was saved.',
    );
    await expect(page.getByTestId('orders-upload-server-errors')).toContainText('Affected fields');
    await expect(page.getByTestId('orders-upload-server-errors')).toContainText(
      'Customer code (1)',
    );
    await expect(page.getByTestId('orders-upload-server-errors')).toContainText('Truck number (1)');
    await expect(page.getByTestId('orders-upload-server-errors')).toContainText(
      'Row 2: Customer code: Customer not found. Value: C1000023.',
    );
    await expect(page.getByTestId('orders-upload-server-errors')).toContainText(
      'Row 2: Truck number: Vehicle not found. Value: 3E-0293.',
    );
    await expect(page.getByTestId('orders-upload-guidance')).toContainText(
      'Nothing was saved. Fix the listed rows in the Excel file, then upload the corrected file again.',
    );
  });

  test('blocks upload on client-side validation errors and opens preview automatically', async ({
    page,
  }) => {
    const fileBuffer = await buildWorkbookBuffer([
      [
        '27.01.2026',
        'C1000023',
        'CA227.01.2026',
        '1',
        '3E-0293',
        '1',
        '',
        'CA2',
        'CPD000011',
        'CAMBODIA WATER PET 1500ML',
        528,
        '',
        8,
        'KB',
        '',
      ],
    ]);

    await page.goto('/orders/upload');
    await page.getByTestId('orders-upload-input').setInputFiles({
      name: 'client-invalid-orders.xlsx',
      mimeType: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
      buffer: fileBuffer,
    });

    await expect(page.getByText('Some rows have missing/invalid fields.')).toBeVisible();
    await expect(page.getByTestId('orders-upload-submit')).toBeDisabled();
    await expect(page.getByTestId('orders-upload-file-card')).toContainText('Needs attention');
    await expect(page.getByTestId('orders-upload-action-hint')).toContainText(
      'Resolve the highlighted row issues before upload is enabled.',
    );
    await expect(page.getByTestId('orders-upload-guidance')).toContainText(
      'Fix the highlighted rows before upload. The upload button stays disabled until all client-side issues are resolved.',
    );
    await expect(
      page.getByRole('cell', { name: 'Missing fromDestination; Missing UoM' }),
    ).toBeVisible();
  });

  test('shows string-only backend template errors clearly', async ({ page }) => {
    await page.route('**/api/admin/transportorders/import-bulk', async (route) => {
      await route.fulfill({
        status: 422,
        contentType: 'application/json',
        body: JSON.stringify({
          success: false,
          message: 'Invalid template headers. Please use the official template.',
          data: ['Column 4 must be TripNo'],
        }),
      });
    });

    const fileBuffer = await buildWorkbookBuffer([
      [
        '27.01.2026',
        'C1000023',
        'CA227.01.2026',
        '1',
        '3E-0293',
        '1',
        'KB',
        'CA2',
        'CPD000011',
        'CAMBODIA WATER PET 1500ML',
        528,
        'Cases',
        8,
        'KB',
        'PENDING',
      ],
    ]);

    await page.goto('/orders/upload');
    await page.getByTestId('orders-upload-input').setInputFiles({
      name: 'template-error-orders.xlsx',
      mimeType: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
      buffer: fileBuffer,
    });

    await page.getByTestId('orders-upload-submit').click();

    await expect(page.getByTestId('orders-upload-error')).toContainText(
      'Invalid template headers. Please use the official template.',
    );
    await expect(page.getByTestId('orders-upload-server-messages')).toContainText(
      'Column 4 must be TripNo',
    );
  });
});
