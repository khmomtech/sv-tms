import { CommonModule } from '@angular/common';
import { Component, Inject } from '@angular/core';
import { MatButtonModule } from '@angular/material/button';
import { MAT_DIALOG_DATA, MatDialogModule, MatDialogRef } from '@angular/material/dialog';
import { MatIconModule } from '@angular/material/icon';

export interface ConflictData {
  resourceName: string;
  currentVersion: any;
  serverVersion: any;
  localChanges: any;
  conflictFields: string[];
}

export interface ConflictResolution {
  action: 'use-local' | 'use-server' | 'merge';
  mergedData?: any;
}

/**
 * Conflict Resolution Dialog Component
 *
 * Displays when optimistic locking detects a version conflict.
 * Allows users to:
 * - Use their local changes (overwrite server)
 * - Use server version (discard local changes)
 * - Manually merge changes field-by-field
 *
 * @example
 * ```typescript
 * const dialogRef = this.dialog.open(ConflictResolutionComponent, {
 *   data: {
 *     resourceName: 'Vehicle #123',
 *     currentVersion: localVehicle,
 *     serverVersion: serverVehicle,
 *     localChanges: changes,
 *     conflictFields: ['status', 'location']
 *   }
 * });
 *
 * dialogRef.afterClosed().subscribe(result => {
 *   if (result?.action === 'use-local') {
 *     // Force update with local changes
 *   }
 * });
 * ```
 */
@Component({
  selector: 'app-conflict-resolution',
  standalone: true,
  imports: [CommonModule, MatDialogModule, MatButtonModule, MatIconModule],
  template: `
    <div class="conflict-dialog">
      <h2 mat-dialog-title class="flex items-center gap-2">
        <mat-icon class="text-amber-500">warning</mat-icon>
        <span>Conflict Detected: {{ data.resourceName }}</span>
      </h2>

      <mat-dialog-content class="max-h-96 overflow-y-auto">
        <div class="mb-4 p-4 bg-amber-50 border border-amber-200 rounded-lg">
          <p class="text-sm text-amber-800">
            <mat-icon class="text-base align-middle mr-1">info</mat-icon>
            Someone else modified this {{ data.resourceName }} while you were editing. Please choose
            how to resolve the conflict.
          </p>
        </div>

        <div class="space-y-4">
          <div>
            <h3 class="text-sm font-semibold text-gray-700 mb-2">Conflicting Fields:</h3>
            <div class="flex flex-wrap gap-2">
              <span
                *ngFor="let field of data.conflictFields"
                class="px-2 py-1 bg-red-100 text-red-800 text-xs rounded"
              >
                {{ field }}
              </span>
            </div>
          </div>

          <!-- Comparison Table -->
          <div class="border rounded-lg overflow-hidden">
            <table class="min-w-full divide-y divide-gray-200">
              <thead class="bg-gray-50">
                <tr>
                  <th class="px-4 py-3 text-left text-xs font-medium text-gray-500 uppercase">
                    Field
                  </th>
                  <th class="px-4 py-3 text-left text-xs font-medium text-gray-500 uppercase">
                    Your Changes
                  </th>
                  <th class="px-4 py-3 text-left text-xs font-medium text-gray-500 uppercase">
                    Server Version
                  </th>
                  <th
                    *ngIf="mergeMode"
                    class="px-4 py-3 text-left text-xs font-medium text-gray-500 uppercase"
                  >
                    Use
                  </th>
                </tr>
              </thead>
              <tbody class="bg-white divide-y divide-gray-200">
                <tr *ngFor="let field of data.conflictFields" class="hover:bg-gray-50">
                  <td class="px-4 py-3 text-sm font-medium text-gray-900">
                    {{ field }}
                  </td>
                  <td class="px-4 py-3 text-sm text-blue-600">
                    {{ formatValue(data.localChanges[field]) }}
                  </td>
                  <td class="px-4 py-3 text-sm text-green-600">
                    {{ formatValue(data.serverVersion[field]) }}
                  </td>
                  <td *ngIf="mergeMode" class="px-4 py-3 text-sm">
                    <div class="flex gap-2">
                      <button
                        (click)="selectField(field, 'local')"
                        [class.bg-blue-100]="mergeSelection[field] === 'local'"
                        class="px-2 py-1 border rounded hover:bg-blue-50"
                        type="button"
                      >
                        Mine
                      </button>
                      <button
                        (click)="selectField(field, 'server')"
                        [class.bg-green-100]="mergeSelection[field] === 'server'"
                        class="px-2 py-1 border rounded hover:bg-green-50"
                        type="button"
                      >
                        Theirs
                      </button>
                    </div>
                  </td>
                </tr>
              </tbody>
            </table>
          </div>

          <!-- Merge Preview (if in merge mode) -->
          <div *ngIf="mergeMode" class="p-4 bg-gray-50 border rounded-lg">
            <h4 class="text-sm font-semibold text-gray-700 mb-2">Merged Result Preview:</h4>
            <pre class="text-xs bg-white p-3 rounded border overflow-x-auto">{{
              getMergedData() | json
            }}</pre>
          </div>
        </div>
      </mat-dialog-content>

      <mat-dialog-actions class="flex gap-2 p-4 border-t">
        <button
          mat-raised-button
          color="primary"
          (click)="useLocal()"
          [disabled]="mergeMode"
          type="button"
        >
          <mat-icon>upload</mat-icon>
          Use My Changes
        </button>

        <button
          mat-raised-button
          color="accent"
          (click)="useServer()"
          [disabled]="mergeMode"
          type="button"
        >
          <mat-icon>download</mat-icon>
          Use Server Version
        </button>

        <button
          mat-raised-button
          [color]="mergeMode ? 'primary' : 'warn'"
          (click)="toggleMerge()"
          type="button"
        >
          <mat-icon>{{ mergeMode ? 'check' : 'merge' }}</mat-icon>
          {{ mergeMode ? 'Apply Merge' : 'Manual Merge' }}
        </button>

        <button mat-button (click)="cancel()" type="button">Cancel</button>
      </mat-dialog-actions>
    </div>
  `,
  styles: [
    `
      .conflict-dialog {
        min-width: 600px;
        max-width: 800px;
      }

      mat-dialog-content {
        padding: 20px;
      }

      ::ng-deep .mat-mdc-dialog-actions {
        justify-content: flex-start !important;
        padding: 16px !important;
      }
    `,
  ],
})
export class ConflictResolutionComponent {
  mergeMode = false;
  mergeSelection: Record<string, 'local' | 'server'> = {};

  constructor(
    public dialogRef: MatDialogRef<ConflictResolutionComponent>,
    @Inject(MAT_DIALOG_DATA) public data: ConflictData,
  ) {
    // Initialize merge selection with local values by default
    this.data.conflictFields.forEach((field) => {
      this.mergeSelection[field] = 'local';
    });
  }

  useLocal(): void {
    this.dialogRef.close({
      action: 'use-local',
      mergedData: this.data.localChanges,
    } as ConflictResolution);
  }

  useServer(): void {
    this.dialogRef.close({
      action: 'use-server',
      mergedData: this.data.serverVersion,
    } as ConflictResolution);
  }

  toggleMerge(): void {
    if (this.mergeMode) {
      // Apply merge
      this.dialogRef.close({
        action: 'merge',
        mergedData: this.getMergedData(),
      } as ConflictResolution);
    } else {
      // Enter merge mode
      this.mergeMode = true;
    }
  }

  selectField(field: string, source: 'local' | 'server'): void {
    this.mergeSelection[field] = source;
  }

  getMergedData(): any {
    const merged = { ...this.data.currentVersion };

    this.data.conflictFields.forEach((field) => {
      if (this.mergeSelection[field] === 'local') {
        merged[field] = this.data.localChanges[field];
      } else {
        merged[field] = this.data.serverVersion[field];
      }
    });

    return merged;
  }

  cancel(): void {
    this.dialogRef.close(null);
  }

  formatValue(value: any): string {
    if (value === null || value === undefined) {
      return '(empty)';
    }
    if (typeof value === 'object') {
      return JSON.stringify(value);
    }
    return String(value);
  }
}
