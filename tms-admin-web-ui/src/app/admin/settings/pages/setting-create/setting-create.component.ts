/* eslint-disable @typescript-eslint/consistent-type-imports */
import { CommonModule } from '@angular/common';
import { Component, inject } from '@angular/core';
import { FormGroup } from '@angular/forms';
import { Validators, ReactiveFormsModule, FormBuilder } from '@angular/forms';

import { SettingsService, type SettingWriteRequest } from '../../../../services/settings.service';
import { NotificationService } from '../../../../services/notification.service';

@Component({
  selector: 'app-setting-create',
  standalone: true,
  imports: [CommonModule, ReactiveFormsModule],
  templateUrl: './setting-create.component.html',
})
export class SettingCreateComponent {
  private notification = inject(NotificationService);
  form: FormGroup;
  saving = false;
  lastSaved?: any;

  constructor(
    private fb: FormBuilder,
    private settings: SettingsService,
  ) {
    this.form = this.fb.group({
      groupCode: ['system.core', [Validators.required]],
      keyCode: ['appName', [Validators.required]],
      scope: ['GLOBAL', [Validators.required]],
      scopeRef: [''],
      value: ['', [Validators.required]],
      typeHint: ['STRING'], // UI-only
      reason: ['Admin create/update', [Validators.required, Validators.minLength(3)]],
    });
  }

  isScoped(): boolean {
    const s = this.form.get('scope')?.value;
    return s === 'TENANT' || s === 'SITE' || s === 'ROLE' || s === 'USER';
  }

  submit() {
    if (this.form.invalid) return;
    this.saving = true;

    const raw = this.form.value;
    let parsed: any = raw.value;
    switch (raw.typeHint) {
      case 'NUMBER':
        parsed = Number(parsed);
        break;
      case 'BOOLEAN':
        parsed = ('' + parsed).toLowerCase() === 'true';
        break;
      case 'JSON':
        try {
          parsed = JSON.parse(parsed);
        } catch {
          this.notification.simulateNotification('Error', 'Invalid JSON');
          this.saving = false;
          return;
        }
        break;
      default:
        break; // STRING/PASSWORD/URL/EMAIL/LIST/MAP: pass-through
    }

    const req: SettingWriteRequest = {
      groupCode: raw.groupCode,
      keyCode: raw.keyCode,
      scope: raw.scope,
      scopeRef: this.isScoped() ? raw.scopeRef || null : null,
      value: parsed,
      reason: raw.reason,
    };

    this.settings.upsert(req).subscribe({
      next: (res) => {
        this.lastSaved = res;
        this.saving = false;
      },
      error: () => {
        this.saving = false;
      },
    });
  }
}
