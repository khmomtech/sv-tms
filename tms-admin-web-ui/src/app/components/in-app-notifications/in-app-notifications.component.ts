import { CommonModule } from '@angular/common';
import { Component, OnInit } from '@angular/core';
import { RouterModule } from '@angular/router';

import {
  InAppNotificationService,
  type InAppNotification,
} from '../../services/in-app-notification.service';
import { NotificationService } from '../../services/notification.service';

@Component({
  selector: 'app-in-app-notifications',
  standalone: true,
  imports: [CommonModule, RouterModule],
  templateUrl: './in-app-notifications.component.html',
  styleUrls: ['./in-app-notifications.component.css'],
})
export class InAppNotificationsComponent implements OnInit {
  notifications: InAppNotification[] = [];
  page = 0;
  totalPages = 0;

  constructor(
    private readonly inAppService: InAppNotificationService,
    private readonly notify: NotificationService,
  ) {}

  ngOnInit(): void {
    this.load();
  }

  load(): void {
    this.inAppService.list(this.page, 20).subscribe({
      next: (res) => {
        this.notifications = res?.data?.content ?? [];
        this.totalPages = res?.data?.totalPages ?? 0;
      },
      error: () => this.notify.error('Failed to load in-app notifications'),
    });
  }

  markRead(id: number): void {
    this.inAppService.markRead(id).subscribe({
      next: () => {
        const notif = this.notifications.find((n) => n.id === id);
        if (notif) notif.isRead = true;
      },
      error: () => this.notify.error('Failed to mark as read'),
    });
  }

  markAll(): void {
    this.inAppService.markAllRead().subscribe({
      next: () => this.notifications.forEach((n) => (n.isRead = true)),
      error: () => this.notify.error('Failed to mark all as read'),
    });
  }

  nextPage(): void {
    if (this.page + 1 < this.totalPages) {
      this.page += 1;
      this.load();
    }
  }

  prevPage(): void {
    if (this.page > 0) {
      this.page -= 1;
      this.load();
    }
  }
}
