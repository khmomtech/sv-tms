import type { OnInit } from '@angular/core';
import { Component } from '@angular/core';
// eslint-disable-next-line @typescript-eslint/consistent-type-imports
import { Router } from '@angular/router';

// eslint-disable-next-line @typescript-eslint/consistent-type-imports
import { AdminNotificationService } from '../../services/admin-notification.service';

@Component({
  selector: 'app-notification',
  standalone: true,
  templateUrl: './notifications.component.html',
})
export class NotificationComponent implements OnInit {
  unreadCount = 0;

  constructor(
    private notifService: AdminNotificationService,
    private router: Router,
  ) {}

  ngOnInit(): void {
    this.notifService.unreadCount$.subscribe((count) => {
      if (count > this.unreadCount) {
        this.showToast(`🔔 ${count} unread notifications`);
      }
      this.unreadCount = count;
    });
  }

  showToast(message: string) {
    const toast = document.createElement('div');
    toast.innerText = message;
    toast.className = 'toast';
    toast.style.cssText =
      'position: fixed; bottom: 20px; right: 20px; background: #333; color: #fff; padding: 12px 20px; border-radius: 4px; cursor: pointer; z-index: 10000;';
    toast.onclick = () => this.router.navigate(['/admin/notifications']);
    document.body.appendChild(toast);
    setTimeout(() => toast.remove(), 5000);
  }
}
