import { saveAs } from 'file-saver';
import * as XLSX from 'xlsx';
import jsPDF from 'jspdf';
import 'jspdf-autotable';

export function generateXlsx(data: any[], filename: string) {
  const ws = XLSX.utils.json_to_sheet(data);
  const wb = XLSX.utils.book_new();
  XLSX.utils.book_append_sheet(wb, ws, 'Checks');
  const wbout = XLSX.write(wb, { bookType: 'xlsx', type: 'array' });
  const blob = new Blob([wbout], { type: 'application/octet-stream' });
  saveAs(blob, filename);
}

export function generatePdf(data: any[], filename: string) {
  const doc = new jsPDF({ unit: 'pt', format: 'A4' });
  const columns = Object.keys(data[0] || {}).map(k => ({ header: k, dataKey: k }));
  (doc as any).autoTable({
    head: [columns.map(c => c.header)],
    body: data.map(row => Object.values(row)),
    startY: 40,
  });
  doc.save(filename);
}
