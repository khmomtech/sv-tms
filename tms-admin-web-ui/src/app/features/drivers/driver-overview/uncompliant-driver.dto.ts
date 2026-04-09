export interface UncompliantDriverDto {
  driverId: number;
  driverName: string;
  phone?: string;
  licenseStatus?: string;
  idCardStatus?: string;
  expiredDocumentCount?: number;
  expiredDocuments?: string;
  openIssues: number;
}
