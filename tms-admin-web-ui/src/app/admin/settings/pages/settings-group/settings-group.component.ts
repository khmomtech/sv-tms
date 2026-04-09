/* eslint-disable @typescript-eslint/consistent-type-imports */
import { CommonModule } from '@angular/common';
import { Component, inject, OnInit } from '@angular/core';
import { FormGroup } from '@angular/forms';
import { ReactiveFormsModule, FormBuilder } from '@angular/forms';
import { ActivatedRoute } from '@angular/router';

import {
  SettingsService,
  type SettingReadResponse,
  type SettingWriteRequest,
} from '../../../../services/settings.service';
import { firstValueFrom } from 'rxjs';
import { NotificationService } from '../../../../services/notification.service';

@Component({
  selector: 'app-settings-group',
  standalone: true,
  imports: [CommonModule, ReactiveFormsModule],
  template: `
    <div class="p-6 bg-white rounded">
      <h2 class="mb-4 text-xl font-bold">Settings: {{ groupCode }}</h2>

      <form *ngIf="form" [formGroup]="form" (ngSubmit)="save()">
        <div class="grid gap-3">
          <div
            *ngFor="let v of values"
            class="grid grid-cols-1 md:grid-cols-2 gap-2 p-3 border rounded"
          >
            <div>
              <label class="font-semibold">{{ v.keyCode }}</label>
              <div class="text-xs text-gray-500">{{ v.type }}</div>
            </div>
            <div>
              <ng-container [ngSwitch]="v.type">
                <input
                  *ngSwitchCase="'NUMBER'"
                  type="number"
                  class="w-full input"
                  [formControlName]="v.keyCode"
                />
                <input
                  *ngSwitchCase="'BOOLEAN'"
                  type="checkbox"
                  class="mr-2"
                  [formControlName]="v.keyCode"
                />
                <textarea
                  *ngSwitchCase="'JSON'"
                  rows="4"
                  class="w-full input"
                  [formControlName]="v.keyCode"
                ></textarea>
                <input *ngSwitchDefault class="w-full input" [formControlName]="v.keyCode" />
              </ng-container>
            </div>
          </div>
        </div>

        <div class="flex justify-end gap-3 mt-4">
          <button type="submit" class="btn btn-primary">Save</button>
        </div>
      </form>

      <div *ngIf="!values?.length" class="text-gray-500">No settings found for group.</div>
    </div>
  `,
})
export class SettingsGroupComponent implements OnInit {
  private notification = inject(NotificationService);
  groupCode!: string;
  scope: 'GLOBAL' | 'TENANT' | 'SITE' = 'GLOBAL';
  scopeRef: string | null = null;

  values: SettingReadResponse[] = [];
  form!: FormGroup;

  constructor(
    private route: ActivatedRoute,
    private fb: FormBuilder,
    private api: SettingsService,
  ) {}

  ngOnInit(): void {
    this.route.paramMap.subscribe((p) => {
      this.groupCode = p.get('groupCode') ?? 'system.core';
      this.load();
    });
  }

  private buildForm() {
    const group: Record<string, any> = {};
    for (const v of this.values) {
      // keep raw value; if BOOLEAN in backend, Angular checkbox expects boolean
      group[v.keyCode] =
        v.type === 'BOOLEAN'
          ? !!v.value
          : v.type === 'JSON' && typeof v.value !== 'string'
            ? JSON.stringify(v.value)
            : v.value;
    }
    this.form = this.fb.group(group);
  }

  load() {
    this.api
      .listValues(this.groupCode, this.scope, this.scopeRef ?? undefined)
      .subscribe((vals) => {
        this.values = vals;
        this.buildForm();
      });
  }

  save() {
    const writes: SettingWriteRequest[] = this.values
      .map((v) => {
        let raw = this.form.value[v.keyCode];
        switch (v.type) {
          case 'NUMBER':
            raw = Number(raw);
            break;
          case 'BOOLEAN':
            raw = !!raw;
            break;
          case 'JSON':
            try {
              raw = typeof raw === 'string' ? JSON.parse(raw) : raw;
            } catch {
              this.notification.simulateNotification('Error', `Invalid JSON for ${v.keyCode}`);
              return;
            }
            break;
          default:
            /* leave as-is */ break;
        }
        return {
          groupCode: this.groupCode,
          keyCode: v.keyCode,
          scope: this.scope,
          scopeRef: this.scopeRef ?? null,
          value: raw,
          reason: 'Admin bulk save',
        } as SettingWriteRequest;
      })
      .filter(Boolean) as SettingWriteRequest[];

    // Simple bulk via sequential upserts
    Promise.all(writes.map((w) => firstValueFrom(this.api.upsert(w)))).then(() => this.load());
  }
}
