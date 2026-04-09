/* eslint-disable @typescript-eslint/consistent-type-imports */
import { CommonModule } from '@angular/common';
import { Component } from '@angular/core';
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
  file: File | null = null;
  previewItems: Item[] = [];
  failedItems: Item[] = [];
  isPreviewReady = false;
  loading = false;

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

  showToastMessage(message: string, type: 'success' | 'error', duration = 3000) {
    this.toastMessage = message;
    this.toastType = type;
    this.showToast = true;
    setTimeout(() => (this.showToast = false), duration);
  }

  async handleFileInput(event: any): Promise<void> {
    this.file = event.target.files[0];
    if (!this.file) return;

    const workbook = new ExcelJS.Workbook();
    await workbook.xlsx.load(await this.file.arrayBuffer());
    const worksheet = workbook.getWorksheet('Items') || workbook.worksheets[0];

    if (!worksheet) {
      this.showToastMessage(' No worksheet found!', 'error');
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

    this.isPreviewReady = false;
    this.previewItems = [];
    this.failedItems = [];
  }

  async generatePreview(): Promise<void> {
    if (!this.file) return;

    const workbook = new ExcelJS.Workbook();
    await workbook.xlsx.load(await this.file.arrayBuffer());
    const worksheet = workbook.getWorksheet('Items') || workbook.worksheets[0];

    const headerRow = worksheet.getRow(1);
    const headerIndexMap: Record<string, number> = {};
    headerRow.eachCell((cell: any, colNumber: number) => {
      const key = String(cell.text || '')
        .trim()
        .toLowerCase();
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
        console.error(' Error importing item:', item, err);
        failed++;
        this.failedItems.push(item);
      }
    }

    if (success > 0) {
      this.showToastMessage(` Imported: ${success},  Failed: ${failed}`, 'success');
    } else {
      this.showToastMessage(` Failed to import any items`, 'error');
    }

    this.previewItems = [];
    this.isPreviewReady = false;
    this.loading = false;
  }

  async exportFailedToExcel(): Promise<void> {
    const workbook = new ExcelJS.Workbook();
    const sheet = workbook.addWorksheet('Failed Imports');

    sheet.columns = Object.keys(this.fieldLabels).map((key) => ({
      header: this.fieldLabels[key],
      key,
    }));

    this.failedItems.forEach((item) => sheet.addRow(item));
    const blob = await workbook.xlsx.writeBuffer();
    const link = document.createElement('a');
    link.href = URL.createObjectURL(new Blob([blob]));
    link.download = 'failed_items.xlsx';
    link.click();
  }
}
