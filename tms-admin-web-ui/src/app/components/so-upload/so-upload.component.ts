import { CommonModule } from '@angular/common';
// eslint-disable-next-line @typescript-eslint/consistent-type-imports
import { HttpClient } from '@angular/common/http';
import { Component, inject } from '@angular/core';
import { FormsModule, ReactiveFormsModule } from '@angular/forms';
import { MatExpansionModule } from '@angular/material/expansion';
import * as ExcelJS from 'exceljs';
import * as FileSaver from 'file-saver';

import { skuMaster } from '../../data/sku-master'; // Adjust path as needed
import { NotificationService } from '../../services/notification.service';

import type { TruckPlan, DriverTruck, SoRow } from './model.component';

@Component({
  selector: 'app-so-upload',
  templateUrl: './so-upload.component.html',
  standalone: true,
  imports: [CommonModule, FormsModule, ReactiveFormsModule, MatExpansionModule],
})
export class SoUploadComponent {
  private notification = inject(NotificationService);
  selectedFile: File | null = null;
  previewData: SoRow[] = [];
  pagedData: SoRow[] = [];
  displayedColumns: string[] = [];
  summaryStats: { label: string; value: number | string }[] = [];
  sortColumn: string = '';
  sortDirection: 'asc' | 'desc' = 'asc';
  showSummary: boolean = true;
  showTable: boolean = true;
  pageSize: number = 300;
  currentPage: number = 0;
  validationMessages: string[] = [];
  showTableTotal: boolean = false;
  errorRows: SoRow[] = [];
  hasValidationErrors: boolean = false;
  truckPlans: TruckPlan[] = [];
  skuMaster = skuMaster; //  Uses imported data
  showDriverInfo: boolean = false;
  showTruckPlan: boolean = false;
  showTablePreview: boolean = false;

  get totalPages(): number {
    return Math.ceil(this.previewData.length / this.pageSize);
  }

  ngOnInit(): void {
    this.generateMockDriverTrucks();
  }
  driverInfo: DriverTruck[] = [];

  generateMockDriverTrucks(): void {
    const truckTypes = [
      { type: '6-Wheeler', maxWeight: 10000, maxVolume: 18.0, pallets: 4 },
      { type: '10-Wheeler', maxWeight: 14000, maxVolume: 24.0, pallets: 6 },
      { type: '12-Wheeler', maxWeight: 16000, maxVolume: 28.0, pallets: 8 },
      {
        type: 'Container 20ft',
        maxWeight: 22000,
        maxVolume: 33.0,
        pallets: 10,
      },
      {
        type: 'Container 40ft',
        maxWeight: 28000,
        maxVolume: 67.0,
        pallets: 20,
      },
    ];

    for (let i = 1; i <= 150; i++) {
      const random = truckTypes[Math.floor(Math.random() * truckTypes.length)];

      this.driverInfo.push({
        name: `Driver ${i}`,
        phone: `09${Math.floor(1000000 + Math.random() * 9000000)}`,
        licensePlate: `KH-${1000 + i}`,
        truckType: random.type,
        maxWeight: random.maxWeight,
        maxVolume: random.maxVolume,
        availablePallets: random.pallets,
        status: i % 5 === 0 ? 'Pending' : 'Available',
      });
    }
  }

  // driverInfo = [
  //   { name: 'Chhun Vanna', phone: '092 888 999', licensePlate: '2AK-7788', truckType: '12-Wheeler', maxWeight: 16000, maxVolume: 28.0, availablePallets: 8, status: 'Available' },
  //   { name: 'Kim Leap', phone: '087 234 5678', licensePlate: '2BK-5566', truckType: '10-Wheeler', maxWeight: 14000, maxVolume: 24.0, availablePallets: 6, status: 'Pending' },
  //   { name: 'Sok Dara', phone: '088 123 4567', licensePlate: '3AD-3322', truckType: '10-Wheeler', maxWeight: 14500, maxVolume: 25.5, availablePallets: 7, status: 'Available' }
  // ];
  constructor(private readonly http: HttpClient) {}

  getTotalMaxWeight(): number {
    return this.driverInfo.reduce((sum, d) => sum + d.maxWeight, 0);
  }

  getTotalMaxVolume(): number {
    return +this.driverInfo.reduce((sum, d) => sum + d.maxVolume, 0).toFixed(2);
  }

  getTotalAvailablePallets(): number {
    return this.driverInfo.reduce((sum, d) => sum + d.availablePallets, 0);
  }

  getDriverSummary() {
    return {
      totalWeight: this.getTotalMaxWeight(),
      totalVolume: this.getTotalMaxVolume(),
      totalPallets: this.getTotalAvailablePallets(),
    };
  }

  async onFileChange(event: Event) {
    const input = event.target as HTMLInputElement;
    const file = input?.files?.[0];
    if (file) {
      this.selectedFile = file;
      const buffer = await file.arrayBuffer();
      const wb = new ExcelJS.Workbook();
      await wb.xlsx.load(buffer);
      const ws = wb.worksheets[0];
      if (!ws) return;

      const headerVals = (ws.getRow(1).values as Array<string | number | null | undefined>) || [];
      const headers: string[] = headerVals.map((h) =>
        typeof h === 'string' ? h.trim() : h != null ? String(h).trim() : '',
      );

      const data: SoRow[] = [] as any;
      ws.eachRow((row, rowNumber) => {
        if (rowNumber === 1) return;
        const obj: any = {};
        for (let c = 1; c < headers.length; c++) {
          const key = headers[c];
          if (!key) continue;
          const v: any = row.getCell(c).value;
          const normalized =
            v?.text ??
            v?.result ??
            (Array.isArray(v?.richText) ? v.richText.map((rt: any) => rt.text).join('') : v);
          obj[key] = typeof normalized === 'string' ? normalized.trim() : (normalized ?? '');
        }
        data.push(obj as SoRow);
      });

      const errorSet = new Set<string>();
      this.errorRows = [];

      this.previewData = data.map((row: SoRow) => {
        const matched = this.skuMaster.find((p) => p.name === row['Description']);
        const qty = +row['Remaining Qty'] || 0;
        const weight = matched ? matched.weight * qty : 0;
        const volume = matched ? matched.volume * qty : 0;
        const hasError = !matched || qty <= 0;

        if (hasError) {
          this.errorRows.push(row);
          if (!matched) errorSet.add(`SKU not found: ${row['Description']}`);
          if (qty <= 0) errorSet.add(`Invalid Qty for: ${row['Description']}`);
        }

        return {
          ...row,
          'Weight (kg)': weight,
          'Volume (m3)': volume,
          isError: hasError,
        };
      });

      this.validationMessages = Array.from(errorSet);
      this.displayedColumns = Object.keys(this.previewData[0] || {}).filter(
        (col) => col !== '__rowNum__',
      );
      this.generateSummary();
      this.updatePagedData();
      this.generateTruckPlansFromPreview();
      this.generateGroupedLoadSummary();
    }
  }

  summary = {
    totaLocations: 0,
    totalItems: 0,
    totalQty: 0,
    totalWeight: 0,
    totalVolume: 0,
    estimatedTrucks: 0,
    usedTrucks: 0, //  Add this
  };
  generateSummary(): void {
    const totalQty = this.previewData.reduce(
      (sum, row) => sum + (Number(row['Remaining Qty']) || 0),
      0,
    );
    const totalWeight = this.previewData.reduce(
      (sum, row) => sum + (Number(row['Weight (kg)']) || 0),
      0,
    );
    const totalVolume = this.previewData.reduce(
      (sum, row) => sum + (Number(row['Volume (m³)']) || Number(row['Volume (m3)']) || 0),
      0,
    );
    const totalItems = this.previewData.length;
    const dropLocations = new Set(
      this.previewData.map((row) => row['Ship to Party Name'] || row['Drop-off'] || ''),
    ).size;

    const ISO_PALLET_VOLUME = 1.5; // m³ per ISO pallet
    const MAX_PALLETS_PER_TRUCK = 22;

    const estimatedPallets = Math.ceil(totalVolume / ISO_PALLET_VOLUME);
    const estimatedTrucks = Math.ceil(estimatedPallets / MAX_PALLETS_PER_TRUCK);

    const usedTrucks = this.truckPlans
      ? this.truckPlans.filter((t) => t.status === 'Ready').length
      : 0;

    this.summaryStats = [
      { label: 'Drop-off Locations', value: dropLocations },
      { label: 'Total Items', value: totalItems },
      { label: 'Total Qty', value: totalQty },
      { label: 'Weight (kg)', value: totalWeight.toLocaleString() },
      { label: 'Volume (m³)', value: totalVolume.toFixed(2) },
      { label: 'Estimated Pallets', value: estimatedPallets },
      { label: 'Estimated Trucks Needed', value: estimatedTrucks },
      { label: 'Used Trucks (Actual)', value: usedTrucks },
    ];
  }

  upload() {
    if (!this.selectedFile || this.validationMessages.length > 0) return;

    const formData = new FormData();
    formData.append('file', this.selectedFile);

    this.http.post('/api/so-upload', formData).subscribe({
      next: () => this.notification.simulateNotification('Success', 'Upload successful'),
      error: () => this.notification.simulateNotification('Error', 'Upload failed'),
    });
  }

  downloadErrorReport() {
    const headers = Object.keys(this.errorRows[0] || {});
    const rows = this.errorRows.map((e) =>
      headers.map((h) => `"${(e[h] ?? '').toString().replace(/"/g, '""')}"`).join(','),
    );
    const csvContent = 'data:text/csv;charset=utf-8,' + [headers.join(','), ...rows].join('\n');

    const encodedUri = encodeURI(csvContent);
    const link = document.createElement('a');
    link.setAttribute('href', encodedUri);
    link.setAttribute('download', 'validation_errors.csv');
    document.body.appendChild(link);
    link.click();
    document.body.removeChild(link);
  }

  sortTable(column: string) {
    if (this.sortColumn === column) {
      this.sortDirection = this.sortDirection === 'asc' ? 'desc' : 'asc';
    } else {
      this.sortColumn = column;
      this.sortDirection = 'asc';
    }

    this.previewData.sort((a, b) => {
      const aValue = isNaN(a[column]) ? a[column] : Number(a[column]);
      const bValue = isNaN(b[column]) ? b[column] : Number(b[column]);

      if (aValue === bValue) return 0;
      return this.sortDirection === 'asc' ? (aValue > bValue ? 1 : -1) : aValue < bValue ? 1 : -1;
    });

    this.currentPage = 0;
    this.updatePagedData();
  }

  updatePagedData() {
    const start = this.currentPage * this.pageSize;
    const end = start + this.pageSize;
    this.pagedData = this.previewData.slice(start, end);
  }

  nextPage() {
    if (this.currentPage + 1 < this.totalPages) {
      this.currentPage++;
      this.updatePagedData();
    }
  }

  prevPage() {
    if (this.currentPage > 0) {
      this.currentPage--;
      this.updatePagedData();
    }
  }

  isUnknownItem(row: SoRow): boolean {
    return !this.skuMaster.some((sku) => sku.name === row.Description);
  }

  generateTruckPlansFromPreview() {
    if (!this.previewData.length) return;

    const palletPerUnitVolume = 0.016; // 1 pallet = 0.016 m³
    const maxPalletsPerTruck = 22;

    const sortedOrders = [...this.previewData].sort(
      (a, b) => this.safeNumber(b['Volume (m3)']) - this.safeNumber(a['Volume (m3)']),
    );

    let fallbackTruckCounter = 1;
    const fallbackTrucks: {
      truckNo: string;
      orders: SoRow[];
      currentVolume: number;
      currentWeight: number;
      currentPallets: number;
    }[] = [];

    const trucks = this.driverInfo.map((driver) => ({
      ...driver,
      currentVolume: 0,
      currentWeight: 0,
      currentPallets: 0,
      orders: [] as SoRow[],
    }));

    sortedOrders.forEach((order) => {
      const vol = this.safeNumber(order['Volume (m3)']);
      const wgt = this.safeNumber(order['Weight (kg)']);
      const pallets = Math.ceil(vol / palletPerUnitVolume);

      let assigned = false;

      for (const t of trucks) {
        if (
          t.currentVolume + vol <= t.maxVolume &&
          t.currentWeight + wgt <= t.maxWeight &&
          t.currentPallets + pallets <= maxPalletsPerTruck
        ) {
          t.orders.push(order);
          t.currentVolume += vol;
          t.currentWeight += wgt;
          t.currentPallets += pallets;
          order['Truck No.'] = t.licensePlate;
          assigned = true;
          break;
        }
      }

      if (!assigned) {
        // fallback logic
        let fallback = fallbackTrucks.find(
          (f) =>
            f.currentVolume + vol <= 30 &&
            f.currentWeight + wgt <= 15000 &&
            f.currentPallets + pallets <= maxPalletsPerTruck,
        );

        if (!fallback) {
          fallback = {
            truckNo: `FB-T${fallbackTruckCounter++}`,
            orders: [],
            currentVolume: 0,
            currentWeight: 0,
            currentPallets: 0,
          };
          fallbackTrucks.push(fallback);
        }

        fallback.orders.push(order);
        fallback.currentVolume += vol;
        fallback.currentWeight += wgt;
        fallback.currentPallets += pallets;
        order['Truck No.'] = fallback.truckNo;
      }
    });

    this.truckPlans = [
      ...trucks
        .filter((t) => t.orders.length > 0)
        .map((t) =>
          this.createTruckPlan(t.licensePlate, t.orders, t.name, t.truckType, t.phone, t.status),
        ),
      ...fallbackTrucks.map((t) => this.createTruckPlan(t.truckNo, t.orders)),
    ];
  }

  private createTruckPlan(
    truckNo: string,
    orders: SoRow[],
    driverName: string = 'Unassigned',
    truckType: string = 'N/A',
    contact: string = '-',
    status: string = 'Pending',
    maxPallets: number = 22, // Default capacity per truck
  ): TruckPlan {
    const qty = orders.reduce((sum, r) => sum + this.safeNumber(r['Remaining Qty']), 0);
    const weight = orders.reduce((sum, r) => sum + this.safeNumber(r['Weight (kg)']), 0);
    const volume = orders.reduce((sum, r) => sum + this.safeNumber(r['Volume (m3)']), 0);

    const estPallets = Math.ceil(volume / 0.016); // assuming 1 pallet = 0.016 m³
    const palletUtilization = +((estPallets / maxPallets) * 100).toFixed(1); // percent

    return {
      truckNo,
      dropOff: 'Multiple',
      items: orders.length,
      qty,
      weight,
      volume: +volume.toFixed(2),
      truckType,
      driver: driverName,
      contact,
      status: status === 'Available' ? 'Ready' : 'Pending',
      estPallets,
      maxPallets,
      palletUtilization,
    };
  }

  safeNumber(val: any): number {
    return typeof val === 'number' ? val : Number(val) || 0;
  }

  groupedLoadSummary: {
    rows: {
      truckNo: string;
      dropOff: string;
      product: string;
      qty: number;
      weight: number;
      volume: number;
    }[];
    subtotals: Record<string, { qty: number; weight: number; volume: number }>;
    grandTotal: { qty: number; weight: number; volume: number };
  } = {
    rows: [],
    subtotals: {},
    grandTotal: { qty: 0, weight: 0, volume: 0 },
  };

  get groupedRows() {
    const groups: {
      truckNo: string;
      rows: {
        truckNo: string;
        dropOff: string;
        product: string;
        qty: number;
        weight: number;
        volume: number;
      }[];
      subtotal: {
        qty: number;
        weight: number;
        volume: number;
      };
    }[] = [];

    const map = new Map<
      string,
      {
        truckNo: string;
        rows: any[];
        subtotal: { qty: number; weight: number; volume: number };
      }
    >();

    for (const row of this.groupedLoadSummary.rows) {
      const key = row.truckNo;
      if (!map.has(key)) {
        map.set(key, {
          truckNo: key,
          rows: [],
          subtotal: { qty: 0, weight: 0, volume: 0 },
        });
      }
      const group = map.get(key)!;
      group.rows.push(row);
      group.subtotal.qty += row.qty;
      group.subtotal.weight += row.weight;
      group.subtotal.volume += row.volume;
    }

    return Array.from(map.values());
  }

  get grandTotal() {
    return this.groupedLoadSummary.grandTotal;
  }

  generateGroupedLoadSummary() {
    const result: {
      truckNo: string;
      dropOff: string;
      product: string;
      qty: number;
      weight: number;
      volume: number;
    }[] = [];

    const subtotals: Record<string, { qty: number; weight: number; volume: number }> = {};

    this.previewData.forEach((row) => {
      const truckNo = row['Truck No.'] ?? 'Unknown';
      const dropOff = row['Ship to Party Name'] ?? 'Unknown';
      const product = row['Description'] ?? 'N/A';

      const qty = this.safeNumber(row['Remaining Qty']);
      const weight = this.safeNumber(row['Weight (kg)']);
      const volume = this.safeNumber(row['Volume (m3)']);

      result.push({ truckNo, dropOff, product, qty, weight, volume });

      if (!subtotals[truckNo]) {
        subtotals[truckNo] = { qty: 0, weight: 0, volume: 0 };
      }

      subtotals[truckNo].qty += qty;
      subtotals[truckNo].weight += weight;
      subtotals[truckNo].volume += volume;
    });

    const grandTotal = Object.values(subtotals).reduce(
      (acc, val) => ({
        qty: acc.qty + val.qty,
        weight: acc.weight + val.weight,
        volume: acc.volume + val.volume,
      }),
      { qty: 0, weight: 0, volume: 0 },
    );

    this.groupedLoadSummary = {
      rows: result,
      subtotals,
      grandTotal,
    };
  }

  exportGroupedSummaryToExcel(): void {
    const wsData = [
      ['Truck No.', 'Drop-off', 'Product', 'Qty', 'Weight (kg)', 'Volume (m³)'],
      ...this.groupedLoadSummary.rows.map((row) => [
        row.truckNo,
        row.dropOff,
        row.product,
        row.qty,
        row.weight,
        row.volume,
      ]),
      [], // empty row
      [
        'Grand Total',
        '',
        '',
        this.groupedLoadSummary.grandTotal.qty,
        this.groupedLoadSummary.grandTotal.weight,
        this.groupedLoadSummary.grandTotal.volume,
      ],
    ];

    const wb = new ExcelJS.Workbook();
    const ws = wb.addWorksheet('Load Summary');
    ws.addRows(wsData as any[]);
    wb.xlsx.writeBuffer().then((buf) => {
      const data = new Blob([buf], {
        type: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
      });
      FileSaver.saveAs(data, 'Grouped_Load_Summary.xlsx');
    });
  }
  exportTruckLoadDetailsToExcel(): void {
    const grouped = this.groupedLoadSummary.rows.reduce(
      (acc, row) => {
        if (!acc[row.truckNo]) acc[row.truckNo] = [];
        acc[row.truckNo].push(row);
        return acc;
      },
      {} as Record<string, typeof this.groupedLoadSummary.rows>,
    );

    const wsData: (string | number)[][] = [
      ['Truck No.', 'Drop-off', 'Product', 'Qty', 'Weight (kg)', 'Volume (m³)'],
    ];

    Object.keys(grouped).forEach((truckNo) => {
      const rows = grouped[truckNo];
      rows.forEach((row) => {
        wsData.push([
          row.truckNo,
          row.dropOff,
          row.product,
          row.qty,
          row.weight,
          +row.volume.toFixed(2),
        ]);
      });

      const subtotal = this.groupedLoadSummary.subtotals[truckNo];
      wsData.push([
        `${truckNo} Subtotal`,
        '',
        '',
        subtotal.qty,
        subtotal.weight,
        +subtotal.volume.toFixed(2),
      ]);

      wsData.push([]); // empty row after group
    });

    // Grand Total
    const grand = this.groupedLoadSummary.grandTotal;
    wsData.push(['Grand Total', '', '', grand.qty, grand.weight, +grand.volume.toFixed(2)]);

    const wb = new ExcelJS.Workbook();
    const ws = wb.addWorksheet('Truck Load Details');
    ws.addRows(wsData as any[]);
    wb.xlsx.writeBuffer().then((buf) => {
      const data = new Blob([buf], {
        type: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
      });
      FileSaver.saveAs(data, 'Truck_Load_Details.xlsx');
    });
  }

  // Truck Load Details

  exportTruckLoadDetailsToExcelReport(): void {
    const grouped = this.groupedLoadSummary.rows.reduce(
      (acc, row) => {
        if (!acc[row.truckNo]) acc[row.truckNo] = [];
        acc[row.truckNo].push(row);
        return acc;
      },
      {} as Record<string, typeof this.groupedLoadSummary.rows>,
    );

    const wsData: (string | number)[][] = [];

    Object.keys(grouped).forEach((truckNo) => {
      wsData.push([` Truck No: ${truckNo}`]);
      wsData.push(['Drop-off', 'Product', 'Qty', 'Weight (kg)', 'Volume (m³)']);

      grouped[truckNo].forEach((row) => {
        wsData.push([row.dropOff, row.product, row.qty, row.weight, +row.volume.toFixed(2)]);
      });

      const subtotal = this.groupedLoadSummary.subtotals[truckNo];
      wsData.push(['Subtotal', '', subtotal.qty, subtotal.weight, +subtotal.volume.toFixed(2)]);

      wsData.push([]); // Spacer between trucks
    });

    // Add Grand Total
    const grand = this.groupedLoadSummary.grandTotal;
    wsData.push(['Grand Total', '', grand.qty, grand.weight, +grand.volume.toFixed(2)]);

    const wb = new ExcelJS.Workbook();
    const ws = wb.addWorksheet('Truck Load Report');
    ws.addRows(wsData as any[]);
    ws.columns = [{ width: 25 }, { width: 30 }, { width: 10 }, { width: 15 }, { width: 15 }];
    wb.xlsx.writeBuffer().then((buf) => {
      const blob = new Blob([buf], {
        type: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
      });
      FileSaver.saveAs(blob, 'Truck_Load_Details_Report.xlsx');
    });
  }

  exportTruckLoadStyledReport() {
    const workbook = new ExcelJS.Workbook();
    const sheet = workbook.addWorksheet('Truck Load Details');

    sheet.properties.defaultRowHeight = 20;

    // Define Columns
    sheet.columns = [
      { header: 'Drop-off', key: 'dropOff', width: 30 },
      { header: 'Product', key: 'product', width: 35 },
      { header: 'Qty', key: 'qty', width: 10 },
      { header: 'Weight (kg)', key: 'weight', width: 15 },
      { header: 'Volume (m³)', key: 'volume', width: 15 },
    ];

    const grouped = this.groupedLoadSummary.rows.reduce(
      (acc, row) => {
        if (!acc[row.truckNo]) acc[row.truckNo] = [];
        acc[row.truckNo].push(row);
        return acc;
      },
      {} as Record<string, typeof this.groupedLoadSummary.rows>,
    );

    const truckColors = ['FFEBF0', 'E8F6FF', 'F3FAD7', 'F9E5D8', 'E9FFF3'];

    let rowIdx = 1;
    let colorIndex = 0;

    Object.keys(grouped).forEach((truckNo, index) => {
      const truckRows = grouped[truckNo];
      const subtotal = this.groupedLoadSummary.subtotals[truckNo];
      const bgColor = truckColors[colorIndex++ % truckColors.length];

      // Merged Header
      const mergeHeader = ` Truck No: ${truckNo}`;
      sheet.mergeCells(`A${rowIdx}:E${rowIdx}`);
      const headerRow = sheet.getCell(`A${rowIdx}`);
      headerRow.value = mergeHeader;
      headerRow.font = { bold: true, color: { argb: 'FFFFFFFF' } };
      headerRow.fill = {
        type: 'pattern',
        pattern: 'solid',
        fgColor: { argb: 'FF007ACC' },
      };
      headerRow.alignment = { vertical: 'middle', horizontal: 'left' };
      rowIdx++;

      // Column Header Row
      const tableHeaderRow = sheet.insertRow(rowIdx, [
        'Drop-off',
        'Product',
        'Qty',
        'Weight (kg)',
        'Volume (m³)',
      ]);
      tableHeaderRow.font = { bold: true };
      tableHeaderRow.fill = {
        type: 'pattern',
        pattern: 'solid',
        fgColor: { argb: 'FFD9EAF7' },
      };
      rowIdx++;

      // Data Rows
      truckRows.forEach((row) => {
        const dataRow = sheet.insertRow(rowIdx, [
          row.dropOff,
          row.product,
          row.qty,
          row.weight,
          +row.volume.toFixed(2),
        ]);
        dataRow.fill = {
          type: 'pattern',
          pattern: 'solid',
          fgColor: { argb: bgColor },
        };
        rowIdx++;
      });

      // Subtotal
      const subtotalRow = sheet.insertRow(rowIdx, [
        'Subtotal',
        '',
        subtotal.qty,
        subtotal.weight,
        +subtotal.volume.toFixed(2),
      ]);
      subtotalRow.font = { bold: true };
      subtotalRow.fill = {
        type: 'pattern',
        pattern: 'solid',
        fgColor: { argb: 'FFFEE599' },
      };
      rowIdx += 2;
    });

    // Grand Total
    const grand = this.groupedLoadSummary.grandTotal;
    const grandTotalRow = sheet.addRow([
      'Grand Total',
      '',
      grand.qty,
      grand.weight,
      +grand.volume.toFixed(2),
    ]);
    grandTotalRow.font = { bold: true };
    grandTotalRow.fill = {
      type: 'pattern',
      pattern: 'solid',
      fgColor: { argb: 'FFB6D7A8' },
    };

    // Export file
    workbook.xlsx.writeBuffer().then((buffer) => {
      const blob = new Blob([buffer], {
        type: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
      });
      FileSaver.saveAs(blob, 'Truck_Load_Details_Styled_Report.xlsx');
    });
  }

  exportTruckLoadReport() {
    const products = this.skuMaster.map((p) => p.name); // product names as columns

    const rows = this.truckPlans.map((plan) => {
      const row: any = {
        'Loading Date': new Date().toLocaleDateString(),
        'Transport Vendor Name': 'CHHAY Y',
        'Transport Vendor Code': 'V_100569',
        Trip: 'LK1',
        'Truck Number': plan.truckNo,
        'Distributor Code': plan.dropOff,
        'Distributor Name': plan.dropOff,
        'Amount of Pallets': plan.items,
        Weight: plan.weight,
        Volume: plan.volume,
        Driver: plan.driver,
        'Truck Type': plan.truckType,
        Status: plan.status,
      };

      // Populate product quantities
      this.previewData
        .filter((row) => row['Truck No.'] === plan.truckNo)
        .forEach((row) => {
          const product = row['Description'];
          const qty = row['Remaining Qty'] ?? 0;
          row[product] = qty;
          row['Qty'] = qty;
          row['Weight'] = row['Weight (kg)'];
          row['Volume'] = row['Volume (m3)'];
          row['Truck No.'] = plan.truckNo;

          if (!row[product]) {
            row[product] = qty;
          } else {
            row[product] += qty;
          }
          row[product] = row[product];
        });

      products.forEach((p) => {
        row[p] = row[p] ?? '';
      });

      return row;
    });

    const headers = [
      'Loading Date',
      'Transport Vendor Name',
      'Transport Vendor Code',
      'Trip',
      'Truck Number',
      'Distributor Code',
      'Distributor Name',
      ...products,
      'Amount of Pallets',
      'Weight',
      'Volume',
      'Driver',
      'Truck Type',
      'Status',
    ];
    const wb = new ExcelJS.Workbook();
    const ws = wb.addWorksheet('Truck Load Report');
    ws.addRow(headers);
    for (const r of rows) {
      ws.addRow(headers.map((h) => (r as any)[h] ?? ''));
    }
    wb.xlsx.writeBuffer().then((buf) => {
      const fileName = 'Truck_Load_Details_Report.xlsx';
      const data = new Blob([buf], {
        type: 'application/octet-stream',
      });
      FileSaver.saveAs(data, fileName);
    });
  }

  async exportStyledTruckLoadReport() {
    const workbook = new ExcelJS.Workbook();
    const worksheet = workbook.addWorksheet('Truck Load Details');

    // 👉 1. Define product columns
    const productNames = this.skuMaster.map((p) => p.name);
    const fixedHeaders = [
      'Loading Date',
      'Transport Vendor Name',
      'Transport Vendor Code',
      'Trip',
      'Truck Number',
      'Distributor Code',
      'Distributor Name',
    ];
    const tailHeaders = [
      'Amount of Pallets',
      'SO Number',
      'Date of SO',
      'Remarks',
      'ETA',
      'Shift',
      'Time Arrival',
      'Time Truck Clean',
      'Time Check in',
      'Time Scale In',
      'Time Scale Out',
      'Time Check Out',
      'Time Truck Out',
      'Time Arrive Dealer',
      'Remark',
    ];

    const columns = [...fixedHeaders, ...productNames, ...tailHeaders];

    worksheet.columns = columns.map((key) => ({
      header: key,
      key,
      width: 20,
      style: {
        alignment: { vertical: 'middle', horizontal: 'center' },
        font: { name: 'Calibri', size: 11 },
      },
    }));

    // 👉 2. Add rows based on truckPlans
    this.truckPlans.forEach((plan, index) => {
      const baseRow: any = {
        'Loading Date': '29.03.2025',
        'Transport Vendor Name': 'CHHAY Y',
        'Transport Vendor Code': 'V_100569',
        Trip: 'LK1',
        'Truck Number': plan.truckNo,
        'Distributor Code': plan.dropOff,
        'Distributor Name': plan.dropOff,
        'Amount of Pallets': plan.items,
        'SO Number': 'SO-' + (index + 1),
        'Date of SO': '28.03.2025',
        Remarks: '',
        ETA: '13:30-15:30',
        Shift: 'Shift II',
        'Time Arrival': '',
        'Time Truck Clean': '',
        'Time Check in': '',
        'Time Scale In': '',
        'Time Scale Out': '',
        'Time Check Out': '',
        'Time Truck Out': '',
        'Time Arrive Dealer': '',
        Remark: index + 1,
      };

      const relatedItems = this.previewData.filter((p) => p['Truck No.'] === plan.truckNo);
      relatedItems.forEach((item) => {
        const desc = item['Description'];
        const qty = item['Remaining Qty'] || 0;
        baseRow[desc] = qty;
      });

      worksheet.addRow(baseRow);
    });

    // 👉 3. Header styling
    worksheet.getRow(1).eachCell((cell) => {
      cell.font = { bold: true };
      cell.fill = {
        type: 'pattern',
        pattern: 'solid',
        fgColor: { argb: 'FFE2EFDA' },
      };
      cell.border = {
        top: { style: 'thin' },
        bottom: { style: 'thin' },
        left: { style: 'thin' },
        right: { style: 'thin' },
      };
    });

    // 👉 4. Alternate row colors by truck
    worksheet.eachRow((row, rowNumber) => {
      if (rowNumber > 1) {
        const color = rowNumber % 2 === 0 ? 'FFF2F2F2' : 'FFFFFFFF';
        row.eachCell((cell) => {
          cell.fill = {
            type: 'pattern',
            pattern: 'solid',
            fgColor: { argb: color },
          };
        });
      }
    });

    // 👉 5. Export to file
    const buffer = await workbook.xlsx.writeBuffer();
    const blob = new Blob([buffer], {
      type: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
    });
    FileSaver.saveAs(blob, 'Styled_Truck_Load_Report.xlsx');
  }

  exportToExcelTruckLoad() {
    const wsData: any[][] = [];

    // Define product columns
    const allProducts = this.skuMaster.map((p) => p.name);

    // Define headers
    const headers = [
      'Loading Date',
      'Transport Vendor Name',
      'Transport Vendor Code',
      'Trip',
      'Truck Number',
      'Distributor Code',
      'Distributor Name',
      ...allProducts,
      'Amount of Pallets',
      'SO Number',
      'Date of SO',
      'Remarks',
      'ETA',
      'Shift',
      'Time Arrival',
      'Time Truck Clean',
      'Time Check In',
      'Time Scale In',
      'Time Scale Out',
      'Time Check Out',
      'Time Truck Out',
      'Time Arrive Dealer',
      'Remark',
    ];
    wsData.push(headers);

    // Map truck data to rows
    const truckMap: Record<string, any> = {};

    this.previewData.forEach((row) => {
      const truckKey = row['Truck No.'] || 'Unknown';

      if (!truckMap[truckKey]) {
        truckMap[truckKey] = {
          'Loading Date': '29.03.2025',
          'Transport Vendor Name': 'CHHAY Y',
          'Transport Vendor Code': 'V_100569',
          Trip: 'LK1',
          'Truck Number': truckKey,
          'Distributor Code': '',
          'Distributor Name': row['Ship to Party Name'] || '',
          products: {},
          'Amount of Pallets': '',
          'SO Number': '',
          'Date of SO': '28.03.2025',
          Remarks: '',
          ETA: '13:30-15:30',
          Shift: 'Shift II',
          'Time Arrival': '',
          'Time Truck Clean': '',
          'Time Check In': '',
          'Time Scale In': '',
          'Time Scale Out': '',
          'Time Check Out': '',
          'Time Truck Out': '',
          'Time Arrive Dealer': '',
          Remark: '',
        };
      }

      const qty = +row['Remaining Qty'] || 0;
      const product = row['Description'] || 'Unknown';
      truckMap[truckKey].products[product] = (truckMap[truckKey].products[product] || 0) + qty;
    });

    Object.values(truckMap).forEach((truck: any) => {
      const row = headers.map((header) => {
        if (allProducts.includes(header)) {
          return truck.products[header] || '';
        }
        return truck[header] || '';
      });
      wsData.push(row);
    });

    // Create worksheet and workbook
    const wb = new ExcelJS.Workbook();
    const ws = wb.addWorksheet('Truck Load');
    ws.addRows(wsData as any[]);
    wb.xlsx.writeBuffer().then((buf) => {
      const blob = new Blob([buf], { type: 'application/octet-stream' });
      FileSaver.saveAs(blob, `Truck_Load_Report_${new Date().toISOString().slice(0, 10)}.xlsx`);
    });
  }

  exportToExcelPivotStyle(): void {
    // Group and pivot the data
    const productSet = new Set<string>();
    const grouped: Record<string, any> = {};

    this.groupedLoadSummary.rows.forEach((row) => {
      productSet.add(row.product);
      const key = `${row.truckNo}-${row.dropOff}`;
      if (!grouped[key]) {
        grouped[key] = {
          'Loading Date': '29.03.2025', // example static or dynamic
          'Truck Number': row.truckNo,
          'Drop-off Location': row.dropOff,
          'Transport Vendor Name': 'CHHAY Y',
          'Transport Vendor Code': 'V_100569',
          Trip: 'LK1',
          'Distributor Code': 'AUTO',
          'Distributor Name': row.dropOff,
          'Amount of Pallets': 1, // mock or dynamic
          'SO Number': '-',
          'Date of SO': '28.03.2025',
          Shift: 'Shift II',
        };
      }
      grouped[key][row.product] = row.qty;
    });

    const headers = [
      'Loading Date',
      'Transport Vendor Name',
      'Transport Vendor Code',
      'Trip',
      'Truck Number',
      'Distributor Code',
      'Distributor Name',
      ...Array.from(productSet).sort(),
      'Amount of Pallets',
      'SO Number',
      'Date of SO',
      'Shift',
    ];

    const wb = new ExcelJS.Workbook();
    const ws = wb.addWorksheet('Truck Load Pivot Report');
    ws.addRow(headers);
    Object.values(grouped).forEach((row: any) => {
      ws.addRow(headers.map((h) => row[h] ?? ''));
    });
    // Style header
    ws.getRow(1).eachCell((cell) => {
      cell.font = { bold: true };
      cell.fill = { type: 'pattern', pattern: 'solid', fgColor: { argb: 'FFDCE6F1' } };
    });
    wb.xlsx.writeBuffer().then((buf) => {
      const blob = new Blob([buf], {
        type: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
      });
      FileSaver.saveAs(blob, 'truck_load_pivot_report.xlsx');
    });
  }
}
