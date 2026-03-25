import { CommonModule } from '@angular/common';
import { Component, EventEmitter, Input, Output } from '@angular/core';

import type { AdminNotification } from '../../services/admin-notification.service';

@Component({
  selector: 'app-notification-dropdown',
  standalone: true,
  imports: [CommonModule],
  templateUrl: './notification-dropdown.component.html',
  styleUrls: ['./notification-dropdown.component.css'],
})
export class NotificationDropdownComponent {
  @Input() unreadCount = 0;
  @Input() notifications: AdminNotification[] = [];
  @Input() dropdownOpen = false;

  @Output() toggle = new EventEmitter<void>();
  @Output() viewAll = new EventEmitter<void>();

  onToggle(): void {
    this.toggle.emit();
  }

  onViewAll(): void {
    this.viewAll.emit();
  }
}
