export interface Document {
  id: number;
  documentType: string;
  fileName?: string;
  documentName?: string;
  fileUrl?: string;
  docNumber?: string;
  documentNumber?: string;
  issueDate?: string;
  expiryDate?: string;
  uploadedDate?: string;
  approved?: boolean;
  updatedAt?: string;
  updatedBy?: string;
  notes?: string;
  vehicleId?: number; // Foreign key reference to Vehicle
  vehicleName?: string;
  licensePlate?: string;
  documentUrl?: string;
}

export type VehicleDocument = Document;
