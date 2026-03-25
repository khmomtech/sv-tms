# Migrate from `xlsx` to `exceljs`

This guide documents replacing `xlsx` (SheetJS) usages with `exceljs` for safer, consistent Excel processing across the Angular app.

- Target modules (read/import):
  - `src/app/pages/bulk-dispatch-upload/bulk-dispatch-upload.component.ts`
  - `src/app/components/order-list/bulk-order-upload/bulk-order-upload.component.ts`
  - `src/app/components/so-upload/so-upload.component.ts` (import side)
- Target modules (write/export):
  - `src/app/components/so-upload/so-upload.component.ts` (several write helpers)

## Rationale
- Reduce dependency risk surface by standardizing on a single library already used elsewhere in the app (`exceljs`).
- Avoid known security advisories affecting older `xlsx` versions.

## Install
`exceljs` is already present. If missing in future checkouts:

```bash
cd tms-frontend
npm i exceljs
```

## Reading files: `xlsx` → `exceljs`

Old (SheetJS):
```ts
import * as XLSX from 'xlsx';

const data = await file.arrayBuffer();
const wb = XLSX.read(data, { type: 'array' });
const ws = wb.Sheets[wb.SheetNames[0]];
const rows = XLSX.utils.sheet_to_json(ws, { defval: '' });
```

New (ExcelJS):
```ts
import { Workbook } from 'exceljs';

const buffer = await file.arrayBuffer();
const wb = new Workbook();
await wb.xlsx.load(buffer);
const ws = wb.worksheets[0];

// header-based mapping (row 1 as headers)
const header = (ws.getRow(1).values as Array<string | null | undefined>)
  .map(h => (typeof h === 'string' ? h.trim() : (h ?? '').toString().trim()));

const rows: any[] = [];
ws.eachRow((row, rowNumber) => {
  if (rowNumber === 1) return;
  const obj: any = {};
  for (let c = 1; c < header.length; c++) {
    const key = header[c];
    if (!key) continue;
    const cell = row.getCell(c).value;
    obj[key] = (cell as any)?.text ?? (cell as any)?.result ?? cell ?? '';
  }
  rows.push(obj);
});
```

Notes:
- ExcelJS is 1-based for rows/columns. `Row.values[0]` is a placeholder.
- Coerce cell values using `text/result` when rich types are returned.

## Writing files: `xlsx` → `exceljs`

Old (SheetJS):
```ts
const ws = XLSX.utils.json_to_sheet(data);
const wb = XLSX.utils.book_new();
XLSX.utils.book_append_sheet(wb, ws, 'Sheet1');
const buf = XLSX.write(wb, { bookType: 'xlsx', type: 'array' });
```

New (ExcelJS):
```ts
import { Workbook } from 'exceljs';

const wb = new Workbook();
const ws = wb.addWorksheet('Sheet1');

// Optional: set header row
ws.addRow(Object.keys(data[0] ?? {}));
for (const row of data) {
  ws.addRow(Object.values(row));
}

const buf = await wb.xlsx.writeBuffer();
```

## File download helper (unchanged)
Use existing blob download helpers:
```ts
const blob = new Blob([buf], { type: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet' });
const url = URL.createObjectURL(blob);
// anchor click or FileSaver
```

## Migration Steps
1. Replace `import * as XLSX from 'xlsx'` with `import { Workbook } from 'exceljs'`.
2. Switch read flows to `Workbook().xlsx.load(arrayBuffer)` and header-mapped parsing.
3. Convert write flows to ExcelJS worksheet creation + `writeBuffer()`.
4. Rebuild: `npm run build` and verify import flows manually.
5. After all call sites are migrated: remove `xlsx` and `@types/xlsx` from `package.json`, run `npm i`, and rebuild.

## Rollback
If issues arise, you can revert individual components to the previous commit (pre-migration) while keeping this guide for reference.

## Testing
- Add or update component tests to validate: header detection, numeric/date coercion, and empty-cell defaults.
- For large files, prefer integration testing with a small synthetic workbook to keep tests fast.
