/* eslint-disable @typescript-eslint/consistent-type-imports */
import { CommonModule } from '@angular/common';
import { Component, OnInit, inject } from '@angular/core';
import { Router } from '@angular/router';

import {
  AppVersionService,
  emptyAppVersion,
  type AppVersionDto,
} from '../../../../services/app-version.service';
import { NotificationService } from '../../../../services/notification.service';
import {
  SettingsService,
  type AppManagementCatalogResponse,
} from '../../../../services/settings.service';

interface HubCard {
  title: string;
  description: string;
  icon: string;
  route: string;
  color: string;
  badge?: string;
  badgeColor?: string;
}

@Component({
  selector: 'app-driver-app-hub',
  standalone: true,
  imports: [CommonModule],
  template: `
    <div class="p-6 max-w-6xl mx-auto">
      <div class="mb-6">
        <h2 class="text-2xl font-bold">Driver App Management</h2>
        <p class="text-sm text-gray-500">
          Central hub for managing the driver mobile application — versions, features, modules,
          alerts and more.
        </p>
      </div>

      <!-- Status Cards Row -->
      <div class="grid grid-cols-1 md:grid-cols-4 gap-4 mb-8">
        <!-- Current Version -->
        <div class="p-4 bg-white border rounded-lg shadow-sm">
          <div class="text-xs text-gray-500 uppercase tracking-wide">Current Version</div>
          <div class="text-2xl font-bold mt-1 font-mono">
            {{ versionInfo?.latestVersion || '—' }}
          </div>
          <div
            class="text-xs mt-1"
            [class.text-red-600]="versionInfo?.mandatoryUpdate"
            [class.text-green-600]="!versionInfo?.mandatoryUpdate"
          >
            {{ versionInfo?.mandatoryUpdate ? 'Force Update ON' : 'Optional Update' }}
          </div>
        </div>

        <!-- Maintenance Status -->
        <div
          class="p-4 border rounded-lg shadow-sm"
          [class.bg-orange-50]="versionInfo?.maintenanceActive"
          [class.border-orange-300]="versionInfo?.maintenanceActive"
          [class.bg-white]="!versionInfo?.maintenanceActive"
        >
          <div class="text-xs text-gray-500 uppercase tracking-wide">Maintenance Mode</div>
          <div
            class="text-lg font-bold mt-1"
            [class.text-orange-700]="versionInfo?.maintenanceActive"
          >
            {{ versionInfo?.maintenanceActive ? 'ACTIVE' : 'Off' }}
          </div>
          <div *ngIf="versionInfo?.maintenanceUntil" class="text-xs text-gray-500 mt-1">
            Until: {{ versionInfo!.maintenanceUntil | date: 'short' }}
          </div>
        </div>

        <!-- Info Banner -->
        <div class="p-4 bg-white border rounded-lg shadow-sm">
          <div class="text-xs text-gray-500 uppercase tracking-wide">Info Banner</div>
          <div class="text-sm mt-1 truncate">
            {{ versionInfo?.infoEn || 'No active info banner' }}
          </div>
        </div>

        <!-- Feature Toggles -->
        <div class="p-4 bg-white border rounded-lg shadow-sm">
          <div class="text-xs text-gray-500 uppercase tracking-wide">Managed Settings</div>
          <div class="text-2xl font-bold mt-1">{{ catalogItemCount }}</div>
          <div class="text-xs text-gray-500 mt-1">screens, features & policies</div>
        </div>
      </div>

      <!-- Navigation Cards -->
      <h3 class="text-lg font-semibold mb-4">Management Modules</h3>
      <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
        <div
          *ngFor="let card of cards"
          class="p-5 bg-white border rounded-lg shadow-sm hover:shadow-md transition-shadow cursor-pointer group"
          (click)="navigate(card.route)"
        >
          <div class="flex items-start justify-between">
            <div class="flex items-center gap-3">
              <span class="material-icons text-3xl" [style.color]="card.color">
                {{ card.icon }}
              </span>
              <div>
                <h4 class="font-semibold group-hover:text-blue-600 transition-colors">
                  {{ card.title }}
                </h4>
                <p class="text-xs text-gray-500 mt-0.5">{{ card.description }}</p>
              </div>
            </div>
            <span
              *ngIf="card.badge"
              class="text-xs px-2 py-0.5 rounded-full font-semibold"
              [style.background-color]="card.badgeColor + '22'"
              [style.color]="card.badgeColor"
            >
              {{ card.badge }}
            </span>
          </div>
        </div>
      </div>

      <!-- Quick Reference -->
      <div class="mt-8 p-4 bg-gray-50 border rounded-lg">
        <h3 class="font-semibold mb-3">How It Works</h3>
        <div class="grid grid-cols-1 md:grid-cols-2 gap-6 text-sm text-gray-600">
          <div>
            <h4 class="font-semibold text-gray-800 mb-1">App Update Flow</h4>
            <ol class="list-decimal list-inside space-y-1">
              <li>Set <strong>Latest Version</strong> and toggle <strong>Force Update</strong></li>
              <li>Driver app checks <code>/api/public/app-version/latest</code> on startup</li>
              <li>If force: app blocks usage until updated via store</li>
              <li>If optional: shows a dismissible update banner</li>
              <li>Platform overrides (Android/iOS) take priority over global</li>
            </ol>
          </div>
          <div>
            <h4 class="font-semibold text-gray-800 mb-1">Feature & Module Control</h4>
            <ol class="list-decimal list-inside space-y-1">
              <li>Toggle screens/features in <strong>App Management</strong></li>
              <li>Driver app fetches config via <code>/api/driver-app/bootstrap</code></li>
              <li>Drawer menu items and home cards hide/show dynamically</li>
              <li>Scoped per GLOBAL / ROLE / USER with resolution priority</li>
              <li>Changes take effect within 10 minutes (cache TTL)</li>
            </ol>
          </div>
        </div>
      </div>
    </div>
  `,
})
export class DriverAppHubComponent implements OnInit {
  private readonly router = inject(Router);
  private readonly versionSvc = inject(AppVersionService);
  private readonly settingsSvc = inject(SettingsService);
  private readonly notif = inject(NotificationService);

  versionInfo: AppVersionDto | null = null;
  catalogItemCount = 0;

  readonly cards: HubCard[] = [
    {
      title: 'App Version & Updates',
      description: 'Manage force/optional updates, release notes, platform overrides, store URLs',
      icon: 'system_update',
      route: '/settings/driver-app/version',
      color: '#1976d2',
    },
    {
      title: 'Maintenance & Info Alerts',
      description: 'Activate maintenance mode, set countdown timers, info banner messages',
      icon: 'engineering',
      route: '/settings/driver-app/version',
      color: '#e65100',
      badge: '',
      badgeColor: '#e65100',
    },
    {
      title: 'Module & Feature Toggles',
      description: 'Enable/disable screens, features, and policies per GLOBAL/ROLE/USER scope',
      icon: 'toggle_on',
      route: '/settings/app-management',
      color: '#2e7d32',
    },
    {
      title: 'Banner Management',
      description: 'Create banners with bilingual content, scheduling, categories, and analytics',
      icon: 'campaign',
      route: '/banners',
      color: '#7b1fa2',
    },
    {
      title: 'Driver Notifications',
      description: 'Send targeted or broadcast notifications, view history, manage FCM delivery',
      icon: 'notifications_active',
      route: '/admin/notifications',
      color: '#c62828',
    },
    {
      title: 'Notification Settings',
      description: 'Configure channels (Telegram, Email, In-App), thresholds, and recipients',
      icon: 'tune',
      route: '/admin/notification-settings',
      color: '#455a64',
    },
  ];

  ngOnInit(): void {
    this.loadVersionInfo();
    this.loadCatalogCount();
  }

  navigate(route: string): void {
    this.router.navigateByUrl(route);
  }

  private loadVersionInfo(): void {
    this.versionSvc.getAll().subscribe({
      next: (versions) => {
        const v = versions?.[0] ?? emptyAppVersion();
        this.versionInfo = v;
        // Set badge on maintenance card
        const maintCard = this.cards.find((c) => c.title.includes('Maintenance'));
        if (maintCard) {
          maintCard.badge = v.maintenanceActive ? 'ACTIVE' : '';
        }
      },
      error: () => {}, // non-critical for dashboard
    });
  }

  private loadCatalogCount(): void {
    this.settingsSvc.getAppManagementCatalog().subscribe({
      next: (catalog) => (this.catalogItemCount = catalog.items?.length ?? 0),
      error: () => {}, // non-critical
    });
  }
}
