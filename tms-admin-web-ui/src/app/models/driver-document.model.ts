export interface DriverDocument {
  id?: number;
  driverId: number;
  driverName?: string; // Added for all-documents view
  name: string;
  category: string;
  description?: string;
  fileUrl?: string;
  fileName?: string;
  fileSize?: number;
  mimeType?: string;
  expiryDate?: string;
  isRequired?: boolean;
  notes?: string;
  uploadDate: string;
  uploadedBy?: string;
  createdAt?: string;
  updatedAt?: string;
  updatedBy?: string;
  status?: 'active' | 'expired' | 'archived';
}
