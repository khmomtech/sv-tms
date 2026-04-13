/* eslint-disable @typescript-eslint/consistent-type-imports */
import { CommonModule } from '@angular/common';
import { Component, OnInit, inject } from '@angular/core';
import { FormBuilder, FormGroup, ReactiveFormsModule, Validators } from '@angular/forms';

import {
  AppVersionService,
  type AppVersionDto,
  emptyAppVersion,
} from '../../../../services/app-version.service';
import { NotificationService } from '../../../../services/notification.service';

@Component({
  selector: 'app-version-management',
  standalone: true,
  imports: [CommonModule, ReactiveFormsModule],
  template: `
    <div class="p-6 max-w-5xl mx-auto space-y-6">
      <!-- Header -->
      <div class="flex items-center justify-between">
        <div>
          <h2 class="text-xl font-bold">App Version & Update Management</h2>
          <p class="text-sm text-gray-500">
            Control force updates, optional updates, maintenance mode, and info banners for the
            driver app.
          </p>
        </div>
        <span *ngIf="lastUpdated" class="text-xs text-gray-400">
          Last updated: {{ lastUpdated }}
        </span>
      </div>

      <div *ngIf="loading" class="text-gray-500">Loading current version config...</div>
      <div *ngIf="loadError" class="p-3 bg-red-50 text-red-700 rounded">{{ loadError }}</div>

      <form *ngIf="!loading && form" [formGroup]="form" (ngSubmit)="save()" class="space-y-6">
        <!-- ════════════════════════════════════════════════ -->
        <!-- SECTION: Global Version                         -->
        <!-- ════════════════════════════════════════════════ -->
        <fieldset class="border rounded-lg p-4">
          <legend class="px-2 font-semibold text-gray-700">Global Version</legend>
          <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
            <div>
              <label class="label">Latest Version *</label>
              <input class="input w-full" formControlName="latestVersion" placeholder="2.5.0" />
            </div>
            <div>
              <label class="label">Min Supported Version</label>
              <input
                class="input w-full"
                formControlName="minSupportedVersion"
                placeholder="2.3.0"
              />
              <p class="text-xs text-gray-500 mt-1">
                Versions below this are blocked when force update is enabled.
              </p>
            </div>
            <div class="flex items-center gap-3 pt-5">
              <input
                type="checkbox"
                id="mandatoryUpdate"
                formControlName="mandatoryUpdate"
                class="h-5 w-5"
              />
              <label for="mandatoryUpdate" class="font-semibold text-red-600">
                Force Update (mandatory)
              </label>
            </div>
            <div>
              <label class="label">Play Store URL</label>
              <input
                class="input w-full"
                formControlName="playstoreUrl"
                placeholder="https://play.google.com/store/apps/details?id=..."
              />
            </div>
            <div>
              <label class="label">App Store URL</label>
              <input
                class="input w-full"
                formControlName="appstoreUrl"
                placeholder="https://apps.apple.com/app/..."
              />
            </div>
            <div>
              <label class="label">Release Note (EN)</label>
              <textarea
                class="input w-full"
                rows="3"
                formControlName="releaseNoteEn"
                placeholder="What's new in this version..."
              ></textarea>
            </div>
            <div>
              <label class="label">Release Note (KM)</label>
              <textarea
                class="input w-full"
                rows="3"
                formControlName="releaseNoteKm"
                placeholder="អ្វីដែលថ្មីក្នុងកំណែនេះ..."
              ></textarea>
            </div>
          </div>
        </fieldset>

        <!-- ════════════════════════════════════════════════ -->
        <!-- SECTION: Android Specific                       -->
        <!-- ════════════════════════════════════════════════ -->
        <fieldset class="border rounded-lg p-4">
          <legend class="px-2 font-semibold text-green-700">
            <span class="inline-flex items-center gap-1">
              <svg class="w-4 h-4" viewBox="0 0 24 24" fill="currentColor">
                <path
                  d="M17.523 2.223l1.645 1.645-2.55 2.55A8.948 8.948 0 0120 12a9 9 0 11-9-9 8.948 8.948 0 015.582 1.932l2.55-2.55zM11 6a7 7 0 107 7 7 7 0 00-7-7z"
                />
              </svg>
              Android Override
            </span>
          </legend>
          <p class="text-xs text-gray-500 mb-3">Leave blank to use global values.</p>
          <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
            <div>
              <label class="label">Android Latest Version</label>
              <input
                class="input w-full"
                formControlName="androidLatestVersion"
                placeholder="2.5.0"
              />
            </div>
            <div class="flex items-center gap-3 pt-5">
              <input
                type="checkbox"
                id="androidMandatoryUpdate"
                formControlName="androidMandatoryUpdate"
                class="h-5 w-5"
              />
              <label for="androidMandatoryUpdate" class="font-semibold text-red-600">
                Android Force Update
              </label>
            </div>
            <div>
              <label class="label">Android Release Note (EN)</label>
              <textarea
                class="input w-full"
                rows="2"
                formControlName="androidReleaseNoteEn"
              ></textarea>
            </div>
            <div>
              <label class="label">Android Release Note (KM)</label>
              <textarea
                class="input w-full"
                rows="2"
                formControlName="androidReleaseNoteKm"
              ></textarea>
            </div>
          </div>
        </fieldset>

        <!-- ════════════════════════════════════════════════ -->
        <!-- SECTION: iOS Specific                           -->
        <!-- ════════════════════════════════════════════════ -->
        <fieldset class="border rounded-lg p-4">
          <legend class="px-2 font-semibold text-blue-700">
            <span class="inline-flex items-center gap-1">
              <svg class="w-4 h-4" viewBox="0 0 24 24" fill="currentColor">
                <path
                  d="M18.71 19.5c-.83 1.24-1.71 2.45-3.05 2.47-1.34.03-1.77-.79-3.29-.79-1.53 0-2 .77-3.27.82-1.31.05-2.3-1.32-3.14-2.53C4.25 17 2.94 12.45 4.7 9.39c.87-1.52 2.43-2.48 4.12-2.51 1.28-.02 2.5.87 3.29.87.78 0 2.26-1.07 3.8-.91.65.03 2.47.26 3.64 1.98-.09.06-2.17 1.28-2.15 3.81.03 3.02 2.65 4.03 2.68 4.04-.03.07-.42 1.44-1.38 2.83M13 3.5c.73-.83 1.94-1.46 2.94-1.5.13 1.17-.34 2.35-1.04 3.19-.69.85-1.83 1.51-2.95 1.42-.15-1.15.41-2.35 1.05-3.11z"
                />
              </svg>
              iOS Override
            </span>
          </legend>
          <p class="text-xs text-gray-500 mb-3">Leave blank to use global values.</p>
          <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
            <div>
              <label class="label">iOS Latest Version</label>
              <input class="input w-full" formControlName="iosLatestVersion" placeholder="2.5.0" />
            </div>
            <div class="flex items-center gap-3 pt-5">
              <input
                type="checkbox"
                id="iosMandatoryUpdate"
                formControlName="iosMandatoryUpdate"
                class="h-5 w-5"
              />
              <label for="iosMandatoryUpdate" class="font-semibold text-red-600">
                iOS Force Update
              </label>
            </div>
            <div>
              <label class="label">iOS Release Note (EN)</label>
              <textarea class="input w-full" rows="2" formControlName="iosReleaseNoteEn"></textarea>
            </div>
            <div>
              <label class="label">iOS Release Note (KM)</label>
              <textarea class="input w-full" rows="2" formControlName="iosReleaseNoteKm"></textarea>
            </div>
          </div>
        </fieldset>

        <!-- ════════════════════════════════════════════════ -->
        <!-- SECTION: Maintenance Mode                       -->
        <!-- ════════════════════════════════════════════════ -->
        <fieldset
          class="border rounded-lg p-4"
          [class.border-orange-400]="form.value.maintenanceActive"
        >
          <legend class="px-2 font-semibold" [class.text-orange-700]="form.value.maintenanceActive">
            <span class="inline-flex items-center gap-1">
              🔧 Maintenance Mode
              <span
                *ngIf="form.value.maintenanceActive"
                class="text-xs bg-orange-100 text-orange-700 px-2 py-0.5 rounded-full font-normal"
              >
                ACTIVE
              </span>
            </span>
          </legend>
          <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
            <div class="flex items-center gap-3">
              <input
                type="checkbox"
                id="maintenanceActive"
                formControlName="maintenanceActive"
                class="h-5 w-5"
              />
              <label for="maintenanceActive" class="font-semibold text-orange-700">
                Maintenance Mode Active
              </label>
            </div>
            <div>
              <label class="label">Maintenance Until</label>
              <input
                type="datetime-local"
                class="input w-full"
                formControlName="maintenanceUntil"
              />
            </div>
            <div>
              <label class="label">Message (EN)</label>
              <textarea
                class="input w-full"
                rows="2"
                formControlName="maintenanceMessageEn"
                placeholder="System is under maintenance. We'll be back soon."
              ></textarea>
            </div>
            <div>
              <label class="label">Message (KM)</label>
              <textarea
                class="input w-full"
                rows="2"
                formControlName="maintenanceMessageKm"
                placeholder="ប្រព័ន្ធកំពុងត្រូវបានថែទាំ។ យើងនឹងត្រឡប់មកវិញឆាប់ៗ។"
              ></textarea>
            </div>
          </div>
          <div
            *ngIf="form.value.maintenanceActive"
            class="mt-3 p-3 bg-orange-50 border border-orange-200 rounded text-sm"
          >
            <strong>⚠ Warning:</strong> When maintenance mode is active, the driver app will show a
            maintenance screen and block normal usage until the maintenance period ends or you
            deactivate this toggle.
          </div>
        </fieldset>

        <!-- ════════════════════════════════════════════════ -->
        <!-- SECTION: Information Banner                     -->
        <!-- ════════════════════════════════════════════════ -->
        <fieldset class="border rounded-lg p-4">
          <legend class="px-2 font-semibold text-blue-700">
            <span class="inline-flex items-center gap-1">ℹ️ Information Alert Banner</span>
          </legend>
          <p class="text-xs text-gray-500 mb-3">
            This message appears as an info strip at the top of the driver app. Leave blank to hide.
          </p>
          <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
            <div>
              <label class="label">Info Message (EN)</label>
              <textarea
                class="input w-full"
                rows="2"
                formControlName="infoEn"
                placeholder="New dispatch flow is available. Update your app!"
              ></textarea>
            </div>
            <div>
              <label class="label">Info Message (KM)</label>
              <textarea
                class="input w-full"
                rows="2"
                formControlName="infoKm"
                placeholder="ស្រោចថ្មីគឺអាចប្រើបាន។ បន្ទាន់កម្មវិធីរបស់អ្នក!"
              ></textarea>
            </div>
          </div>
        </fieldset>

        <!-- ════════════════════════════════════════════════ -->
        <!-- SECTION: Preview                                -->
        <!-- ════════════════════════════════════════════════ -->
        <div class="border rounded-lg p-4 bg-gray-50">
          <h3 class="font-semibold mb-3">Driver App Preview</h3>
          <div class="grid grid-cols-1 md:grid-cols-3 gap-4 text-sm">
            <div class="p-3 bg-white border rounded">
              <div class="text-xs text-gray-500 mb-1">Update Behavior (Global)</div>
              <div
                class="font-semibold"
                [class.text-red-600]="form.value.mandatoryUpdate"
                [class.text-green-600]="!form.value.mandatoryUpdate"
              >
                {{
                  form.value.mandatoryUpdate
                    ? 'FORCE UPDATE — Blocks App'
                    : 'OPTIONAL — Banner Only'
                }}
              </div>
              <div class="text-xs text-gray-400 mt-1">
                v{{ form.value.latestVersion || '?.?.?' }}
              </div>
            </div>
            <div class="p-3 bg-white border rounded">
              <div class="text-xs text-gray-500 mb-1">Android</div>
              <div class="font-mono text-sm">
                {{ form.value.androidLatestVersion || '(uses global)' }}
              </div>
              <div class="text-xs mt-1" [class.text-red-600]="form.value.androidMandatoryUpdate">
                {{ form.value.androidMandatoryUpdate ? 'Force' : 'Not forced' }}
              </div>
            </div>
            <div class="p-3 bg-white border rounded">
              <div class="text-xs text-gray-500 mb-1">iOS</div>
              <div class="font-mono text-sm">
                {{ form.value.iosLatestVersion || '(uses global)' }}
              </div>
              <div class="text-xs mt-1" [class.text-red-600]="form.value.iosMandatoryUpdate">
                {{ form.value.iosMandatoryUpdate ? 'Force' : 'Not forced' }}
              </div>
            </div>
          </div>

          <!-- Maintenance preview -->
          <div
            *ngIf="form.value.maintenanceActive"
            class="mt-3 p-3 bg-orange-50 border border-orange-200 rounded"
          >
            <div class="font-semibold text-orange-700">🔧 Maintenance Active</div>
            <div class="text-sm mt-1">
              {{ form.value.maintenanceMessageEn || 'No message set' }}
            </div>
            <div *ngIf="form.value.maintenanceUntil" class="text-xs text-gray-500 mt-1">
              Until: {{ form.value.maintenanceUntil }}
            </div>
          </div>

          <!-- Info banner preview -->
          <div
            *ngIf="form.value.infoEn || form.value.infoKm"
            class="mt-3 p-3 bg-blue-50 border border-blue-200 rounded"
          >
            <div class="font-semibold text-blue-700">ℹ️ Info Banner</div>
            <div class="text-sm mt-1">{{ form.value.infoEn }}</div>
            <div *ngIf="form.value.infoKm" class="text-sm mt-1 text-gray-500">
              {{ form.value.infoKm }}
            </div>
          </div>
        </div>

        <!-- Submit -->
        <div class="flex items-center justify-between">
          <button type="button" class="btn btn-outline" (click)="reload()">Reload</button>
          <button type="submit" class="btn btn-primary" [disabled]="saving || form.invalid">
            {{ saving ? 'Saving...' : 'Save App Version Config' }}
          </button>
        </div>
      </form>

      <!-- ════════════════════════════════════════════════ -->
      <!-- SECTION: Version History                        -->
      <!-- ════════════════════════════════════════════════ -->
      <div *ngIf="allVersions.length > 1" class="border rounded-lg p-4 bg-gray-50 mt-6">
        <h3 class="font-semibold mb-3">Version History</h3>
        <div class="overflow-auto">
          <table class="w-full text-sm">
            <thead>
              <tr class="border-b bg-white">
                <th class="text-left p-2">ID</th>
                <th class="text-left p-2">Version</th>
                <th class="text-left p-2">Android</th>
                <th class="text-left p-2">iOS</th>
                <th class="text-left p-2">Mandatory</th>
                <th class="text-left p-2">Maintenance</th>
                <th class="text-left p-2">Updated</th>
              </tr>
            </thead>
            <tbody>
              <tr *ngFor="let v of allVersions" class="border-b hover:bg-white">
                <td class="p-2">{{ v.id }}</td>
                <td class="p-2 font-mono">{{ v.latestVersion }}</td>
                <td class="p-2 font-mono">{{ v.androidLatestVersion || '-' }}</td>
                <td class="p-2 font-mono">{{ v.iosLatestVersion || '-' }}</td>
                <td class="p-2">
                  <span
                    class="text-xs px-1.5 py-0.5 rounded"
                    [class.bg-red-100]="v.mandatoryUpdate"
                    [class.text-red-700]="v.mandatoryUpdate"
                    [class.bg-green-100]="!v.mandatoryUpdate"
                    [class.text-green-700]="!v.mandatoryUpdate"
                  >
                    {{ v.mandatoryUpdate ? 'FORCE' : 'Optional' }}
                  </span>
                </td>
                <td class="p-2">
                  <span
                    *ngIf="v.maintenanceActive"
                    class="text-xs bg-orange-100 text-orange-700 px-1.5 py-0.5 rounded"
                    >Active</span
                  >
                  <span *ngIf="!v.maintenanceActive" class="text-xs text-gray-400">Off</span>
                </td>
                <td class="p-2 text-xs text-gray-500">{{ v.lastUpdated || '-' }}</td>
              </tr>
            </tbody>
          </table>
        </div>
      </div>
    </div>
  `,
})
export class AppVersionManagementComponent implements OnInit {
  private readonly svc = inject(AppVersionService);
  private readonly fb = inject(FormBuilder);
  private readonly notif = inject(NotificationService);

  form!: FormGroup;
  loading = false;
  saving = false;
  loadError = '';
  lastUpdated = '';
  allVersions: AppVersionDto[] = [];

  ngOnInit(): void {
    this.buildForm(emptyAppVersion());
    this.reload();
  }

  reload(): void {
    this.loading = true;
    this.loadError = '';

    this.svc.getAll().subscribe({
      next: (versions) => {
        const safeVersions = versions ?? [];
        this.allVersions = safeVersions;
        const safeVersion = safeVersions[0] ?? emptyAppVersion();
        this.buildForm(safeVersion);
        this.lastUpdated = safeVersion.lastUpdated ?? '';
        this.loading = false;
      },
      error: (err: Error) => {
        this.loadError = err.message;
        this.loading = false;
      },
    });
  }

  private buildForm(v: AppVersionDto | null | undefined): void {
    const data = v ?? emptyAppVersion();

    this.form = this.fb.group({
      id: [data.id ?? null],
      latestVersion: [
        data.latestVersion,
        [Validators.required, Validators.pattern(/^\d+\.\d+\.\d+$/)],
      ],
      minSupportedVersion: [
        data.minSupportedVersion,
        [Validators.pattern(/^$|^\d+\.\d+\.\d+$/)],
      ],
      mandatoryUpdate: [data.mandatoryUpdate],
      playstoreUrl: [data.playstoreUrl],
      appstoreUrl: [data.appstoreUrl],
      releaseNoteEn: [data.releaseNoteEn],
      releaseNoteKm: [data.releaseNoteKm],
      androidLatestVersion: [data.androidLatestVersion],
      androidMandatoryUpdate: [data.androidMandatoryUpdate],
      androidReleaseNoteEn: [data.androidReleaseNoteEn],
      androidReleaseNoteKm: [data.androidReleaseNoteKm],
      iosLatestVersion: [data.iosLatestVersion],
      iosMandatoryUpdate: [data.iosMandatoryUpdate],
      iosReleaseNoteEn: [data.iosReleaseNoteEn],
      iosReleaseNoteKm: [data.iosReleaseNoteKm],
      maintenanceActive: [data.maintenanceActive],
      maintenanceMessageEn: [data.maintenanceMessageEn],
      maintenanceMessageKm: [data.maintenanceMessageKm],
      maintenanceUntil: [data.maintenanceUntil ? this.toLocalDatetime(data.maintenanceUntil) : ''],
      infoEn: [data.infoEn],
      infoKm: [data.infoKm],
    });
  }

  save(): void {
    if (this.form.invalid) return;
    this.saving = true;

    const dto: AppVersionDto = { ...this.form.value };
    // Convert datetime-local to ISO string
    if (dto.maintenanceUntil) {
      dto.maintenanceUntil = new Date(dto.maintenanceUntil).toISOString();
    }

    this.svc.save(dto).subscribe({
      next: (saved) => {
        const safeSaved = saved ?? dto;
        this.saving = false;
        this.lastUpdated = safeSaved.lastUpdated ?? '';
        this.notif.success('App version config saved successfully');
        this.loadAllVersions();
      },
      error: (err: Error) => {
        this.saving = false;
        this.notif.error(err.message);
      },
    });
  }

  private loadAllVersions(): void {
    this.svc.getAll().subscribe({
      next: (versions) => (this.allVersions = versions ?? []),
      error: () => {}, // non-critical
    });
  }

  private toLocalDatetime(iso: string): string {
    try {
      const d = new Date(iso);
      if (isNaN(d.getTime())) return '';
      // Format: YYYY-MM-DDTHH:mm for datetime-local input
      return d.toISOString().slice(0, 16);
    } catch {
      return '';
    }
  }
}
