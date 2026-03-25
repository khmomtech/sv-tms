/* eslint-disable @typescript-eslint/consistent-type-imports */
import { CommonModule } from '@angular/common';
import { Component, OnInit, inject } from '@angular/core';
import { FormBuilder, FormGroup, ReactiveFormsModule, Validators } from '@angular/forms';
import { firstValueFrom, forkJoin, of } from 'rxjs';
import { catchError } from 'rxjs/operators';

import { NotificationService } from '../../../../services/notification.service';
import {
  SettingsService,
  type AppBootstrapResponse,
  type AppManagementCatalogItem,
  type AppManagementCatalogResponse,
  type SettingReadResponse,
  type SettingWriteRequest,
} from '../../../../services/settings.service';

type AppScope = 'GLOBAL' | 'ROLE' | 'USER';
type ValueType = 'BOOLEAN' | 'NUMBER' | 'STRING';

interface UiItem {
  spec: AppManagementCatalogItem;
  fullKey: string;
  controlName: string;
  valueType: ValueType;
}

interface SettingAuditRow {
  groupCode: string;
  keyCode: string;
  scope: string;
  scopeRef: string | null;
  oldValue: string | null;
  newValue: string | null;
  updatedBy: string;
  updatedAt: string;
  reason: string;
}

interface EffectiveCompareDiff {
  onlyInA: Record<string, unknown>;
  onlyInB: Record<string, unknown>;
  changed: Array<{ key: string; a: unknown; b: unknown }>;
}

type ComparePrefix = 'all' | 'screens' | 'features' | 'policies';

@Component({
  selector: 'app-app-management',
  standalone: true,
  imports: [CommonModule, ReactiveFormsModule],
  template: `
    <div class="p-6 bg-white rounded">
      <div class="flex flex-col gap-2 md:flex-row md:items-center md:justify-between">
        <div>
          <h2 class="text-xl font-bold">Driver App Management</h2>
          <p class="text-sm text-gray-500">Central control for screens, features, and policies.</p>
        </div>
        <div class="text-xs text-gray-500" *ngIf="catalog">
          Resolution: {{ catalog.resolutionOrder }}
        </div>
      </div>

      <form class="grid grid-cols-1 gap-3 mt-4 md:grid-cols-4" [formGroup]="scopeForm">
        <div>
          <label class="font-semibold">Scope</label>
          <select class="w-full input" formControlName="scope" (change)="loadScopedValues()">
            <option value="GLOBAL">GLOBAL</option>
            <option value="ROLE">ROLE</option>
            <option value="USER">USER</option>
          </select>
        </div>
        <div *ngIf="selectedScope !== 'GLOBAL'">
          <label class="font-semibold">Scope Ref</label>
          <input
            class="w-full input"
            [placeholder]="
              selectedScope === 'ROLE' ? 'DRIVER or segment:driver.partner' : 'User ID'
            "
            formControlName="scopeRef"
          />
        </div>
        <div>
          <label class="font-semibold">Reason</label>
          <input class="w-full input" formControlName="reason" placeholder="Admin update" />
        </div>
        <div class="self-end">
          <button type="button" class="btn btn-secondary w-full" (click)="loadScopedValues()">
            Reload Scope
          </button>
        </div>
      </form>

      <div *ngIf="loading" class="mt-4 text-gray-500">Loading app-management catalog...</div>
      <div *ngIf="loadError" class="mt-4 text-red-600">{{ loadError }}</div>

      <form *ngIf="!loading && uiItems.length" [formGroup]="valueForm" (ngSubmit)="save()">
        <div *ngFor="let group of groupCodes" class="mt-6">
          <h3 class="font-semibold text-lg mb-2">{{ group }}</h3>
          <div class="grid gap-2">
            <div
              *ngFor="let item of getGroupItems(group)"
              class="grid grid-cols-1 md:grid-cols-2 gap-2 p-3 border rounded"
            >
              <div>
                <div class="font-semibold">{{ item.spec.label || item.spec.keyCode }}</div>
                <div class="text-xs text-gray-500">{{ item.spec.description }}</div>
                <div class="text-xs text-gray-400 mt-1">
                  {{ item.spec.keyCode }} ({{ item.spec.type }})
                </div>
                <div *ngIf="isDynamicKey(item.fullKey)" class="text-xs text-blue-700 mt-2">
                  Allowed:
                  <span class="font-mono">{{ allowedValuesFor(item.fullKey).join(', ') }}</span>
                </div>
              </div>
              <div class="flex items-center md:justify-end">
                <input
                  *ngIf="item.valueType === 'NUMBER'"
                  type="number"
                  class="w-full input"
                  [formControlName]="item.controlName"
                />
                <input
                  *ngIf="item.valueType === 'BOOLEAN'"
                  type="checkbox"
                  class="h-5 w-5"
                  [formControlName]="item.controlName"
                />
                <input
                  *ngIf="item.valueType === 'STRING'"
                  class="w-full input"
                  [formControlName]="item.controlName"
                />
              </div>
              <div class="md:col-span-2 flex justify-end gap-2">
                <button
                  *ngIf="isDynamicKey(item.fullKey)"
                  type="button"
                  class="btn btn-outline"
                  [disabled]="savingItemKeys.has(item.fullKey)"
                  (click)="applyRecommended(item)"
                >
                  Use Recommended
                </button>
                <button
                  type="button"
                  class="btn btn-secondary"
                  [disabled]="savingItemKeys.has(item.fullKey) || scopeForm.invalid"
                  (click)="saveItem(item)"
                >
                  {{ savingItemKeys.has(item.fullKey) ? 'Saving...' : 'Save Key' }}
                </button>
                <button
                  type="button"
                  class="btn btn-outline"
                  [disabled]="auditLoadingKeys.has(item.fullKey)"
                  (click)="toggleAudit(item)"
                >
                  {{
                    expandedAuditKey === item.fullKey
                      ? 'Hide History'
                      : auditLoadingKeys.has(item.fullKey)
                        ? 'Loading...'
                        : 'View History'
                  }}
                </button>
              </div>
              <div
                *ngIf="expandedAuditKey === item.fullKey"
                class="md:col-span-2 border rounded p-2 bg-gray-50"
              >
                <div *ngIf="!auditByKey[item.fullKey]?.length" class="text-xs text-gray-500">
                  No audit history.
                </div>
                <table *ngIf="auditByKey[item.fullKey]?.length" class="w-full text-xs">
                  <thead>
                    <tr class="border-b">
                      <th class="text-left py-1">When</th>
                      <th class="text-left py-1">By</th>
                      <th class="text-left py-1">Scope</th>
                      <th class="text-left py-1">Old</th>
                      <th class="text-left py-1">New</th>
                    </tr>
                  </thead>
                  <tbody>
                    <tr *ngFor="let a of auditByKey[item.fullKey]" class="border-b">
                      <td class="py-1">{{ a.updatedAt }}</td>
                      <td class="py-1">{{ a.updatedBy }}</td>
                      <td class="py-1">{{ a.scope }}/{{ a.scopeRef || '-' }}</td>
                      <td class="py-1 truncate max-w-[220px]">{{ a.oldValue }}</td>
                      <td class="py-1 truncate max-w-[220px]">{{ a.newValue }}</td>
                    </tr>
                  </tbody>
                </table>
              </div>
            </div>
          </div>
        </div>

        <div class="flex justify-end mt-6">
          <button class="btn btn-primary" type="submit" [disabled]="saving || scopeForm.invalid">
            {{ saving ? 'Saving...' : 'Save App Management Settings' }}
          </button>
        </div>
      </form>

      <div class="mt-8 p-4 border rounded bg-gray-50">
        <h3 class="font-semibold">Effective Config Preview</h3>
        <form
          class="grid grid-cols-1 gap-3 mt-3 md:grid-cols-4"
          [formGroup]="previewForm"
          (ngSubmit)="preview()"
        >
          <div class="md:col-span-2">
            <label class="font-semibold">User ID</label>
            <input class="w-full input" formControlName="userId" type="number" min="1" />
          </div>
          <div class="self-end md:col-span-2">
            <button
              class="btn btn-secondary w-full"
              type="submit"
              [disabled]="previewLoading || previewForm.invalid"
            >
              {{ previewLoading ? 'Loading...' : 'Preview Effective Config' }}
            </button>
          </div>
        </form>
        <div *ngIf="previewError" class="mt-2 text-red-600">{{ previewError }}</div>
        <div *ngIf="previewData" class="mt-3 grid grid-cols-1 md:grid-cols-2 gap-3 text-sm">
          <div class="p-3 bg-white border rounded">
            <div class="font-semibold">Drawer Items</div>
            <div class="text-xs text-gray-500 mt-1">
              {{ previewDrawerItems().join(', ') || 'Default' }}
            </div>
            <div *ngIf="previewDrawerError()" class="text-xs text-red-600 mt-2">
              {{ previewDrawerError() }}
            </div>
          </div>
          <div class="p-3 bg-white border rounded">
            <div class="font-semibold">Bottom Nav</div>
            <div class="text-xs text-gray-500 mt-1">
              {{ previewBottomItems().join(', ') || 'Default' }}
            </div>
            <div *ngIf="previewBottomError()" class="text-xs text-red-600 mt-2">
              {{ previewBottomError() }}
            </div>
          </div>
          <div class="p-3 bg-white border rounded">
            <div class="font-semibold">Home Quick Actions</div>
            <div class="text-xs text-gray-500 mt-1">
              {{ previewQuickActionItems().join(', ') || 'Default' }}
            </div>
            <div *ngIf="previewQuickActionError()" class="text-xs text-red-600 mt-2">
              {{ previewQuickActionError() }}
            </div>
          </div>
          <div class="p-3 bg-white border rounded">
            <div class="font-semibold">Dispatch Action Policy</div>
            <div class="text-xs text-gray-500 mt-1">
              Require driver initiated:
              <span class="font-mono">{{ previewRequireDriverInitiated() }}</span>
            </div>
            <div class="text-xs text-gray-500 mt-1">
              Hidden statuses: {{ previewHiddenStatuses().join(', ') || '(none)' }}
            </div>
            <div class="text-xs text-gray-500 mt-1">
              Allowed statuses: {{ previewAllowedStatuses().join(', ') || '(none)' }}
            </div>
            <div *ngIf="previewDispatchPolicyError()" class="text-xs text-red-600 mt-2">
              {{ previewDispatchPolicyError() }}
            </div>
          </div>
        </div>
        <details *ngIf="previewData" class="mt-3">
          <summary class="cursor-pointer text-sm text-gray-700">Show raw preview JSON</summary>
          <pre class="mt-2 p-3 bg-white border rounded text-xs overflow-auto">{{
            previewData | json
          }}</pre>
        </details>
      </div>

      <div class="mt-8 p-4 border rounded bg-gray-50">
        <h3 class="font-semibold">Effective Config Compare</h3>
        <form
          class="grid grid-cols-1 gap-3 mt-3 md:grid-cols-4"
          [formGroup]="compareForm"
          (ngSubmit)="compareEffective()"
        >
          <div class="md:col-span-2">
            <label class="font-semibold">User A ID</label>
            <input class="w-full input" formControlName="userIdA" type="number" min="1" />
          </div>
          <div class="md:col-span-2">
            <label class="font-semibold">User B ID</label>
            <input class="w-full input" formControlName="userIdB" type="number" min="1" />
          </div>
          <div class="md:col-span-4">
            <button
              class="btn btn-secondary w-full"
              type="submit"
              [disabled]="compareLoading || compareForm.invalid"
            >
              {{ compareLoading ? 'Comparing...' : 'Compare Effective Configs' }}
            </button>
          </div>
        </form>
        <div *ngIf="compareError" class="mt-2 text-red-600">{{ compareError }}</div>
        <div *ngIf="compareResult" class="mt-3">
          <div class="text-sm text-gray-700">
            Changed: {{ compareResult.changed.length }} | Only in A:
            {{ objectSize(compareResult.onlyInA) }} | Only in B:
            {{ objectSize(compareResult.onlyInB) }}
          </div>
          <div class="flex gap-2 mt-2">
            <button type="button" class="btn btn-secondary" (click)="exportChangedCsv()">
              Export CSV
            </button>
            <button type="button" class="btn btn-outline" (click)="copyChangedKeys()">
              Copy Changed Keys
            </button>
          </div>

          <div class="grid grid-cols-1 md:grid-cols-3 gap-2 mt-3">
            <div>
              <label class="font-semibold text-xs">Key Group</label>
              <select
                class="w-full input"
                [value]="comparePrefix"
                (change)="setComparePrefix($any($event.target).value)"
              >
                <option value="all">All</option>
                <option value="screens">Screens</option>
                <option value="features">Features</option>
                <option value="policies">Policies</option>
              </select>
            </div>
            <div class="md:col-span-2">
              <label class="font-semibold text-xs">Search Key</label>
              <input
                class="w-full input"
                [value]="compareSearch"
                (input)="setCompareSearch($any($event.target).value)"
                placeholder="e.g. dashboard.visible"
              />
            </div>
          </div>

          <div class="mt-3 border rounded bg-white overflow-auto">
            <table class="w-full text-xs">
              <thead>
                <tr class="border-b bg-gray-50">
                  <th class="text-left p-2">Key</th>
                  <th class="text-left p-2">User A</th>
                  <th class="text-left p-2">User B</th>
                </tr>
              </thead>
              <tbody>
                <tr *ngFor="let row of filteredChangedRows()" class="border-b">
                  <td class="p-2 font-mono">{{ row.key }}</td>
                  <td class="p-2 font-mono">{{ stringifyValue(row.a) }}</td>
                  <td class="p-2 font-mono">{{ stringifyValue(row.b) }}</td>
                </tr>
                <tr *ngIf="filteredChangedRows().length === 0">
                  <td colspan="3" class="p-2 text-gray-500">No changed keys for current filter.</td>
                </tr>
              </tbody>
            </table>
          </div>

          <details class="mt-3">
            <summary class="cursor-pointer text-sm text-gray-700">Show raw compare JSON</summary>
            <pre class="mt-2 p-3 bg-white border rounded text-xs overflow-auto">{{
              compareResult | json
            }}</pre>
          </details>
        </div>
      </div>
    </div>
  `,
})
export class AppManagementComponent implements OnInit {
  private readonly settings = inject(SettingsService);
  private readonly fb = inject(FormBuilder);
  private readonly notification = inject(NotificationService);

  catalog: AppManagementCatalogResponse | null = null;
  uiItems: UiItem[] = [];
  groupCodes: string[] = [];
  loading = false;
  saving = false;
  loadError = '';

  previewLoading = false;
  previewError = '';
  previewData: AppBootstrapResponse | null = null;
  compareLoading = false;
  compareError = '';
  compareResult: EffectiveCompareDiff | null = null;
  comparePrefix: ComparePrefix = 'all';
  compareSearch = '';
  savingItemKeys = new Set<string>();
  auditLoadingKeys = new Set<string>();
  auditByKey: Record<string, SettingAuditRow[]> = {};
  expandedAuditKey: string | null = null;
  private readonly allowedDrawerIds = new Set([
    'home',
    'my_vehicle',
    'my_id_card',
    'notifications',
    'profile',
    'report_issue_list',
    'incident_report',
    'incident_report_list',
    'safety_history',
    'maintenance',
    'trip_report',
    'daily_summary',
    'settings',
    'help',
  ]);
  private readonly allowedBottomIds = new Set(['home', 'trips', 'report', 'profile', 'more']);
  private readonly allowedQuickActionIds = new Set([
    'my_trips',
    'incident_report',
    'report_issue',
    'documents',
    'trip_report',
    'help_center',
    'daily_summary',
    'more',
  ]);
  private readonly allowedDispatchStatuses = new Set([
    'PENDING',
    'SCHEDULED',
    'ASSIGNED',
    'DRIVER_CONFIRMED',
    'ARRIVED_LOADING',
    'IN_QUEUE',
    'LOADING',
    'LOADED',
    'AT_HUB',
    'HUB_LOADING',
    'IN_TRANSIT',
    'IN_TRANSIT_BREAKDOWN',
    'PENDING_INVESTIGATION',
    'ARRIVED_UNLOADING',
    'UNLOADING',
    'UNLOADED',
    'APPROVED',
    'SAFETY_PASSED',
    'SAFETY_FAILED',
    'DELIVERED',
    'FINANCIAL_LOCKED',
    'CLOSED',
    'COMPLETED',
    'CANCELLED',
    'REJECTED',
  ]);
  private readonly recommendedValueByKey: Record<string, string> = {
    'app.policies.nav.drawer.items':
      'home,my_vehicle,my_id_card,notifications,profile,report_issue_list,incident_report,incident_report_list,safety_history,maintenance,trip_report,daily_summary,settings,help',
    'app.policies.nav.bottom.items': 'home,trips,report,profile,more',
    'app.policies.nav.home.quick_actions':
      'my_trips,incident_report,report_issue,documents,trip_report,help_center',
    'app.policies.dispatch.actions.hidden_statuses': '',
    'app.policies.dispatch.actions.allowed_statuses': '',
    'app.policies.dispatch.actions.require_driver_initiated': 'true',
  };

  readonly scopeForm: FormGroup;
  readonly valueForm = this.fb.group({});
  readonly previewForm = this.fb.group({
    userId: [null as number | null, [Validators.required, Validators.min(1)]],
  });
  readonly compareForm = this.fb.group({
    userIdA: [null as number | null, [Validators.required, Validators.min(1)]],
    userIdB: [null as number | null, [Validators.required, Validators.min(1)]],
  });

  constructor() {
    this.scopeForm = this.fb.group({
      scope: ['GLOBAL' as AppScope, Validators.required],
      scopeRef: [''],
      reason: ['Admin app-management update', [Validators.required, Validators.minLength(3)]],
    });
  }

  ngOnInit(): void {
    this.updateScopeRefValidators();
    this.scopeForm.get('scope')?.valueChanges.subscribe(() => this.updateScopeRefValidators());
    this.loadCatalog();
  }

  get selectedScope(): AppScope {
    return (this.scopeForm.value.scope as AppScope) ?? 'GLOBAL';
  }

  getGroupItems(groupCode: string): UiItem[] {
    return this.uiItems.filter((item) => item.spec.groupCode === groupCode);
  }

  loadCatalog(): void {
    this.loading = true;
    this.loadError = '';

    this.settings.getAppManagementCatalog().subscribe({
      next: (catalog) => {
        this.catalog = catalog;
        this.initUi(catalog.items);
        this.loadScopedValues();
      },
      error: (err: unknown) => {
        const message = err instanceof Error ? err.message : 'Failed to load catalog';
        const isNotFound =
          message.toLowerCase().includes('not found') ||
          message.includes('/api/admin/app-management/catalog');
        if (isNotFound) {
          this.catalog = this.fallbackCatalog();
          this.initUi(this.catalog.items);
          this.notification.warn(
            'Using fallback app-management catalog (backend endpoint missing).',
          );
          this.loadScopedValues();
          return;
        }
        this.loading = false;
        this.loadError = message;
      },
    });
  }

  private fallbackCatalog(): AppManagementCatalogResponse {
    const item = (
      groupCode: string,
      keyCode: string,
      type: string,
      defaultValue: string,
      label: string,
      description: string,
    ): AppManagementCatalogItem => ({
      groupCode,
      keyCode,
      type,
      defaultValue,
      label,
      description,
    });

    return {
      scopes: ['GLOBAL', 'ROLE', 'USER'],
      resolutionOrder: 'USER > ROLE/SEGMENT > GLOBAL > DEF_DEFAULT',
      items: [
        item(
          'app.screens',
          'dashboard.visible',
          'BOOLEAN',
          'true',
          'Dashboard Visible',
          'Show dashboard screen',
        ),
        item(
          'app.screens',
          'trips.visible',
          'BOOLEAN',
          'true',
          'Trips Visible',
          'Show trips screen',
        ),
        item(
          'app.screens',
          'profile.visible',
          'BOOLEAN',
          'true',
          'Profile Visible',
          'Show profile screen',
        ),
        item(
          'app.screens',
          'settings.visible',
          'BOOLEAN',
          'true',
          'Settings Visible',
          'Show settings screen',
        ),
        item(
          'app.screens',
          'driver_id.visible',
          'BOOLEAN',
          'true',
          'Driver ID Visible',
          'Show driver ID screen',
        ),
        item(
          'app.features',
          'edit_profile.enabled',
          'BOOLEAN',
          'true',
          'Edit Profile',
          'Allow profile edit',
        ),
        item(
          'app.features',
          'incident_report.enabled',
          'BOOLEAN',
          'true',
          'Incident Report',
          'Allow incident report',
        ),
        item(
          'app.features',
          'notifications.enabled',
          'BOOLEAN',
          'true',
          'Notifications',
          'Enable notifications feature',
        ),
        item(
          'app.features',
          'safety_check.enabled',
          'BOOLEAN',
          'true',
          'Safety Check',
          'Enable safety check feature',
        ),
        item(
          'app.features',
          'location_tracking.enabled',
          'BOOLEAN',
          'true',
          'Location Tracking',
          'Enable location tracking feature',
        ),
        item(
          'app.policies',
          'dashboard.refresh_sec',
          'NUMBER',
          '30',
          'Dashboard Refresh (sec)',
          'Dashboard refresh interval',
        ),
        item(
          'app.policies',
          'map.default_type',
          'STRING',
          'normal',
          'Map Default Type',
          'Default map type',
        ),
        item(
          'app.policies',
          'biometric.quick_unlock_enabled',
          'BOOLEAN',
          'false',
          'Biometric Quick Unlock',
          'Enable biometric quick unlock',
        ),
        item(
          'app.policies',
          'nav.drawer.items',
          'STRING',
          'home,my_vehicle,my_id_card,notifications,profile,report_issue_list,incident_report,incident_report_list,safety_history,maintenance,trip_report,daily_summary,settings,help',
          'Drawer Nav Items',
          'Comma-separated drawer menu IDs for driver app',
        ),
        item(
          'app.policies',
          'nav.bottom.items',
          'STRING',
          'home,trips,report,profile,more',
          'Bottom Nav Items',
          'Comma-separated bottom navigation IDs for driver app',
        ),
        item(
          'app.policies',
          'nav.home.quick_actions',
          'STRING',
          'my_trips,incident_report,report_issue,documents,trip_report,help_center',
          'Home Quick Actions',
          'Comma-separated quick-action IDs shown on home screen',
        ),
        item(
          'app.policies',
          'dispatch.actions.hidden_statuses',
          'STRING',
          '',
          'Hidden Dispatch Actions',
          'Comma-separated target statuses to hide from driver action buttons',
        ),
        item(
          'app.policies',
          'dispatch.actions.allowed_statuses',
          'STRING',
          '',
          'Allowed Dispatch Actions',
          'Optional allowlist of target statuses for driver action buttons',
        ),
        item(
          'app.policies',
          'dispatch.actions.require_driver_initiated',
          'BOOLEAN',
          'true',
          'Driver-Initiated Actions Only',
          'When enabled, non-driver-initiated dispatch actions are hidden',
        ),
        item(
          'app.policies',
          'update.force_min_version',
          'STRING',
          '',
          'Force Minimum Version',
          'Minimum app version required',
        ),
      ],
    };
  }

  private initUi(items: AppManagementCatalogItem[]): void {
    this.uiItems = items.map((spec) => {
      const fullKey = `${spec.groupCode}.${spec.keyCode}`;
      const controlName = fullKey.replace(/[^a-zA-Z0-9_]/g, '_');
      const valueType = this.toValueType(spec.type);
      if (!this.valueForm.get(controlName)) {
        this.valueForm.addControl(
          controlName,
          this.fb.control(this.parseRawValue(spec.defaultValue, valueType)),
        );
      }
      return { spec, fullKey, controlName, valueType };
    });

    this.groupCodes = Array.from(new Set(this.uiItems.map((item) => item.spec.groupCode)));
  }

  private toValueType(type: string): ValueType {
    const upper = type.toUpperCase();
    if (upper === 'BOOLEAN') return 'BOOLEAN';
    if (upper === 'NUMBER' || upper === 'INTEGER' || upper === 'LONG') return 'NUMBER';
    return 'STRING';
  }

  private parseRawValue(raw: unknown, type: ValueType): unknown {
    if (type === 'BOOLEAN') {
      if (typeof raw === 'boolean') return raw;
      if (typeof raw === 'string') return raw.toLowerCase() === 'true';
      return false;
    }
    if (type === 'NUMBER') {
      const n = Number(raw);
      return Number.isFinite(n) ? n : 0;
    }
    return raw == null ? '' : String(raw);
  }

  loadScopedValues(): void {
    if (!this.catalog) return;

    const scope = this.selectedScope;
    const scopeRefRaw = String(this.scopeForm.value.scopeRef ?? '').trim();
    const scopeRef = scope === 'GLOBAL' ? undefined : scopeRefRaw || undefined;

    if (!this.validateScopeSelectionOrNotify()) {
      return;
    }

    const groups = Array.from(new Set(this.uiItems.map((item) => item.spec.groupCode)));
    this.loading = true;

    const calls = groups.map((groupCode) =>
      this.settings
        .listValues(groupCode, scope, scopeRef)
        .pipe(catchError(() => of([] as SettingReadResponse[]))),
    );

    forkJoin(calls).subscribe({
      next: (responses) => {
        const valueMap = new Map<string, unknown>();
        for (const groupValues of responses) {
          for (const v of groupValues) {
            valueMap.set(`${v.groupCode}.${v.keyCode}`, v.value);
          }
        }

        for (const item of this.uiItems) {
          const existing = valueMap.get(item.fullKey);
          const fallback = item.spec.defaultValue;
          const value = this.parseRawValue(existing ?? fallback, item.valueType);
          this.valueForm.get(item.controlName)?.setValue(value, { emitEvent: false });
        }

        this.loading = false;
      },
      error: () => {
        this.loading = false;
        this.notification.error('Failed to load scoped values');
      },
    });
  }

  private resolveScopeRefOrNotify(): string | null | undefined | false {
    const scope = this.selectedScope;
    const scopeRefRaw = String(this.scopeForm.value.scopeRef ?? '').trim();
    if (!this.validateScopeSelectionOrNotify()) return false;
    return scope === 'GLOBAL' ? null : scopeRefRaw;
  }

  private updateScopeRefValidators(): void {
    const scope = this.selectedScope;
    const scopeRefCtrl = this.scopeForm.get('scopeRef');
    if (!scopeRefCtrl) return;

    if (scope === 'GLOBAL') {
      scopeRefCtrl.setValidators([]);
      scopeRefCtrl.setValue('', { emitEvent: false });
    } else if (scope === 'USER') {
      scopeRefCtrl.setValidators([Validators.required, Validators.pattern(/^\d+$/)]);
    } else {
      scopeRefCtrl.setValidators([Validators.required, Validators.pattern(/^[A-Za-z0-9:_\-.]+$/)]);
    }

    scopeRefCtrl.updateValueAndValidity({ emitEvent: false });
  }

  private validateScopeSelectionOrNotify(): boolean {
    const scope = this.selectedScope;
    const scopeRefRaw = String(this.scopeForm.value.scopeRef ?? '').trim();

    if (scope === 'GLOBAL') return true;

    if (!scopeRefRaw) {
      this.notification.warn('Scope Ref is required for ROLE/USER scope');
      return false;
    }

    if (scope === 'USER' && !/^\d+$/.test(scopeRefRaw)) {
      this.notification.warn('USER scope requires numeric user ID in Scope Ref');
      return false;
    }

    if (scope === 'ROLE' && !/^[A-Za-z0-9:_\-.]+$/.test(scopeRefRaw)) {
      this.notification.warn('ROLE scopeRef must use letters/numbers and : _ - . only');
      return false;
    }

    return true;
  }

  private normalizeItemValue(item: UiItem): unknown {
    const raw = this.valueForm.get(item.controlName)?.value;
    if (item.valueType === 'BOOLEAN') return !!raw;
    if (item.valueType === 'NUMBER') return Number(raw);
    return raw;
  }

  saveItem(item: UiItem): void {
    if (this.scopeForm.invalid) return;
    const scopeRef = this.resolveScopeRefOrNotify();
    if (scopeRef === false) return;
    const validationError = this.validateDynamicPolicyValue(item, this.normalizeItemValue(item));
    if (validationError) {
      this.notification.error(validationError);
      return;
    }

    const req: SettingWriteRequest = {
      groupCode: item.spec.groupCode,
      keyCode: item.spec.keyCode,
      scope: this.selectedScope,
      scopeRef,
      value: this.normalizeItemValue(item),
      reason: String(this.scopeForm.value.reason ?? 'Admin app-management update'),
    };

    this.savingItemKeys.add(item.fullKey);
    this.settings.upsert(req).subscribe({
      next: () => {
        this.savingItemKeys.delete(item.fullKey);
        this.notification.success(`Saved ${item.spec.keyCode}`);
        if (this.expandedAuditKey === item.fullKey) this.loadAudit(item);
      },
      error: () => {
        this.savingItemKeys.delete(item.fullKey);
        this.notification.error(`Failed to save ${item.spec.keyCode}`);
      },
    });
  }

  toggleAudit(item: UiItem): void {
    if (this.expandedAuditKey === item.fullKey) {
      this.expandedAuditKey = null;
      return;
    }
    this.expandedAuditKey = item.fullKey;
    if (this.auditByKey[item.fullKey]?.length) return;
    this.loadAudit(item);
  }

  private loadAudit(item: UiItem): void {
    this.auditLoadingKeys.add(item.fullKey);
    const scope = this.selectedScope;
    const scopeRef = String(this.scopeForm.value.scopeRef ?? '').trim();
    this.settings
      .audit(
        item.spec.groupCode,
        item.spec.keyCode,
        0,
        10,
        scope,
        scope === 'GLOBAL' ? undefined : scopeRef || undefined,
      )
      .subscribe({
        next: (page) => {
          const rows = (page?.content ?? []) as SettingAuditRow[];
          this.auditByKey[item.fullKey] = rows;
          this.auditLoadingKeys.delete(item.fullKey);
        },
        error: () => {
          this.auditLoadingKeys.delete(item.fullKey);
          this.notification.error('Failed to load setting history');
        },
      });
  }

  objectSize(obj: Record<string, unknown>): number {
    return Object.keys(obj).length;
  }

  setComparePrefix(prefix: ComparePrefix): void {
    this.comparePrefix = prefix;
  }

  setCompareSearch(search: string): void {
    this.compareSearch = search.trim().toLowerCase();
  }

  filteredChangedRows(): Array<{ key: string; a: unknown; b: unknown }> {
    if (!this.compareResult) return [];
    const search = this.compareSearch;
    const prefix = this.comparePrefix;

    return this.compareResult.changed.filter((row) => {
      if (prefix !== 'all' && !row.key.startsWith(`${prefix}.`)) return false;
      if (!search) return true;
      return row.key.toLowerCase().includes(search);
    });
  }

  stringifyValue(value: unknown): string {
    if (typeof value === 'string') return value;
    return JSON.stringify(value);
  }

  private escapeCsv(value: string): string {
    if (value.includes('"') || value.includes(',') || value.includes('\n')) {
      return `"${value.replace(/"/g, '""')}"`;
    }
    return value;
  }

  exportChangedCsv(): void {
    const rows = this.filteredChangedRows();
    if (rows.length === 0) {
      this.notification.warn('No changed keys to export');
      return;
    }

    const header = 'key,user_a,user_b';
    const lines = rows.map(
      (r) =>
        `${this.escapeCsv(r.key)},${this.escapeCsv(this.stringifyValue(r.a))},${this.escapeCsv(this.stringifyValue(r.b))}`,
    );
    const csv = [header, ...lines].join('\n');
    const blob = new Blob([csv], { type: 'text/csv;charset=utf-8;' });
    const url = URL.createObjectURL(blob);
    const a = document.createElement('a');
    a.href = url;
    a.download = 'effective-config-diff.csv';
    a.click();
    URL.revokeObjectURL(url);
  }

  copyChangedKeys(): void {
    const rows = this.filteredChangedRows();
    if (rows.length === 0) {
      this.notification.warn('No changed keys to copy');
      return;
    }

    const text = rows.map((r) => r.key).join('\n');
    if (navigator.clipboard?.writeText) {
      navigator.clipboard
        .writeText(text)
        .then(() => this.notification.success('Changed keys copied'))
        .catch(() => this.notification.error('Failed to copy keys'));
      return;
    }

    // Fallback for restricted clipboard contexts.
    const ta = document.createElement('textarea');
    ta.value = text;
    ta.style.position = 'fixed';
    ta.style.opacity = '0';
    document.body.appendChild(ta);
    ta.select();
    try {
      document.execCommand('copy');
      this.notification.success('Changed keys copied');
    } catch {
      this.notification.error('Failed to copy keys');
    } finally {
      document.body.removeChild(ta);
    }
  }

  private flattenBootstrap(prefix: string, value: unknown, out: Record<string, unknown>): void {
    if (value == null) {
      out[prefix] = value;
      return;
    }
    if (Array.isArray(value)) {
      out[prefix] = value;
      return;
    }
    if (typeof value === 'object') {
      for (const [k, v] of Object.entries(value as Record<string, unknown>)) {
        const next = prefix ? `${prefix}.${k}` : k;
        this.flattenBootstrap(next, v, out);
      }
      return;
    }
    out[prefix] = value;
  }

  private toFlatConfig(cfg: AppBootstrapResponse): Record<string, unknown> {
    const out: Record<string, unknown> = {};
    this.flattenBootstrap('screens', cfg.screens, out);
    this.flattenBootstrap('features', cfg.features, out);
    this.flattenBootstrap('policies', cfg.policies, out);
    return out;
  }

  compareEffective(): void {
    this.compareError = '';
    this.compareResult = null;
    this.comparePrefix = 'all';
    this.compareSearch = '';
    const userIdA = this.compareForm.value.userIdA;
    const userIdB = this.compareForm.value.userIdB;
    if (!userIdA || !userIdB || userIdA < 1 || userIdB < 1) return;

    this.compareLoading = true;
    forkJoin([
      this.settings.getAppManagementEffective(userIdA),
      this.settings.getAppManagementEffective(userIdB),
    ]).subscribe({
      next: ([a, b]) => {
        const flatA = this.toFlatConfig(a);
        const flatB = this.toFlatConfig(b);

        const onlyInA: Record<string, unknown> = {};
        const onlyInB: Record<string, unknown> = {};
        const changed: Array<{ key: string; a: unknown; b: unknown }> = [];

        for (const [k, av] of Object.entries(flatA)) {
          if (!(k in flatB)) {
            onlyInA[k] = av;
            continue;
          }
          const bv = flatB[k];
          if (JSON.stringify(av) !== JSON.stringify(bv)) {
            changed.push({ key: k, a: av, b: bv });
          }
        }
        for (const [k, bv] of Object.entries(flatB)) {
          if (!(k in flatA)) onlyInB[k] = bv;
        }

        this.compareResult = { onlyInA, onlyInB, changed };
        this.compareLoading = false;
      },
      error: (err: unknown) => {
        this.compareLoading = false;
        this.compareError = err instanceof Error ? err.message : 'Compare failed';
      },
    });
  }

  async save(): Promise<void> {
    if (!this.catalog || this.scopeForm.invalid) return;

    const scope = this.selectedScope;
    const scopeRef = this.resolveScopeRefOrNotify();
    const reason = String(this.scopeForm.value.reason ?? '').trim();
    if (scopeRef === false) {
      return;
    }

    this.saving = true;
    try {
      const invalid = this.uiItems
        .map((item) => ({
          item,
          error: this.validateDynamicPolicyValue(item, this.normalizeItemValue(item)),
        }))
        .find((entry) => !!entry.error);
      if (invalid?.error) {
        this.notification.error(invalid.error);
        this.saving = false;
        return;
      }

      const writes: SettingWriteRequest[] = this.uiItems.map((item) => {
        return {
          groupCode: item.spec.groupCode,
          keyCode: item.spec.keyCode,
          scope,
          scopeRef,
          value: this.normalizeItemValue(item),
          reason,
        };
      });

      await Promise.all(writes.map((w) => firstValueFrom(this.settings.upsert(w))));
      this.notification.success('App management settings saved');
      this.loadScopedValues();
    } catch {
      this.notification.error('Failed to save app management settings');
    } finally {
      this.saving = false;
    }
  }

  preview(): void {
    this.previewError = '';
    this.previewData = null;
    const userId = this.previewForm.value.userId;
    if (!userId || userId < 1) return;

    this.previewLoading = true;
    this.settings.getAppManagementEffective(userId).subscribe({
      next: (res) => {
        this.previewData = res;
        this.previewLoading = false;
      },
      error: (err: unknown) => {
        this.previewLoading = false;
        this.previewError = err instanceof Error ? err.message : 'Preview failed';
      },
    });
  }

  previewDrawerItems(): string[] {
    return this.previewListPolicy('nav.drawer.items');
  }

  previewBottomItems(): string[] {
    return this.previewListPolicy('nav.bottom.items');
  }

  previewQuickActionItems(): string[] {
    return this.previewListPolicy('nav.home.quick_actions');
  }

  previewHiddenStatuses(): string[] {
    return this.previewListPolicy('dispatch.actions.hidden_statuses').map((v) => v.toUpperCase());
  }

  previewAllowedStatuses(): string[] {
    return this.previewListPolicy('dispatch.actions.allowed_statuses').map((v) => v.toUpperCase());
  }

  previewRequireDriverInitiated(): string {
    const raw = this.previewPolicy('dispatch.actions.require_driver_initiated');
    if (typeof raw === 'boolean') return String(raw);
    const text = String(raw ?? '')
      .trim()
      .toLowerCase();
    return text || '(default: true)';
  }

  previewDrawerError(): string | null {
    return this.validateDynamicPolicyByFullKey(
      'app.policies.nav.drawer.items',
      this.previewDrawerItems().join(','),
    );
  }

  previewBottomError(): string | null {
    return this.validateDynamicPolicyByFullKey(
      'app.policies.nav.bottom.items',
      this.previewBottomItems().join(','),
    );
  }

  previewQuickActionError(): string | null {
    return this.validateDynamicPolicyByFullKey(
      'app.policies.nav.home.quick_actions',
      this.previewQuickActionItems().join(','),
    );
  }

  previewDispatchPolicyError(): string | null {
    const hiddenErr = this.validateDynamicPolicyByFullKey(
      'app.policies.dispatch.actions.hidden_statuses',
      this.previewHiddenStatuses().join(','),
    );
    if (hiddenErr) return hiddenErr;
    const allowedErr = this.validateDynamicPolicyByFullKey(
      'app.policies.dispatch.actions.allowed_statuses',
      this.previewAllowedStatuses().join(','),
    );
    if (allowedErr) return allowedErr;
    return this.validateDynamicPolicyByFullKey(
      'app.policies.dispatch.actions.require_driver_initiated',
      this.previewRequireDriverInitiated(),
    );
  }

  private previewPolicy(key: string): unknown {
    return this.previewData?.policies?.[key];
  }

  private previewListPolicy(key: string): string[] {
    const raw = this.previewPolicy(key);
    if (Array.isArray(raw)) {
      return raw.map((v) => String(v).trim()).filter((v) => !!v);
    }
    const text = String(raw ?? '').trim();
    if (!text) return [];
    return text
      .split(',')
      .map((v) => v.trim())
      .filter((v) => !!v);
  }

  isDynamicKey(fullKey: string): boolean {
    return fullKey in this.recommendedValueByKey;
  }

  allowedValuesFor(fullKey: string): string[] {
    if (fullKey === 'app.policies.nav.drawer.items') {
      return Array.from(this.allowedDrawerIds);
    }
    if (fullKey === 'app.policies.nav.bottom.items') {
      return Array.from(this.allowedBottomIds);
    }
    if (fullKey === 'app.policies.nav.home.quick_actions') {
      return Array.from(this.allowedQuickActionIds);
    }
    if (
      fullKey === 'app.policies.dispatch.actions.hidden_statuses' ||
      fullKey === 'app.policies.dispatch.actions.allowed_statuses'
    ) {
      return Array.from(this.allowedDispatchStatuses);
    }
    if (fullKey === 'app.policies.dispatch.actions.require_driver_initiated') {
      return ['true', 'false'];
    }
    return [];
  }

  applyRecommended(item: UiItem): void {
    const value = this.recommendedValueByKey[item.fullKey];
    if (value == null) return;
    const control = this.valueForm.get(item.controlName);
    if (!control) return;
    if (item.valueType === 'BOOLEAN') {
      control.setValue(String(value).toLowerCase() === 'true');
      return;
    }
    control.setValue(value);
  }

  private validateDynamicPolicyValue(item: UiItem, rawValue: unknown): string | null {
    return this.validateDynamicPolicyByFullKey(item.fullKey, rawValue);
  }

  private validateDynamicPolicyByFullKey(fullKey: string, rawValue: unknown): string | null {
    const asList = (value: unknown): string[] => {
      if (Array.isArray(value)) {
        return value.map((v) => String(v).trim()).filter((v) => !!v);
      }
      const text = String(value ?? '').trim();
      if (!text) return [];
      return text
        .split(',')
        .map((v) => v.trim())
        .filter((v) => !!v);
    };
    const duplicates = (list: string[]): string[] => {
      const seen = new Set<string>();
      const out = new Set<string>();
      for (const value of list) {
        if (seen.has(value)) out.add(value);
        seen.add(value);
      }
      return Array.from(out);
    };
    const invalidValues = (list: string[], allowed: Set<string>): string[] =>
      list.filter((v) => !allowed.has(v));

    if (fullKey === 'app.policies.nav.drawer.items') {
      const list = asList(rawValue);
      const dups = duplicates(list);
      if (dups.length) return `Duplicate drawer item(s): ${dups.join(', ')}`;
      const invalid = invalidValues(list, this.allowedDrawerIds);
      if (invalid.length) return `Invalid drawer item(s): ${invalid.join(', ')}`;
      return null;
    }

    if (fullKey === 'app.policies.nav.bottom.items') {
      const list = asList(rawValue);
      const dups = duplicates(list);
      if (dups.length) return `Duplicate bottom nav item(s): ${dups.join(', ')}`;
      const invalid = invalidValues(list, this.allowedBottomIds);
      if (invalid.length) return `Invalid bottom nav item(s): ${invalid.join(', ')}`;
      if (list.length && !list.includes('home')) return `Bottom nav must include "home"`;
      if (list.length && list[0] !== 'home') return `Bottom nav should start with "home"`;
      return null;
    }

    if (fullKey === 'app.policies.nav.home.quick_actions') {
      const list = asList(rawValue);
      const dups = duplicates(list);
      if (dups.length) return `Duplicate quick action(s): ${dups.join(', ')}`;
      const invalid = invalidValues(list, this.allowedQuickActionIds);
      if (invalid.length) return `Invalid quick action(s): ${invalid.join(', ')}`;
      return null;
    }

    if (
      fullKey === 'app.policies.dispatch.actions.hidden_statuses' ||
      fullKey === 'app.policies.dispatch.actions.allowed_statuses'
    ) {
      const list = asList(rawValue).map((v) => v.toUpperCase());
      const dups = duplicates(list);
      if (dups.length) return `Duplicate dispatch status(es): ${dups.join(', ')}`;
      const invalid = invalidValues(list, this.allowedDispatchStatuses);
      if (invalid.length) return `Invalid dispatch status(es): ${invalid.join(', ')}`;
      return null;
    }

    if (fullKey === 'app.policies.dispatch.actions.require_driver_initiated') {
      const text = String(rawValue ?? '')
        .trim()
        .toLowerCase();
      if (text === 'true' || text === 'false') return null;
      if (typeof rawValue === 'boolean') return null;
      return 'dispatch.actions.require_driver_initiated must be true or false';
    }

    return null;
  }
}
