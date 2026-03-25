export interface DriverComplianceDto {
  licenseStatus?: string;
  idCardStatus?: string;
  complianceStatus?: string;
  documentExpiryStatus?: string;
  driverId: number;
  name: string;
  openIssues: number;
}
