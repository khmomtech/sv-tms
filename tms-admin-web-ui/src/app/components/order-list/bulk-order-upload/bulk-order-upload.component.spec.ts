import { Workbook } from 'exceljs';

import { BulkOrderUploadComponent } from './bulk-order-upload.component';

describe('BulkOrderUploadComponent', () => {
  let component: BulkOrderUploadComponent;
  const translations: Record<string, string> = {
    'bulkOrderUpload.field_labels.customer_code': 'Customer code',
    'bulkOrderUpload.messages.cors_blocked':
      'Upload was blocked by browser/API access rules (CORS or origin mismatch).',
    'bulkOrderUpload.messages.internal_error':
      'Upload failed because the server hit an internal error. Nothing was saved. Check backend logs and try again.',
    'bulkOrderUpload.messages.internal_error_with_detail':
      'Upload failed before saving any data. The server reported: {{message}}',
    'bulkOrderUpload.messages.validation_issue_with_detail':
      'Upload was blocked by template, row, or master-data validation. {{message}}',
    'bulkOrderUpload.messages.validation_issue_fallback':
      'Upload was blocked by template, row, or master-data validation. Nothing was saved.',
    'bulkOrderUpload.errors.missing_from_destination': 'Missing fromDestination',
    'bulkOrderUpload.errors.missing_uom': 'Missing UoM',
  };
  const translateStub = {
    instant: (key: string, params?: Record<string, unknown>) => {
      if (key === 'bulkOrderUpload.value_label' && params?.['value']) {
        return `Value: ${params['value']}.`;
      }
      if (translations[key]) {
        return translations[key].replace(/\{\{(\w+)\}\}/g, (_, token) =>
          String(params?.[token] ?? `{{${token}}}`),
        );
      }
      return key;
    },
  };

  beforeEach(() => {
    component = new BulkOrderUploadComponent({} as any, translateStub as any);
  });

  it('groups rows using truckTripCount to match backend import behavior', () => {
    component.parsedRows = [
      {
        rowNumber: 2,
        deliveryDate: '27.01.2026',
        customerCode: 'C1000023',
        trackingNo: 'CA227.01.2026',
        tripNo: '1',
        truckNumber: '3E-0293',
        truckTripCount: '1',
        fromDestination: 'KB',
        toDestination: 'CA2',
        itemCode: 'CPD000011',
        itemName: 'Water',
        qty: 100,
        uom: 'Cases',
        uoMPallet: '8',
        loadingPlace: 'KB',
        status: 'PENDING',
      },
      {
        rowNumber: 3,
        deliveryDate: '27.01.2026',
        customerCode: 'C1000023',
        trackingNo: 'CA227.01.2026',
        tripNo: '1',
        truckNumber: '3E-0116',
        truckTripCount: '2',
        fromDestination: 'KB',
        toDestination: 'CA2',
        itemCode: 'CPD000011',
        itemName: 'Water',
        qty: 120,
        uom: 'Cases',
        uoMPallet: '8',
        loadingPlace: 'KB',
        status: 'PENDING',
      },
    ];

    component.groupTrips();

    expect(component.groupedTrips.length).toBe(2);
    expect(component.groupedTrips.map((trip) => trip.truckTripCount)).toEqual(['1', '2']);
  });

  it('extracts string-based server issues without crashing error grouping', () => {
    const issues = (component as any).extractServerIssues([
      'Invalid template headers. Please use the official template.',
    ]);

    expect(issues.importErrors).toEqual([]);
    expect(issues.messages).toEqual([
      'Invalid template headers. Please use the official template.',
    ]);
  });

  it('formats backend fields into readable user-facing problems', () => {
    const readable = component.getReadableServerProblem({
      row: 4,
      groupKey: '27.01.2026_C1000023_CA2_3',
      field: 'customerCode',
      value: 'C1000023',
      message: 'Customer not found',
    });

    expect(readable).toBe('Customer code: Customer not found. Value: C1000023.');
  });

  it('treats generic 500 responses with master-data details as validation-style failures', () => {
    const message = (component as any).buildFriendlyUploadError(
      { status: 500, error: null } as any,
      { message: 'Item not found' },
      ['Item not found'],
    );

    expect(message).toBe(
      'Upload was blocked by template, row, or master-data validation. Item not found',
    );
  });

  it('suppresses noisy generic unexpected-error text when no useful detail exists', () => {
    const message = (component as any).buildFriendlyUploadError(
      { status: 500, error: null } as any,
      { message: 'An unexpected error occurred' },
      [],
    );

    expect(message).toBe(
      'Upload failed because the server hit an internal error. Nothing was saved. Check backend logs and try again.',
    );
  });

  it('filters generic server messages out of the validation summary panel', () => {
    component.serverMessages = ['An unexpected error occurred', 'Item not found'];

    expect(component.filteredServerMessages).toEqual(['Item not found']);
    expect(component.hasStructuredServerFeedback).toBeTrue();
  });

  it('formats DeliveryDate cells as dd.MM.yyyy during extraction', async () => {
    const workbook = new Workbook();
    const worksheet = workbook.addWorksheet('Orders');
    worksheet.addRow([
      'DeliveryDate',
      'CustomerCode',
      'TrackingNo',
      'TripNo',
      'TruckNumber',
      'TruckTripCount',
      'FromDestination',
      'ToDestination',
      'ItemCode',
      'ItemName',
      'Qty',
      'UoM',
      'UoMPallet',
      'LoadingPlace',
      'Status',
    ]);
    worksheet.addRow([
      new Date(2026, 0, 27),
      'C1000023',
      'CA227.01.2026',
      '1',
      '3E-0293',
      '1',
      'KB',
      'CA2',
      'CPD000011',
      'Water',
      528,
      'Cases',
      '8',
      'KB',
      'PENDING',
    ]);

    const buffer = await workbook.xlsx.writeBuffer();
    const file = new File([buffer], 'transport-order-template.xlsx', {
      type: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
    });

    const rows = await (component as any).extractRowsFromFile(file);

    expect(rows).not.toBeNull();
    expect(rows[0]['DeliveryDate']).toBe('27.01.2026');
  });

  it('accepts files when required headers are present in a different order', async () => {
    const workbook = new Workbook();
    const worksheet = workbook.addWorksheet('Orders');
    worksheet.addRow([
      'DeliveryDate',
      'CustomerCode',
      'TripNo',
      'TrackingNo',
      'TruckNumber',
      'TruckTripCount',
      'FromDestination',
      'ToDestination',
      'ItemCode',
      'ItemName',
      'Qty',
      'UoM',
      'UoMPallet',
      'LoadingPlace',
      'Status',
    ]);
    worksheet.addRow([
      '27.01.2026',
      'C1000023',
      '1',
      'CA227.01.2026',
      '3E-0293',
      '1',
      'KB',
      'CA2',
      'CPD000011',
      'Water',
      528,
      'Cases',
      '8',
      'KB',
      'PENDING',
    ]);

    const buffer = await workbook.xlsx.writeBuffer();
    const file = new File([buffer], 'transport-order-template.xlsx', {
      type: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
    });

    const rows = await (component as any).extractRowsFromFile(file);

    expect(rows).not.toBeNull();
    expect(rows[0]['TripNo']).toBe('1');
    expect(rows[0]['TrackingNo']).toBe('CA227.01.2026');
  });

  it('maps Excel headers to the correct columns without a one-column shift', async () => {
    const workbook = new Workbook();
    const worksheet = workbook.addWorksheet('Orders');
    worksheet.addRow([
      'DeliveryDate',
      'CustomerCode',
      'TrackingNo',
      'TruckTripCount',
      'TruckNumber',
      'TripNo',
      'FromDestination',
      'ToDestination',
      'ItemCode',
      'ItemName',
      'Qty',
      'UoM',
      'UoMPallet',
      'LoadingPlace',
      'Status',
    ]);
    worksheet.addRow([
      '07.04.2026',
      'C1000023',
      'KDL107.04.2026C1000023',
      1,
      '3B-9917',
      'KB',
      'PHN',
      'KDL1',
      'CPD000067',
      'CAMBODIA BEER LITE CAN 330ML NCP',
      1200,
      'Cases',
      8,
      'W2',
      'PENDING',
    ]);

    const buffer = await workbook.xlsx.writeBuffer();
    const file = new File([buffer], 'transport-order-template.xlsx', {
      type: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
    });

    await (component as any).handleSelectedFile(file);

    expect(component.hasValidationErrors).toBeFalse();
    expect(component.parsedRows[0].deliveryDate).toBe('07.04.2026');
    expect(component.parsedRows[0].truckTripCount).toBe('1');
    expect(component.parsedRows[0].truckNumber).toBe('3B-9917');
    expect(component.parsedRows[0].tripNo).toBe('KB');
    expect(component.parsedRows[0].qty).toBe(1200);
    expect(component.parsedRows[0].status).toBe('PENDING');
  });

  it('marks rows invalid when backend-required client fields are missing', async () => {
    const workbook = new Workbook();
    const worksheet = workbook.addWorksheet('Orders');
    worksheet.addRow([
      'DeliveryDate',
      'CustomerCode',
      'TrackingNo',
      'TripNo',
      'TruckNumber',
      'TruckTripCount',
      'FromDestination',
      'ToDestination',
      'ItemCode',
      'ItemName',
      'Qty',
      'UoM',
      'UoMPallet',
      'LoadingPlace',
      'Status',
    ]);
    worksheet.addRow([
      '27.01.2026',
      'C1000023',
      'CA227.01.2026',
      '1',
      '3E-0293',
      '1',
      '',
      'CA2',
      'CPD000011',
      'Water',
      528,
      '',
      '8',
      'KB',
      '',
    ]);

    const buffer = await workbook.xlsx.writeBuffer();
    const file = new File([buffer], 'transport-order-template.xlsx', {
      type: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
    });

    await (component as any).handleSelectedFile(file);

    expect(component.hasValidationErrors).toBeTrue();
    expect(component.showPreview).toBeTrue();
    expect(component.parsedRows[0].error).toContain('Missing fromDestination');
    expect(component.parsedRows[0].error).toContain('Missing UoM');
    expect(component.parsedRows[0].status).toBe('PENDING');
    expect(component.parsedRows[0].error).not.toContain('Missing status');
  });

  it('defaults blank import status values to PENDING', async () => {
    const workbook = new Workbook();
    const worksheet = workbook.addWorksheet('Orders');
    worksheet.addRow([
      'DeliveryDate',
      'CustomerCode',
      'TrackingNo',
      'TruckTripCount',
      'TruckNumber',
      'TripNo',
      'FromDestination',
      'ToDestination',
      'ItemCode',
      'ItemName',
      'Qty',
      'UoM',
      'UoMPallet',
      'LoadingPlace',
      'Status',
    ]);
    worksheet.addRow([
      '07.04.2026',
      'C1000023',
      'KDL107.04.2026C1000023',
      1,
      '3B-9917',
      'KB',
      'PHN',
      'KDL1',
      'CPD000067',
      'CAMBODIA BEER LITE CAN 330ML NCP',
      1200,
      'Cases',
      8,
      'W2',
      '',
    ]);

    const buffer = await workbook.xlsx.writeBuffer();
    const file = new File([buffer], 'transport-order-template.xlsx', {
      type: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
    });

    await (component as any).handleSelectedFile(file);

    expect(component.hasValidationErrors).toBeFalse();
    expect(component.parsedRows[0].status).toBe('PENDING');
  });

  it('builds upload success summary from validated preview data', () => {
    component.selectedFile = new File(['ok'], 'orders.xlsx');
    component.validationSummary = {
      totalRows: 3,
      validRows: 3,
      invalidRows: 0,
      totalTrips: 2,
      uniqueCustomers: 1,
      totalQty: 120,
      issueCounts: {},
    };

    const summary = (component as any).buildUploadResultSummary();

    expect(summary).toEqual({
      fileName: 'orders.xlsx',
      importedRows: 3,
      importedTrips: 2,
      importedCustomers: 1,
      importedQty: 120,
    });
  });

  it('turns raw 500 upload failures into readable user messages', () => {
    const message = (component as any).buildFriendlyUploadError(
      {
        status: 500,
        error: 'Internal Server Error',
      },
      null,
      [],
    );

    expect(message).toBe(
      'Upload failed before saving any data. The server reported: Internal Server Error',
    );
  });

  it('turns cors-style 403 upload failures into actionable guidance', () => {
    const message = (component as any).buildFriendlyUploadError(
      {
        status: 403,
        error: 'Invalid CORS request',
      },
      null,
      ['Invalid CORS request'],
    );

    expect(message).toContain('CORS');
    expect(message).toContain('origin mismatch');
  });
});
