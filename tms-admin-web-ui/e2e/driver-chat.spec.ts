import { expect, test } from '@playwright/test';

import { mockAuthentication, TEST_USERS } from './helpers/auth.helper';

const conversation = {
  driverId: 99,
  driverName: 'Marcus Jenkins',
  phone: '010123456',
  employeeName: null,
  latestMessage: 'The GPS signal is dropping on I-95.',
  latestSenderRole: 'DRIVER',
  latestMessageAt: '2026-03-19T12:45:00',
  unreadDriverMessageCount: 1,
  totalMessageCount: 3,
};

const thread = [
  {
    id: 1,
    driverId: 99,
    senderRole: 'DRIVER',
    sender: 'Marcus Jenkins',
    message: 'The GPS signal is dropping on I-95.',
    createdAt: '2026-03-19T12:45:00',
    read: false,
  },
  {
    id: 2,
    driverId: 99,
    senderRole: 'ADMIN',
    sender: 'Dispatch',
    message: 'Checking traffic now. Take Route 301.',
    createdAt: '2026-03-19T12:48:00',
    read: true,
  },
];

test.describe('Driver Chat Admin Inbox', () => {
  test.beforeEach(async ({ page }) => {
    await mockAuthentication(page, TEST_USERS.admin);

    await page.route('**/api/admin/driver-chat/conversations', async (route) => {
      await route.fulfill({
        status: 200,
        contentType: 'application/json',
        body: JSON.stringify([conversation]),
      });
    });

    await page.route('**/api/admin/driver-chat/99/mark-read', async (route) => {
      await route.fulfill({
        status: 200,
        contentType: 'application/json',
        body: JSON.stringify({ driverId: 99, updated: 1 }),
      });
    });

    await page.route('**/api/admin/driver-chat/99/send', async (route) => {
      const payload = route.request().postDataJSON() as { message: string };
      await route.fulfill({
        status: 200,
        contentType: 'application/json',
        body: JSON.stringify({
          id: 3,
          driverId: 99,
          senderRole: 'ADMIN',
          sender: 'Dispatch',
          message: payload.message,
          createdAt: '2026-03-19T12:52:00',
          read: false,
        }),
      });
    });

    await page.route('**/api/admin/driver-chat/99*', async (route) => {
      await route.fulfill({
        status: 200,
        contentType: 'application/json',
        body: JSON.stringify(thread),
      });
    });

    await page.route('**/ws-sockjs/**', async (route) => {
      await route.fulfill({
        status: 200,
        contentType: 'application/json',
        body: JSON.stringify({}),
      });
    });
  });

  test('renders the inbox, opens a thread, and sends an admin reply', async ({ page }) => {
    await page.goto('/drivers/communication/messages?driverId=99');

    await expect(page.getByTestId('driver-chat-page')).toBeVisible();
    await expect(page.getByTestId('driver-chat-conversation')).toContainText('Marcus Jenkins');
    await expect(page.getByTestId('driver-chat-thread-header')).toContainText('Marcus Jenkins');
    await expect(page.getByTestId('driver-chat-thread-body')).toContainText(
      'The GPS signal is dropping on I-95.',
    );

    await page.getByTestId('driver-chat-composer').fill('Use Route 301 to avoid the dead zone.');
    await page.getByTestId('driver-chat-send').click();

    await expect(page.getByTestId('driver-chat-thread-body')).toContainText(
      'Use Route 301 to avoid the dead zone.',
    );
  });
});
