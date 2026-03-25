import { CommonModule } from '@angular/common';
import { Component, EventEmitter, Input, Output } from '@angular/core';
import { FormsModule } from '@angular/forms';
import { GoogleMapsModule } from '@angular/google-maps';

import type { DriverLocation } from '../../services/socket.service';

@Component({
  selector: 'app-driver-sidebar',
  standalone: true,
  imports: [CommonModule, FormsModule, GoogleMapsModule],
  templateUrl: './driver-sidebar.component.html',
  styleUrls: ['./driver-sidebar.component.css'],
})
export class DriverSidebarComponent {
  @Input() drivers: DriverLocation[] = [];
  @Input() focusedDriverId: string | null = null;
  @Output() focusDriver = new EventEmitter<DriverLocation>();

  isActive(driver: DriverLocation): boolean {
    return this.focusedDriverId === driver.driverId;
  }

  getBadgeClass(driver: DriverLocation): string {
    return driver.isONLINE ? 'bg-green-100 text-green-600' : 'bg-gray-100 text-gray-500';
  }

  getStatusLabel(driver: DriverLocation): string {
    return driver.isONLINE ? 'ONLINE' : 'OFFLINE';
  }

  getTimeAgo(driver: DriverLocation): string {
    if (!driver.lastUpdated) return '—';
    const diffMs = Date.now() - new Date(driver.lastUpdated).getTime();
    const diffMin = Math.floor(diffMs / 60000);
    if (diffMin < 1) return 'Just now';
    if (diffMin === 1) return '1 min ago';
    return `${diffMin} mins ago`;
  }

  onFocus(driver: DriverLocation): void {
    this.focusDriver.emit(driver);
  }

  handleClick(driver: DriverLocation): void {
    this.onFocus(driver);
  }
}
