/* eslint-disable @typescript-eslint/consistent-type-imports */
import { CommonModule } from '@angular/common';
import { OnInit } from '@angular/core';
import { Component } from '@angular/core';
import { FormsModule } from '@angular/forms';
import { Router } from '@angular/router';
import { RouterLink, RouterLinkActive } from '@angular/router';

interface DriverNavItem {
  id: string;
  label: string;
  icon: string;
  route: string;
  badge?: string;
  description: string;
  category: 'overview' | 'management' | 'monitoring' | 'analytics' | 'communication';
  permissions?: string[];
}

interface DriverNavCategory {
  id: string;
  label: string;
  icon: string;
  items: DriverNavItem[];
}

@Component({
  selector: 'app-driver-management-nav',
  standalone: true,
  imports: [CommonModule, RouterLink, RouterLinkActive, FormsModule],
  templateUrl: './driver-management-nav.component.html',
  styleUrls: ['./driver-management-nav.component.css'],
})
export class DriverManagementNavComponent implements OnInit {
  navCategories: DriverNavCategory[] = [
    {
      id: 'overview',
      label: 'Overview',
      icon: '📊',
      items: [
        {
          id: 'dashboard',
          label: 'Driver Dashboard',
          icon: '📈',
          route: '/drivers',
          description: 'Overview of all drivers with key metrics',
          category: 'overview',
        },
        {
          id: 'quick-stats',
          label: 'Quick Stats',
          icon: '⚡',
          route: '/drivers/stats',
          description: 'Real-time driver statistics and KPIs',
          category: 'overview',
        },
      ],
    },
    {
      id: 'management',
      label: 'Driver Management',
      icon: '👥',
      items: [
        {
          id: 'driver-list',
          label: 'All Drivers',
          icon: '📋',
          route: '/drivers',
          description: 'Complete list of registered drivers',
          category: 'management',
        },
        {
          id: 'add-driver',
          label: 'Add New Driver',
          icon: '➕',
          route: '/drivers/add',
          description: 'Register a new driver in the system',
          category: 'management',
        },
        {
          id: 'driver-profiles',
          label: 'Driver Profiles',
          icon: '👤',
          route: '/drivers/profiles',
          description: 'Detailed driver profile management',
          category: 'management',
        },
        {
          id: 'bulk-actions',
          label: 'Bulk Operations',
          icon: '🔄',
          route: '/drivers/bulk',
          description: 'Bulk update drivers, assignments, and communications',
          category: 'management',
        },
        {
          id: 'vehicle-assignments',
          label: 'Vehicle Assignments',
          icon: '🚚',
          route: '/fleet/vehicles/assignments',
          description: 'Manage permanent and temporary driver–vehicle assignments',
          category: 'management',
          permissions: ['ADMIN', 'SUPERADMIN'],
        },
      ],
    },
    {
      id: 'monitoring',
      label: 'Monitoring & Tracking',
      icon: '📍',
      items: [
        {
          id: 'live-location',
          label: 'Live Map',
          icon: '📍',
          route: '/live/map',
          description: 'Real-time driver location tracking',
          category: 'monitoring',
        },
        {
          id: 'driver-map',
          label: 'Driver Map View',
          icon: '🗺️',
          route: '/live/map',
          description: 'Interactive map showing all driver locations',
          category: 'monitoring',
        },
        {
          id: 'location-history',
          label: 'Location History',
          icon: '📚',
          route: '/drivers/location-history',
          description: 'Historical location data for drivers',
          category: 'monitoring',
        },
        {
          id: 'driver-status',
          label: 'Driver Status',
          icon: '🔴',
          route: '/drivers/status',
          description: 'Current status of all drivers (online/offline/busy)',
          category: 'monitoring',
        },
        {
          id: 'device-tracking',
          label: 'Device Tracking',
          icon: '📱',
          route: '/drivers/devices',
          description: 'Monitor driver device connectivity and health',
          category: 'monitoring',
        },
      ],
    },
    {
      id: 'analytics',
      label: 'Analytics & Reports',
      icon: '📊',
      items: [
        {
          id: 'performance',
          label: 'Performance Analytics',
          icon: '📈',
          route: '/drivers/analytics/performance',
          description: 'Driver performance metrics and trends',
          category: 'analytics',
        },
        {
          id: 'attendance-reports',
          label: 'Attendance Reports',
          icon: '🕐',
          route: '/drivers/analytics/attendance',
          description: 'Driver attendance and working hours reports',
          category: 'analytics',
        },
        {
          id: 'efficiency-metrics',
          label: 'Efficiency Metrics',
          icon: '⚡',
          route: '/drivers/analytics/efficiency',
          description: 'Delivery efficiency and route optimization analytics',
          category: 'analytics',
        },
        {
          id: 'driver-ratings',
          label: 'Driver Ratings',
          icon: '⭐',
          route: '/drivers/analytics/ratings',
          description: 'Customer ratings and feedback analysis',
          category: 'analytics',
        },
        {
          id: 'compliance-reports',
          label: 'Compliance Reports',
          icon: '✅',
          route: '/drivers/analytics/compliance',
          description: 'License, document, and regulatory compliance tracking',
          category: 'analytics',
        },
      ],
    },
    {
      id: 'communication',
      label: 'Communication',
      icon: '💬',
      items: [
        {
          id: 'messages',
          label: 'Driver Messages',
          icon: '💬',
          route: '/drivers/communication/messages',
          badge: '3',
          description: 'Send and receive messages with drivers',
          category: 'communication',
        },
        {
          id: 'notifications',
          label: 'Push Notifications',
          icon: '🔔',
          route: '/drivers/communication/notifications',
          description: 'Send push notifications to driver devices',
          category: 'communication',
        },
        {
          id: 'announcements',
          label: 'Announcements',
          icon: '📢',
          route: '/drivers/communication/announcements',
          description: 'Broadcast important announcements to all drivers',
          category: 'communication',
        },
        {
          id: 'feedback',
          label: 'Driver Feedback',
          icon: '💭',
          route: '/drivers/communication/feedback',
          description: 'Collect and manage driver feedback',
          category: 'communication',
        },
      ],
    },
  ];

  activeCategory: string = 'overview';
  searchTerm: string = '';
  collapsedCategories: Set<string> = new Set();

  constructor(private router: Router) {}

  ngOnInit(): void {
    // Set active category based on current route
    this.setActiveCategoryFromRoute();
  }

  setActiveCategoryFromRoute(): void {
    const currentUrl = this.router.url;

    for (const category of this.navCategories) {
      const activeItem = category.items.find(
        (item) =>
          currentUrl.startsWith(item.route) ||
          (item.route !== '/drivers' && currentUrl.includes(item.route)),
      );

      if (activeItem) {
        this.activeCategory = category.id;
        break;
      }
    }
  }

  setActiveCategory(categoryId: string): void {
    this.activeCategory = categoryId;
  }

  toggleCategory(categoryId: string): void {
    if (this.collapsedCategories.has(categoryId)) {
      this.collapsedCategories.delete(categoryId);
    } else {
      this.collapsedCategories.add(categoryId);
    }
  }

  isCategoryCollapsed(categoryId: string): boolean {
    return this.collapsedCategories.has(categoryId);
  }

  getFilteredItems(category: DriverNavCategory): DriverNavItem[] {
    if (!this.searchTerm) return category.items;

    return category.items.filter(
      (item) =>
        item.label.toLowerCase().includes(this.searchTerm.toLowerCase()) ||
        item.description.toLowerCase().includes(this.searchTerm.toLowerCase()),
    );
  }

  onSearchChange(): void {
    // Expand all categories when searching
    if (this.searchTerm) {
      this.collapsedCategories.clear();
    }
  }

  clearSearch(): void {
    this.searchTerm = '';
    this.collapsedCategories.clear();
  }

  getTotalItemsInCategory(category: DriverNavCategory): number {
    return this.getFilteredItems(category).length;
  }

  trackByCategoryId(index: number, category: DriverNavCategory): string {
    return category.id;
  }

  trackByItemId(index: number, item: DriverNavItem): string {
    return item.id;
  }
}
