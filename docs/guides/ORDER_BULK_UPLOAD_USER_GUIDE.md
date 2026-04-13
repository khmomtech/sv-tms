# Order Bulk Upload User Guide

This guide explains how the `/orders/upload` module works in `tms-admin-web-ui`, what the Excel file must contain, how rows are grouped into transport orders, and what errors block import.

## Route

- Frontend route: `/orders/upload`
- Frontend component: `tms-admin-web-ui/src/app/components/order-list/bulk-order-upload/bulk-order-upload.component.ts`
- Backend endpoint: `/api/admin/transportorders/import-bulk`

## Purpose

The bulk upload screen imports transport orders from the official Excel template. Each uploaded file is validated on both the frontend and backend before anything is saved.

The import is all-or-nothing:

- If any validation error exists, nothing is saved.
- If validation passes, the backend creates transport orders and order item lines from the grouped rows.

## Required Excel Template

Use the official template:

- `tms-admin-web-ui/src/assets/templates/transport-order-template.xlsx`

Required columns and expected order:

1. `DeliveryDate`
2. `CustomerCode`
3. `TrackingNo`
4. `TripNo`
5. `TruckNumber`
6. `TruckTripCount`
7. `FromDestination`
8. `ToDestination`
9. `ItemCode`
10. `ItemName`
11. `Qty`
12. `UoM`
13. `UoMPallet`
14. `LoadingPlace`
15. `Status`

Notes:

- File type must be `.xlsx`
- File size limit is `5 MB`
- Header order must match the official template
- Empty trailing rows are ignored

## Frontend Flow

### 1. File selection

The user selects or drags an Excel file into the upload screen.

The frontend checks:

- file extension is valid
- MIME type looks like an Excel file
- file size is within limit

### 2. Workbook parsing

The component reads the first worksheet using `exceljs`.

It validates:

- worksheet exists
- required columns exist
- columns are in the official order

If this fails, upload is blocked before the file is sent to the backend.

### 3. Row normalization

Each row is converted into a frontend `ParsedRow` with:

- Excel row number
- delivery date
- customer code
- tracking number
- trip number
- truck number
- truck trip count
- from/to destination
- item code and item name
- quantity
- units
- loading place
- status

Dates are normalized to `dd.MM.yyyy`.

### 4. Client-side validation

The frontend marks rows invalid when:

- `DeliveryDate` is missing or not `dd.MM.yyyy`
- `CustomerCode` is missing
- `TripNo` is missing
- `TruckNumber` is missing
- `TruckTripCount` is missing or not a whole number
- `ToDestination` is missing
- `ItemCode` is missing
- `ItemName` is missing
- `Qty <= 0`

If any row is invalid:

- the row is highlighted in preview
- upload button is disabled

### 5. Preview and grouping

The UI shows:

- summary counts
- parsed row preview
- grouped upload batches

The grouped batch preview follows backend import logic.

## Grouping Logic

Rows are grouped by:

- `DeliveryDate`
- `CustomerCode`
- `ToDestination`
- `TruckTripCount`

Group key format:

`DeliveryDate_CustomerCode_ToDestination_TruckTripCount`

This means:

- rows with the same values above become one transport order
- rows inside the same group become item lines on that order
- changing only `ItemCode` or `Qty` does not create a new order

Important:

- `TripNo` is stored and displayed
- `TruckTripCount` is what currently splits groups for import behavior

## Backend Flow

The backend controller accepts the uploaded file and forwards it to `TransportOrderService.importBulkOrders(...)`.

The backend then runs two phases.

### Phase 1: validation only

The backend:

- validates row count limit
- validates template headers
- parses non-empty rows
- builds import groups
- validates each group and each item row

Lookup validation includes:

- customer exists
- vehicle exists
- source address exists
- destination address exists
- item code exists
- quantity is valid
- status is valid
- generated order reference does not already exist

If any error exists:

- backend returns `422 Unprocessable Entity`
- nothing is saved

### Phase 2: persistence

Only after all rows pass validation, the backend starts writing data.

For each valid group, it creates:

- one transport order header
- one or more order item/detail records

If vehicle-driver mapping exists, assignment-related data may also be attached.

## Example Using Sample File

Sample file:

- `/Users/sotheakh/Documents/SV Document/uploads/File Import 27-Jan-26 (2)1 2.xlsx`

This file contains 13 data rows and produces 10 groups.

### Example group

Excel rows 4 and 5:

- same `DeliveryDate = 27.01.2026`
- same `CustomerCode = C1000023`
- same `ToDestination = CA2`
- same `TruckTripCount = 3`

These two rows become:

- 1 transport order
- 2 item lines

### Full group count from the sample file

1. `27.01.2026_C1000023_CA2_1`
2. `27.01.2026_C1000023_CA2_2`
3. `27.01.2026_C1000023_CA2_3`
4. `27.01.2026_C1000023_CA2_4`
5. `27.01.2026_C1000023_CA2_5`
6. `27.01.2026_C1000023_CA2_6`
7. `27.01.2026_C1000023_CA2_7`
8. `27.01.2026_C1000023_CA3_8`
9. `27.01.2026_C1000023_CA3_9`
10. `27.01.2026_C1000023_CA3_10`

If backend reference data is valid, the upload would create:

- 10 transport orders
- 13 order item lines

## Common Failure Cases

Upload is blocked when:

- wrong file type
- wrong header names
- wrong header order
- bad date format
- missing required fields
- invalid `TruckTripCount`
- invalid quantity
- unknown customer
- unknown vehicle
- unknown source or destination
- unknown item code
- invalid status
- duplicate generated order reference

## Error Handling

The frontend handles two backend error shapes:

- structured `ImportError[]`
- plain string/template validation messages

The UI displays:

- grouped errors by import group
- row-level error messages
- template/header messages
- CSV export for error rows

## Operational Rules

- Use the official template only
- Do not reorder columns
- Ensure master data already exists in the database
- Treat one grouped batch as one order, not one row
- Fix every validation error before retrying upload

## Files Involved

- `tms-admin-web-ui/src/app/features/orders/orders.routes.ts`
- `tms-admin-web-ui/src/app/components/order-list/bulk-order-upload/bulk-order-upload.component.ts`
- `tms-admin-web-ui/src/app/components/order-list/bulk-order-upload/bulk-order-upload.component.html`
- `tms-admin-web-ui/src/app/components/order-list/bulk-order-upload/bulk-order-upload.component.spec.ts`
- `tms-core-api/src/main/java/com/svtrucking/logistics/controller/admin/TransportOrderController.java`
- `tms-core-api/src/main/java/com/svtrucking/logistics/service/TransportOrderService.java`
