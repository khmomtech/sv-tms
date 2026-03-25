export interface InvoiceDto {
  id: number;
  orderId: number;
  invoiceDate: string; // ISO Date String
  totalAmount: number;
  paymentStatus: 'PAID' | 'UNPAID' | 'PARTIAL';
}
