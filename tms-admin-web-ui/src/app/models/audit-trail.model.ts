export interface AuditTrail {
  id: number;
  userId: number;
  username: string;
  action: string;
  resourceType: string;
  resourceId: number;
  resourceName: string;
  timestamp: string;
  details: string;
  ipAddress: string;
  userAgent: string;
}
