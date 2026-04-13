/* eslint-disable @typescript-eslint/consistent-type-imports */
import { CommonModule } from '@angular/common';
import { Component, ElementRef, ViewChild } from '@angular/core';
import { FormsModule } from '@angular/forms';
import * as ExcelJS from 'exceljs';

import type { Item } from '../../../../models/item.model';
import { ItemService } from '../../../../services/item.service';
import { firstValueFrom } from 'rxjs';

@Component({
  selector: 'app-item-import',
  standalone: true,
  templateUrl: './item-import.component.html',
  styleUrls: ['./item-import.component.css'],
  imports: [CommonModule, FormsModule],
})
export class ItemImportComponent {
  @ViewChild('fileInput') fileInput!: ElementRef<HTMLInputElement>;

  file: File | null = null;
  previewItems: Item[] = [];
  failedItems: Item[] = [];
  isPreviewReady = false;
  loading = false;
  isDragging = false;

  toastMessage = '';
  toastType: 'success' | 'error' | '' = '';
  showToast = false;

  excelColumns: string[] = [];

  fieldLabels: Record<string, string> = {
    itemCode: 'Item Code',
    itemName: 'Item Name',
    itemNameKh: 'Item Name (Khmer)',
    quantity: 'Quantity',
    size: 'Size',
    unit: 'Unit',
    weight: 'Weight',
    itemType: 'Item Type',
    pallets: 'Pallets',
    palletType: 'Pallet Type',
    status: 'Status',
    sortOrder: 'Sort Order',
  };

  columnMapping: Record<string, string> = {
    itemCode: '',
    itemName: '',
    itemNameKh: '',
    quantity: '',
    size: '',
    unit: '',
    weight: '',
    itemType: '',
    pallets: '',
    palletType: '',
    status: '',
    sortOrder: '',
  };

  constructor(private itemService: ItemService) {}

  // ── Drag & Drop ──────────────────────────────────────────────────────────

  onDragOver(event: DragEvent) {
    event.preventDefault();
    event.stopPropagation();
    this.isDragging = true;
  }

  onDragLeave(event: DragEvent) {
    event.preventDefault();
    event.stopPropagation();
    this.isDragging = false;
  }

  onDrop(event: DragEvent) {
    event.preventDefault();
    event.stopPropagation();
    this.isDragging = false;
    const file = event.dataTransfer?.files?.[0];
    if (file) this.loadFile(file);
  }

  onFileInputChange(event: Event) {
    const file = (event.target as HTMLInputElement).files?.[0] ?? null;
    if (file) this.loadFile(file);
  }

  private async loadFile(file: File) {
    if (!file.name.match(/\.xlsx$/i)) {
      this.showToastMessage('Only .xlsx files are supported', 'error');
      return;
    }
    this.file = file;
    this.isPreviewReady = false;
    this.previewItems = [];
    this.failedItems = [];

    const workbook = new ExcelJS.Workbook();
    await workbook.xlsx.load(await file.arrayBuffer());
    const worksheet = workbook.getWorksheet('Items') || workbook.worksheets[0];

    if (!worksheet) {
      this.showToastMessage('No worksheet found in file', 'error');
      return;
    }

    const headerRow = worksheet.getRow(1);
    this.excelColumns = [];
    headerRow.eachCell((cell: any) => {
      this.excelColumns.push(String(cell.text || '').trim());
    });

    for (const field in this.columnMapping) {
      const match = this.excelColumns.find(
        (h) => h.trim().toLowerCase().replace(/\s|_/g, '') === field.toLowerCase(),
      );
      this.columnMapping[field] = match ?? '';
    }
  }

  // ── Preview ──────────────────────────────────────────────────────────────

  async generatePreview(): Promise<void> {
    if (!this.file) return;

    const workbook = new ExcelJS.Workbook();
    await workbook.xlsx.load(await this.file.arrayBuffer());
    const worksheet = workbook.getWorksheet('Items') || workbook.worksheets[0];

    const headerRow = worksheet.getRow(1);
    const headerIndexMap: Record<string, number> = {};
    headerRow.eachCell((cell: any, colNumber: number) => {
      const key = String(cell.text || '').trim().toLowerCase();
      headerIndexMap[key] = colNumber;
    });

    const getValue = (row: ExcelJS.Row, field: keyof Item): string => {
      const mappedHeader = this.columnMapping[field];
      const colIndex = headerIndexMap[mappedHeader?.toLowerCase()];
      return String(row.getCell(colIndex)?.text ?? '').trim();
    };

    const preview: Item[] = [];
    worksheet.eachRow((row, rowIndex) => {
      if (rowIndex === 1) return;
      const itemName = getValue(row, 'itemName');
      if (!itemName) return;
      preview.push({
        itemCode: getValue(row, 'itemCode'),
        itemName,
        itemNameKh: getValue(row, 'itemNameKh'),
        quantity: parseInt(getValue(row, 'quantity')) || 0,
        size: getValue(row, 'size'),
        unit: getValue(row, 'unit'),
        weight: getValue(row, 'weight'),
        itemType: getValue(row, 'itemType'),
        pallets: getValue(row, 'pallets'),
        palletType: getValue(row, 'palletType'),
        status: getValue(row, 'status') === '0' ? 0 : 1,
        sortOrder: parseInt(getValue(row, 'sortOrder')) || 0,
      });
    });

    this.previewItems = preview;
    this.isPreviewReady = true;
  }

  // ── Import ───────────────────────────────────────────────────────────────

  async confirmImport(): Promise<void> {
    this.loading = true;
    let success = 0;
    let failed = 0;
    this.failedItems = [];

    for (const item of this.previewItems) {
      try {
        await firstValueFrom(this.itemService.createItem(item));
        success++;
      } catch (err) {
        console.error('Error importing item:', item, err);
        failed++;
        this.failedItems.push(item);
      }
    }

    if (success > 0) {
      this.showToastMessage(`Imported: ${success}  Failed: ${failed}`, 'success');
    } else {
      this.showToastMessage('Failed to import any items', 'error');
    }

    this.previewItems = [];
    this.isPreviewReady = false;
    this.loading = false;
    this.resetInput();
  }

  // ── Download Template ────────────────────────────────────────────────────

  async downloadTemplate(): Promise<void> {
    const workbook = new ExcelJS.Workbook();
    const sheet = workbook.addWorksheet('Items');

    sheet.columns = Object.keys(this.fieldLabels).map((key) => ({
      header: this.fieldLabels[key],
      key,
      width: 20,
    }));

    // Style header row
    const headerRow = sheet.getRow(1);
    headerRow.font = { bold: true, color: { argb: 'FFFFFFFF' } };
    headerRow.fill = {
      type: 'pattern',
      pattern: 'solid',
      fgColor: { argb: 'FF2563EB' },
    };
    headerRow.alignment = { horizontal: 'center' };

    // Sample row
    sheet.addRow({
      itemCode: 'ITEM-001',
      itemName: 'Sample Item',
      itemNameKh: 'ទំនិញគំរូ',
      quantity: 10,
      size: 'M',
      unit: 'PCS',
      weight: '1.5',
      itemType: 'GENERAL',
      pallets: '2',
      palletType: 'EURO',
      status: 1,
      sortOrder: 1,
    });

    const blob = await workbook.xlsx.writeBuffer();
    const link = document.createElement('a');
    link.href = URL.createObjectURL(new Blob([blob]));
    link.download = 'items_import_template.xlsx';
    link.click();
    URL.revokeObjectURL(link.href);
  }

  // ── Export Failed ────────────────────────────────────────────────────────

  async exportFailedToExcel(): Promise<void> {
    const workbook = new ExcelJS.Workbook();
    const sheet = workbook.addWorksheet('Failed Imports');

    sheet.columns = Object.keys(this.fieldLabels).map((key) => ({
      header: this.fieldLabels[key],
      key,
      width: 20,
    }));

    this.failedItems.forEach((item) => sheet.addRow(item));

    const blob = await workbook.xlsx.writeBuffer();
    const link = document.createElement('a');
    link.href = URL.createObjectURL(new Blob([blob]));
    link.download = 'failed_items.xlsx';
    link.click();
    URL.revokeObjectURL(link.href);
  }

  // ── Helpers ──────────────────────────────────────────────────────────────

  showToastMessage(message: string, type: 'success' | 'error', duration = 4000) {
    this.toastMessage = message;
    this.toastType = type;
    this.showToast = true;
    setTimeout(() => (this.showToast = false), duration);
  }

  private resetInput() {
    this.file = null;
    this.excelColumns = [];
    for (const field in this.columnMapping) {
      this.columnMapping[field] = '';
    }
    this.fileInput.nativeElement.value = '';
  }
}
