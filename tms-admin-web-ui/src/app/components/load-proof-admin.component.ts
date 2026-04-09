import { CommonModule } from '@angular/common';
// eslint-disable-next-line @typescript-eslint/consistent-type-imports
import { HttpClient, HttpHeaders } from '@angular/common/http';
import { Component } from '@angular/core';
import type { OnInit } from '@angular/core';
import { FormsModule } from '@angular/forms';
import { MatIconModule } from '@angular/material/icon';
import * as ExcelJS from 'exceljs';
import * as FileSaver from 'file-saver';
import jsPDF from 'jspdf';
import autoTable from 'jspdf-autotable';

import { environment } from '../environments/environment';
import type { ApiResponse } from '../models/api-response.model';
// eslint-disable-next-line @typescript-eslint/consistent-type-imports
import { AuthService } from '../services/auth.service';
import { ImagePreviewModalComponent } from '../shared/image-preview-modal/image-preview-modal.component';

interface LoadProofDto {
  dispatchId: number;
  routeCode: string;
  driverName: string;
  proofImagePaths: string[];
  signaturePath: string;
  remarks: string;
  uploadedAt: string;
}

@Component({
  selector: 'app-load-proof-admin',
  standalone: true,
  imports: [CommonModule, FormsModule, ImagePreviewModalComponent, MatIconModule],
  templateUrl: './load-proof-admin.component.html',
  styleUrls: ['./load-proof-admin.component.css'],
})
export class LoadProofAdminComponent implements OnInit {
  proofs: LoadProofDto[] = [];
  filteredProofs: LoadProofDto[] = [];
  loading = false;
  error = '';

  searchText = '';
  selectedDriver = '';
  routeFilter = '';
  fromDate = '';
  toDate = '';

  driverList: string[] = [];
  showModal = false;
  modalImages: string[] = [];
  currentImageIndex = 0;

  autoRefresh = false;
  refreshInterval = 900000;
  intervalId: any = null;

  refreshOptions = [
    { value: 15000, label: '15 seconds' },
    { value: 30000, label: '30 seconds' },
    { value: 60000, label: '1 minute' },
    { value: 120000, label: '2 minutes' },
    { value: 300000, label: '5 minutes' },
    { value: 600000, label: '10 minutes' },
    { value: 900000, label: '15 minutes' },
    { value: 1800000, label: '30 minutes' },
    { value: 3600000, label: '1 hour' },
  ];

  private readonly apiUrl = `${environment.baseUrl}/api/admin/dispatches/proofs/load`;
  baseUrl = `${environment.baseUrl}/uploads`;

  constructor(
    private http: HttpClient,
    private authService: AuthService,
  ) {}

  ngOnInit(): void {
    this.fetchLoadProofs();
    if (this.autoRefresh) {
      this.startAutoRefresh();
    }
  }

  fetchLoadProofs(): void {
    this.loading = true;
    this.error = '';

    const headers = new HttpHeaders({
      'Content-Type': 'application/json',
      Authorization: `Bearer ${this.authService.getToken()}`,
    });

    this.http.get<ApiResponse<LoadProofDto[]>>(this.apiUrl, { headers }).subscribe({
      next: (res) => {
        this.proofs = res.data || [];
        this.filteredProofs = this.proofs;
        this.driverList = [...new Set(this.proofs.map((p) => p.driverName))];
        this.loading = false;
      },
      error: (err) => {
        console.error(' Error fetching load proofs:', err);
        this.error = 'Failed to load data.';
        this.loading = false;
      },
    });
  }

  toggleAutoRefresh(): void {
    this.autoRefresh ? this.startAutoRefresh() : this.stopAutoRefresh();
  }

  startAutoRefresh(): void {
    this.stopAutoRefresh();
    this.intervalId = setInterval(() => {
      console.log(' Auto-refresh triggered...');
      this.fetchLoadProofs();
    }, this.refreshInterval);
  }

  stopAutoRefresh(): void {
    if (this.intervalId) {
      clearInterval(this.intervalId);
      this.intervalId = null;
    }
  }

  changeInterval(newInterval: number): void {
    this.refreshInterval = newInterval;
    if (this.autoRefresh) {
      this.startAutoRefresh();
    }
  }

  onIntervalChange(event: Event): void {
    const value = parseInt((event.target as HTMLSelectElement).value, 10);
    this.changeInterval(value);
  }

  applyFilter(): void {
    const query = this.searchText.toLowerCase();
    this.filteredProofs = this.proofs.filter((proof) => {
      const date = new Date(proof.uploadedAt);
      return (
        (!this.fromDate || new Date(this.fromDate) <= date) &&
        (!this.toDate || new Date(this.toDate) >= date) &&
        (!this.selectedDriver || proof.driverName === this.selectedDriver) &&
        (!this.routeFilter ||
          proof.routeCode.toLowerCase().includes(this.routeFilter.toLowerCase())) &&
        `${proof.dispatchId} ${proof.routeCode} ${proof.driverName} ${proof.remarks || ''}`
          .toLowerCase()
          .includes(query)
      );
    });
  }

  resetFilters(): void {
    this.searchText = '';
    this.selectedDriver = '';
    this.routeFilter = '';
    this.fromDate = '';
    this.toDate = '';
    this.filteredProofs = this.proofs;
  }

  openPreview(images: string[], index: number): void {
    this.modalImages = images.map((img) => this.buildUploadUrl(img));
    this.currentImageIndex = index;
    this.showModal = true;
  }

  buildUploadUrl(path?: string): string {
    if (!path) return '';
    const cleaned = path
      .replace(/^https?:\/\/[^/]+/i, '')
      .replace(/^\/+/, '')
      .replace(/^uploads\/+/i, '')
      .replace(/^\/+/, '');
    return `${this.baseUrl}/${cleaned}`.replace(/([^:]\/)\/+/g, '$1');
  }

  closeModal(): void {
    this.showModal = false;
  }

  nextImage(): void {
    if (this.currentImageIndex < this.modalImages.length - 1) this.currentImageIndex++;
  }

  prevImage(): void {
    if (this.currentImageIndex > 0) this.currentImageIndex--;
  }

  async exportToExcel(): Promise<void> {
    const workbook = new ExcelJS.Workbook();
    const worksheet = workbook.addWorksheet('Load Proofs');

    worksheet.columns = [
      { header: 'Trip ID', key: 'dispatchId', width: 15 },
      { header: 'Driver', key: 'driverName', width: 20 },
      { header: 'Route Code', key: 'routeCode', width: 20 },
      { header: 'Remarks', key: 'remarks', width: 30 },
      { header: 'Uploaded At', key: 'uploadedAt', width: 20 },
    ];

    this.filteredProofs.forEach((proof) => {
      worksheet.addRow({
        dispatchId: proof.dispatchId,
        driverName: proof.driverName,
        routeCode: proof.routeCode,
        remarks: proof.remarks,
        uploadedAt: proof.uploadedAt,
      });
    });

    worksheet.getRow(1).font = { bold: true };

    const buffer = await workbook.xlsx.writeBuffer();
    FileSaver.saveAs(new Blob([buffer]), 'LoadProofs.xlsx');
  }

  async exportToExcelWithImages(): Promise<void> {
    const workbook = new ExcelJS.Workbook();
    const worksheet = workbook.addWorksheet('Load Proofs');

    worksheet.columns = [
      { header: 'Trip ID', key: 'dispatchId', width: 15 },
      { header: 'Driver', key: 'driverName', width: 20 },
      { header: 'Route Code', key: 'routeCode', width: 20 },
      { header: 'Remarks', key: 'remarks', width: 30 },
      { header: 'Uploaded At', key: 'uploadedAt', width: 20 },
    ];

    const imageStartCol = 5;

    for (const [index, proof] of this.filteredProofs.entries()) {
      const rowIndex = index + 2;

      worksheet.addRow({
        dispatchId: proof.dispatchId,
        driverName: proof.driverName,
        routeCode: proof.routeCode,
        remarks: proof.remarks,
        uploadedAt: proof.uploadedAt,
      });

      if (proof.proofImagePaths?.length) {
        for (let i = 0; i < proof.proofImagePaths.length; i++) {
          const imgUrl = this.buildUploadUrl(proof.proofImagePaths[i]);
          const buffer = await this.fetchImageBuffer(imgUrl);

          const imageId = workbook.addImage({
            buffer,
            extension: 'jpeg',
          });

          worksheet.addImage(imageId, {
            tl: { col: imageStartCol + i, row: rowIndex - 1 },
            ext: { width: 80, height: 80 },
          });
        }

        worksheet.getRow(rowIndex).height = 80;
      }
    }

    const buffer = await workbook.xlsx.writeBuffer();
    FileSaver.saveAs(new Blob([buffer]), 'LoadProofs_with_Multiple_Images.xlsx');
  }

  exportToPDF(): void {
    const doc = new jsPDF();
    const tableData = this.filteredProofs.map((p) => [
      p.dispatchId,
      p.driverName,
      p.routeCode,
      p.remarks,
      p.uploadedAt,
    ]);
    autoTable(doc, {
      head: [['Trip ID', 'Driver', 'Route', 'Remarks', 'Uploaded At']],
      body: tableData,
    });
    doc.save('LoadProofs.pdf');
  }

  async fetchImageBuffer(url: string): Promise<ArrayBuffer> {
    try {
      const response = await fetch(url);
      if (!response.ok) throw new Error('Image fetch failed');
      return await response.arrayBuffer();
    } catch (err) {
      const fallback =
        'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR4nGNgYGBgAAAABAABJzQnCgAAAABJRU5ErkJggg==';
      const byteString = atob(fallback);
      const buffer = new Uint8Array(byteString.length);
      for (let i = 0; i < byteString.length; i++) buffer[i] = byteString.charCodeAt(i);
      return buffer.buffer;
    }
  }
}
