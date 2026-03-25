import { CommonModule } from '@angular/common';
import { Component, Inject, signal } from '@angular/core';
import { MatButtonModule } from '@angular/material/button';
import { MAT_DIALOG_DATA, MatDialogModule, MatDialogRef } from '@angular/material/dialog';
import { MatFormFieldModule } from '@angular/material/form-field';
import { MatIconModule } from '@angular/material/icon';
import { MatProgressBarModule } from '@angular/material/progress-bar';
import { MatSelectModule } from '@angular/material/select';

import type { GeofenceCreateRequest } from '../../models/geofence.model';
import { GeofenceImportExportService } from '../geofence-import-export.service';

@Component({
  selector: 'app-geofence-import-dialog',
  standalone: true,
  imports: [
    CommonModule,
    MatDialogModule,
    MatFormFieldModule,
    MatSelectModule,
    MatButtonModule,
    MatProgressBarModule,
    MatIconModule,
  ],
  template: `
    <h2 mat-dialog-title>Import Geofences</h2>

    <mat-dialog-content>
      <div *ngIf="!selectedFile()" class="import-form">
        <p class="instruction">Select a CSV or GeoJSON file to import geofences</p>

        <div class="file-input-wrapper">
          <input
            type="file"
            #fileInput
            (change)="onFileSelected($event)"
            accept=".csv,.geojson,.json"
            class="file-input"
          />
          <button mat-raised-button (click)="fileInput.click()" color="primary">
            <mat-icon>upload_file</mat-icon>
            Choose File
          </button>
        </div>

        <div class="supported-formats">
          <h4>Supported Formats:</h4>
          <ul>
            <li>
              <strong>CSV</strong> - Spreadsheet format with columns: Name, Type, Alert Type, etc.
            </li>
            <li><strong>GeoJSON</strong> - Geographic data format with Feature collections</li>
          </ul>
        </div>
      </div>

      <div *ngIf="selectedFile() && !previewLoaded()" class="loading-state">
        <mat-progress-bar mode="indeterminate"></mat-progress-bar>
        <p>Parsing file...</p>
      </div>

      <div *ngIf="previewLoaded()" class="preview-section">
        <h3>Preview: {{ previewGeofences().length }} geofences ready to import</h3>

        <div *ngIf="importError()" class="error-message">
          <mat-icon>error</mat-icon>
          <span>{{ importError() }}</span>
        </div>

        <div class="preview-table">
          <table>
            <thead>
              <tr>
                <th>Name</th>
                <th>Type</th>
                <th>Alert Type</th>
                <th>Active</th>
              </tr>
            </thead>
            <tbody>
              <tr *ngFor="let geo of previewGeofences().slice(0, 5)">
                <td>{{ geo.name }}</td>
                <td>{{ geo.type }}</td>
                <td>{{ geo.alertType }}</td>
                <td>{{ geo.active ? 'Yes' : 'No' }}</td>
              </tr>
              <tr *ngIf="previewGeofences().length > 5">
                <td colspan="4" class="more">... and {{ previewGeofences().length - 5 }} more</td>
              </tr>
            </tbody>
          </table>
        </div>
      </div>
    </mat-dialog-content>

    <mat-dialog-actions>
      <button mat-button (click)="dialog.close()">Cancel</button>
      <button
        *ngIf="!previewLoaded()"
        mat-raised-button
        [disabled]="!selectedFile()"
        color="accent"
        (click)="parseFile()"
      >
        Preview
      </button>
      <button
        *ngIf="previewLoaded() && !importError()"
        mat-raised-button
        color="primary"
        (click)="confirmImport()"
      >
        <mat-icon>check_circle</mat-icon>
        Import {{ previewGeofences().length }} Geofences
      </button>
      <button *ngIf="previewLoaded()" mat-stroked-button (click)="resetImport()">
        Choose Different File
      </button>
    </mat-dialog-actions>
  `,
  styles: [
    `
      mat-dialog-content {
        padding: 24px;
        min-width: 500px;
      }

      .import-form {
        display: flex;
        flex-direction: column;
        gap: 20px;
      }

      .instruction {
        color: #6b7280;
        margin: 0;
        font-size: 14px;
      }

      .file-input-wrapper {
        display: flex;
        gap: 12px;
      }

      .file-input {
        display: none;
      }

      .supported-formats {
        padding: 16px;
        background-color: #f0f9ff;
        border-radius: 8px;
        border-left: 4px solid #3b82f6;
      }

      .supported-formats h4 {
        margin: 0 0 8px;
        color: #1e40af;
        font-size: 13px;
      }

      .supported-formats ul {
        margin: 0;
        padding-left: 20px;
        font-size: 13px;
        color: #4b5563;
      }

      .loading-state {
        display: flex;
        flex-direction: column;
        gap: 16px;
        padding: 20px;
        text-align: center;
        color: #6b7280;
      }

      .preview-section {
        display: flex;
        flex-direction: column;
        gap: 16px;
      }

      .preview-section h3 {
        margin: 0;
        font-size: 14px;
        color: #111827;
      }

      .error-message {
        display: flex;
        align-items: center;
        gap: 8px;
        padding: 12px 16px;
        background-color: #fee2e2;
        border: 1px solid #fecaca;
        border-radius: 6px;
        color: #dc2626;
        font-size: 13px;
      }

      .error-message mat-icon {
        font-size: 18px;
      }

      .preview-table {
        overflow-x: auto;
        border: 1px solid #e5e7eb;
        border-radius: 6px;
      }

      table {
        width: 100%;
        border-collapse: collapse;
        font-size: 12px;
      }

      thead {
        background-color: #f9fafb;
      }

      th {
        padding: 12px;
        text-align: left;
        font-weight: 600;
        color: #6b7280;
        border-bottom: 1px solid #e5e7eb;
      }

      td {
        padding: 12px;
        border-bottom: 1px solid #f3f4f6;
      }

      td.more {
        text-align: center;
        color: #9ca3af;
        font-style: italic;
      }

      mat-dialog-actions {
        display: flex;
        justify-content: flex-end;
        gap: 8px;
        padding: 16px 24px;
        border-top: 1px solid #e5e7eb;
      }
    `,
  ],
})
export class GeofenceImportDialogComponent {
  selectedFile = signal<File | null>(null);
  previewGeofences = signal<GeofenceCreateRequest[]>([]);
  previewLoaded = signal(false);
  importError = signal<string | null>(null);

  constructor(
    public dialog: MatDialogRef<GeofenceImportDialogComponent>,
    @Inject(MAT_DIALOG_DATA) public data: { companyId: number },
    private importExportService: GeofenceImportExportService,
  ) {}

  onFileSelected(event: Event): void {
    const target = event.target as HTMLInputElement;
    const files = target.files;

    if (files && files.length > 0) {
      this.selectedFile.set(files[0]);
      this.previewLoaded.set(false);
      this.importError.set(null);
    }
  }

  parseFile(): void {
    const file = this.selectedFile();
    if (!file) return;

    const isCSV = file.name.endsWith('.csv');
    const isGeoJSON = file.name.endsWith('.geojson') || file.name.endsWith('.json');

    let parsePromise: Promise<GeofenceCreateRequest[]>;

    if (isCSV) {
      parsePromise = this.importExportService.importFromCSV(file);
    } else if (isGeoJSON) {
      parsePromise = this.importExportService.importFromGeoJSON(file, this.data.companyId);
    } else {
      this.importError.set('Unsupported file format. Please use CSV or GeoJSON.');
      return;
    }

    parsePromise
      .then((geofences) => {
        if (geofences.length === 0) {
          this.importError.set('No valid geofences found in file.');
          return;
        }

        this.previewGeofences.set(geofences);
        this.previewLoaded.set(true);
        this.importError.set(null);
      })
      .catch((error) => {
        this.importError.set(error instanceof Error ? error.message : 'Failed to parse file');
        this.previewLoaded.set(true);
      });
  }

  confirmImport(): void {
    this.dialog.close(this.previewGeofences());
  }

  resetImport(): void {
    this.selectedFile.set(null);
    this.previewGeofences.set([]);
    this.previewLoaded.set(false);
    this.importError.set(null);
  }
}
