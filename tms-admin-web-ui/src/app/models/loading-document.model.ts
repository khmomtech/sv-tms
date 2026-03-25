export type LoadingDocumentType = 'INVOICE' | 'PACKING_LIST' | 'PROOF_OF_DELIVERY' | 'OTHER';

export interface LoadingDocument {
  id: number;
  documentType: LoadingDocumentType;
  fileName: string;
  fileUrl: string;
  mimeType?: string | null;
  uploadedAt?: string;
}
