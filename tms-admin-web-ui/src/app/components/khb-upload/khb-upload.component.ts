/* eslint-disable @typescript-eslint/consistent-type-imports */
import { CommonModule } from '@angular/common';
import { Component, inject } from '@angular/core';
import { FormsModule } from '@angular/forms';
import { RouterModule } from '@angular/router';

import { KhbSoUploadService } from '../../services/khb-so-upload.service';
import { NotificationService } from '../../services/notification.service';

interface KhbUploadRow {
  [key: string]: string | number | undefined; //  Add this line to allow dynamic access

  docNo: string;
  soldToParty: string;
  name1: string;
  transportVendorName: string;
  shipToParty: string;
  shipToPartyName: string;
  docDate: string;
  purchasingDoc: string;
  description: string;
  qty: number;
  plant: string;
  remark?: string;
  qtyPerPallet?: number;
  pallet?: number;
  distributorCode: string;
}

@Component({
  selector: 'app-khb-so-upload',
  standalone: true,
  imports: [CommonModule, FormsModule, RouterModule],
  templateUrl: './khb-upload.component.html',
})
export class KhbSoUploadComponent {
  private notification = inject(NotificationService);
  selectedFile: File | null = null;
  previewData: {
    valid: KhbUploadRow[];
    errors: { row: number; reason: string }[];
    totalRows: number;
    skipped: number;
  } | null = null;

  errorMsg = '';
  isLoading = false;
  objectKeys = Object.keys;

  constructor(private khbService: KhbSoUploadService) {}

  get hasValidRows(): boolean {
    return !!this.previewData?.valid?.length;
  }

  get hasErrorRows(): boolean {
    return !!this.previewData?.errors?.length;
  }

  onFileSelected(event: Event): void {
    const input = event.target as HTMLInputElement;
    if (input.files?.length) {
      this.selectedFile = input.files[0];
    }
  }

  onPreview(): void {
    if (!this.selectedFile) {
      this.errorMsg = 'Please select a file.';
      return;
    }

    this.isLoading = true;
    this.khbService.previewUpload(this.selectedFile).subscribe({
      next: (res) => {
        this.previewData = res;
        this.errorMsg = '';
        this.isLoading = false;
        console.log(' Preview Data:', this.previewData);
      },
      error: (err) => {
        this.errorMsg = err.message || 'Failed to preview file.';
        this.previewData = null;
        this.isLoading = false;
      },
    });
  }
  onCommit(): void {
    if (!this.hasValidRows) {
      this.errorMsg = 'No valid data to commit.';
      return;
    }

    const payload = { rows: this.previewData!.valid };
    console.log('🚀 Committing Payload:', payload);

    this.khbService.commitUpload(payload).subscribe({
      next: (res) => {
        this.notification.simulateNotification('Success', 'Upload committed successfully');
        console.log(' Server Response:', res);
        this.previewData = null;
        this.selectedFile = null;
        this.errorMsg = '';
      },
      error: (err) => {
        console.error(' Commit Failed:', err);
        this.errorMsg = err.message || 'Failed to commit data.';
      },
    });
  }
}
