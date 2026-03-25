/* eslint-disable @typescript-eslint/consistent-type-imports */
import { CommonModule } from '@angular/common';
import { OnInit } from '@angular/core';
import { Component } from '@angular/core';
import { FormsModule } from '@angular/forms';
import { RouterModule } from '@angular/router';

import {
  InAppNotificationService,
  type InAppNotification,
} from '../../services/in-app-notification.service';
import { NotificationService } from '../../services/notification.service';

@Component({
  selector: 'app-in-app-notifications-admin',
  standalone: true,
  imports: [CommonModule, FormsModule, RouterModule],
  templateUrl: './in-app-notifications-admin.component.html',
  styleUrls: ['./in-app-notifications-admin.component.css'],
})
export class InAppNotificationsAdminComponent implements OnInit {
  notifications: InAppNotification[] = [];
  searchKeyword = '';
  showUnreadOnly = false;
  fromDate = '';
  toDate = '';
  page = 0;
  pageSize = 20;
  totalPages = 0;
  totalUnread = 0;
  readonly entityRouteMap: Record<string, (id: string) => string[]> = {
    MR: (id) => ['/fleet/maintenance/requests', id],
    MAINTENANCE_REQUEST: (id) => ['/fleet/maintenance/requests', id],
    WO: (id) => ['/fleet/maintenance/work-orders', id],
    WORK_ORDER: (id) => ['/fleet/maintenance/work-orders', id],
    PM_RUN: (id) => ['/fleet/maintenance/pm-runs', id],
    PM_PLAN: (id) => ['/fleet/maintenance/pm-plans', id],
    INCIDENT: (id) => ['/incidents', id],
  };

  constructor(
    private readonly inAppService: InAppNotificationService,
    private readonly notify: NotificationService,
  ) {}

  ngOnInit(): void {
    this.loadNotifications();
    this.loadUnreadCount();
  }

  loadNotifications(): void {
    this.inAppService
      .list(this.page, this.pageSize, {
        q: this.searchKeyword || undefined,
        unreadOnly: this.showUnreadOnly || undefined,
        fromDate: this.fromDate || undefined,
        toDate: this.toDate || undefined,
      })
      .subscribe({
        next: (res) => {
          this.notifications = res?.data?.content ?? [];
          this.totalPages = res?.data?.totalPages ?? 0;
        },
        error: () => this.notify.error('Failed to load notifications'),
      });
  }

  loadUnreadCount(): void {
    this.inAppService.countUnread().subscribe({
      next: (res) => (this.totalUnread = res?.data ?? 0),
      error: () => (this.totalUnread = 0),
    });
  }

  get filteredNotifications(): InAppNotification[] {
    return this.notifications;
  }

  changePage(delta: number): void {
    const newPage = this.page + delta;
    if (newPage >= 0 && newPage < this.totalPages) {
      this.page = newPage;
      this.loadNotifications();
    }
  }

  markAsRead(notificationId: number): void {
    this.inAppService.markRead(notificationId).subscribe({
      next: () => {
        const notif = this.notifications.find((n) => n.id === notificationId);
        if (notif && !notif.isRead) {
          notif.isRead = true;
          this.totalUnread = Math.max(0, this.totalUnread - 1);
        }
      },
      error: () => this.notify.error('Failed to mark as read'),
    });
  }

  markAllAsRead(): void {
    this.inAppService.markAllRead().subscribe({
      next: () => {
        this.notifications.forEach((n) => (n.isRead = true));
        this.totalUnread = 0;
      },
      error: () => this.notify.error('Failed to mark all as read'),
    });
  }

  refresh(): void {
    this.loadNotifications();
    this.loadUnreadCount();
  }

  applyFilters(): void {
    this.page = 0;
    this.loadNotifications();
  }

  clearFilters(): void {
    this.searchKeyword = '';
    this.showUnreadOnly = false;
    this.fromDate = '';
    this.toDate = '';
    this.applyFilters();
  }

  resolveEntityLabel(notification: InAppNotification): string {
    if (!notification.entityType || !notification.entityId) return '-';
    return `${notification.entityType} #${notification.entityId}`;
  }

  resolveEntityRoute(notification: InAppNotification): string[] | null {
    if (!notification.entityType || !notification.entityId) return null;
    const resolver = this.entityRouteMap[notification.entityType];
    if (!resolver) return null;
    return resolver(notification.entityId);
  }
}
