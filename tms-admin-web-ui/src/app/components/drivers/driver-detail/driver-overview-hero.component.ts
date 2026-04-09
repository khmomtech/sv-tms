import { CommonModule } from '@angular/common';
import { Component, Input } from '@angular/core';

@Component({
  standalone: true,
  selector: 'app-driver-overview-hero',
  imports: [CommonModule],
  template: `
    <section class="mb-6">
      <div
        class="space-y-6 rounded-2xl border border-blue-100 bg-gradient-to-b from-white to-blue-50 p-6 shadow-lg"
      >
        <div class="flex flex-col gap-4 md:flex-row md:items-center md:justify-between">
          <div class="flex items-center gap-4">
            <div
              class="flex h-20 w-20 items-center justify-center overflow-hidden rounded-full border border-blue-200 bg-blue-50"
            >
              <ng-container *ngIf="profilePreviewUrl; else avatarFallbackSmall">
                <img [src]="profilePreviewUrl" alt="Driver photo" class="h-full w-full object-cover" />
              </ng-container>
              <ng-template #avatarFallbackSmall>
                <svg
                  class="h-12 w-12 text-blue-400"
                  fill="none"
                  stroke="currentColor"
                  viewBox="0 0 24 24"
                >
                  <path
                    stroke-linecap="round"
                    stroke-linejoin="round"
                    stroke-width="1.5"
                    d="M16 7a4 4 0 11-8 0 4 4 0 018 0zM12 14a7 7 0 00-7 7h14a7 7 0 00-7-7z"
                  ></path>
                </svg>
              </ng-template>
            </div>
            <div>
              <p class="text-lg font-semibold text-gray-900">
                {{ driverName || '—' }}
                <span class="text-sm font-normal text-gray-500">#DR-{{ driverId }}</span>
              </p>
              <p class="text-sm text-gray-600">⭐ {{ rating.toFixed(1) }} Rating</p>
            </div>
          </div>
          <div class="text-sm text-gray-600">
            <p class="font-semibold text-gray-700">📞 {{ phone }}</p>
            <p>Last Seen: {{ lastSeen }}</p>
          </div>
        </div>

        <div class="grid grid-cols-2 gap-4 text-sm text-gray-700 md:grid-cols-5">
          <div>
            <p class="text-xs uppercase text-gray-400">Zone</p>
            <p class="font-semibold">{{ zone }}</p>
          </div>
          <div>
            <p class="text-xs uppercase text-gray-400">Group</p>
            <p class="font-semibold">{{ group }}</p>
          </div>
          <div>
            <p class="text-xs uppercase text-gray-400">Vendor</p>
            <p class="font-semibold">{{ vendor }}</p>
          </div>
          <div>
            <p class="text-xs uppercase text-gray-400">Presence</p>
            <p class="font-semibold">{{ presence }}</p>
          </div>
          <div>
            <p class="text-xs uppercase text-gray-400">Employment Status</p>
            <p class="font-semibold">{{ employmentStatus }}</p>
          </div>
        </div>

        <div class="grid grid-cols-2 gap-3 md:grid-cols-4">
          <div
            *ngFor="let stat of metrics"
            class="rounded-xl border border-blue-100 bg-white p-3 text-sm text-gray-600 shadow-sm"
          >
            <p class="text-xs uppercase tracking-wide text-blue-500">{{ stat.label }}</p>
            <p class="text-lg font-semibold text-gray-900">{{ stat.value }}</p>
          </div>
        </div>

        <div
          class="flex flex-col gap-2 border-t border-blue-100 pt-3 text-sm text-gray-700 md:flex-row md:items-center md:justify-between"
        >
          <p class="font-semibold">🚛 Current Vehicle: {{ currentVehicleLabel }}</p>
          <p class="text-gray-500" *ngIf="currentVehicleSince">Assigned Since: {{ currentVehicleSince }}</p>
        </div>
      </div>
    </section>
  `,
})
export class DriverOverviewHeroComponent {
  @Input() profilePreviewUrl: string | null = null;
  @Input() driverName = '';
  @Input() driverId!: number;
  @Input() rating = 0;
  @Input() phone = '—';
  @Input() lastSeen = 'Not available';
  @Input() zone = '—';
  @Input() group = '—';
  @Input() vendor = '—';
  @Input() presence = 'OFFLINE';
  @Input() employmentStatus = 'Unknown';
  @Input() metrics: Array<{ label: string; value: string }> = [];
  @Input() currentVehicleLabel = '—';
  @Input() currentVehicleSince = '';
}
