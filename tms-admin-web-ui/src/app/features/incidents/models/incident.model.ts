/**
 * Incident Management Models
 * Aligned with backend IncidentDto
 */

export interface Incident {
  id?: number;
  code?: string;
  title: string;
  description: string;
  incidentStatus: IncidentStatus;
  incidentGroup: IncidentGroup;
  incidentType: IncidentType;
  severity: IssueSeverity;
  source?: IncidentSource;

  // Related entities
  driverId?: number;
  driverName?: string;
  vehicleId?: number;
  vehiclePlate?: string;
  tripId?: number;
  tripReference?: string;

  // Location (aligned with backend locationText/locationLat/locationLng)
  locationText?: string;
  locationLat?: number;
  locationLng?: number;
  location?: string; // Deprecated: Use locationText instead

  // Reporting
  reportedByUserId?: number;
  reportedByUsername?: string;
  reportedAt?: string;
  slaDueAt?: string;

  // Assignment
  assignedToId?: number;
  assignedToName?: string;

  // Resolution
  resolutionNotes?: string;
  resolvedAt?: string;

  // Attachments
  photoUrls?: string[];
  photoCount?: number;

  // Case linking (aligned with backend)
  linkedToCase?: boolean;
  caseId?: number;
  caseCode?: string;

  // Audit
  createdAt?: string;
  updatedAt?: string;
  isDeleted?: boolean;
}

export enum IncidentStatus {
  NEW = 'NEW',
  VALIDATED = 'VALIDATED',
  UNDER_INVESTIGATION = 'UNDER_INVESTIGATION',
  RESOLVED = 'RESOLVED',
  CLOSED = 'CLOSED',
  ESCALATED = 'ESCALATED',
}

export enum IncidentGroup {
  TRAFFIC = 'TRAFFIC', // Speeding, harsh braking, etc.
  BEHAVIOR = 'BEHAVIOR', // Driver conduct, compliance issues
  CUSTOMER = 'CUSTOMER', // Customer complaints
  ACCIDENT = 'ACCIDENT', // Traffic accidents, collisions
  VEHICLE = 'VEHICLE', // Mechanical, maintenance-related issues
  DRIVER = 'DRIVER',
}

export enum IncidentType {
  // Traffic-related
  SPEEDING = 'SPEEDING',
  HARSH_BRAKING = 'HARSH_BRAKING',
  HARSH_ACCELERATION = 'HARSH_ACCELERATION',
  SHARP_CORNERING = 'SHARP_CORNERING',
  WRONG_ROUTE = 'WRONG_ROUTE',

  // Behavior-related
  UNPROFESSIONAL_CONDUCT = 'UNPROFESSIONAL_CONDUCT',
  POLICY_VIOLATION = 'POLICY_VIOLATION',
  UNAUTHORIZED_STOP = 'UNAUTHORIZED_STOP',
  MISSED_SCHEDULE = 'MISSED_SCHEDULE',

  // Customer-related
  CUSTOMER_COMPLAINT = 'CUSTOMER_COMPLAINT',
  DAMAGE_CLAIM = 'DAMAGE_CLAIM',
  SERVICE_QUALITY_ISSUE = 'SERVICE_QUALITY_ISSUE',

  // Accident-related
  COLLISION = 'COLLISION',
  PROPERTY_DAMAGE = 'PROPERTY_DAMAGE',
  INJURY = 'INJURY',

  // Vehicle-related
  MECHANICAL_FAILURE = 'MECHANICAL_FAILURE',
  BREAKDOWN = 'BREAKDOWN',
  MAINTENANCE_DUE = 'MAINTENANCE_DUE',

  // Other
  OTHER = 'OTHER',
}

export enum IncidentSource {
  DRIVER_REPORT = 'DRIVER_REPORT',
  CUSTOMER_REPORT = 'CUSTOMER_REPORT',
  DISPATCHER_REPORT = 'DISPATCHER_REPORT',
  SYSTEM_ALERT = 'SYSTEM_ALERT',
  TELEMATICS = 'TELEMATICS',
}

export enum IssueSeverity {
  LOW = 'LOW',
  MEDIUM = 'MEDIUM',
  HIGH = 'HIGH',
  CRITICAL = 'CRITICAL',
}

export interface IncidentFilter {
  status?: IncidentStatus;
  group?: IncidentGroup;
  severity?: IssueSeverity;
  driverId?: number;
  vehicleId?: number;
  reportedAfter?: string;
  reportedBefore?: string;
  search?: string;
}

export interface IncidentStatistics {
  total: number;
  byStatus: Record<IncidentStatus, number>;
  byGroup: Record<IncidentGroup, number>;
  bySeverity: Record<IssueSeverity, number>;
}

/**
 * Case Management Models
 * Aligned with backend CaseDto
 */

export interface Case {
  id?: number;
  code?: string;
  title: string;
  description: string;
  status: CaseStatus;
  severity: IssueSeverity;
  category: CaseCategory;
  caseStatus: CaseStatus; // Alias for status
  caseCategory: CaseCategory; // Alias for category
  resolution?: string;
  driverId?: number;
  driverName?: string;
  vehicleId?: number;
  vehiclePlate?: string;
  assignedToUserId?: number;
  assignedToId?: number; // Alias for assignedToUserId
  assignedToUsername?: string;
  assignedTeam?: string;
  createdByUserId?: number;
  createdByUsername?: string;
  createdAt?: string;
  updatedAt?: string;
  closedAt?: string;
  resolvedAt?: string;
  slaTargetAt?: string;
  incidentCount?: number;
  taskCount?: number;
  attachmentCount?: number;
  timelineEntryCount?: number;
  incidents?: Incident[];
  tasks?: CaseTask[];
  attachments?: CaseAttachment[];
  timeline?: CaseTimelineEntry[];
  isDeleted?: boolean;
}

export enum CaseStatus {
  OPEN = 'OPEN',
  INVESTIGATION = 'INVESTIGATION',
  PENDING_APPROVAL = 'PENDING_APPROVAL',
  CLOSED = 'CLOSED',
}

export enum CaseCategory {
  ACCIDENT = 'ACCIDENT',
  THEFT = 'THEFT',
  DAMAGE = 'DAMAGE',
  COMPLAINT = 'COMPLAINT',
  VIOLATION = 'VIOLATION',
  FRAUD = 'FRAUD',
  OTHER = 'OTHER',
}

export interface CaseTask {
  id?: number;
  caseId?: number;
  title: string;
  description?: string;
  status?: CaseTaskStatus;
  taskStatus?: CaseTaskStatus; // Alias for status
  assignedToUserId?: number;
  assignedToUsername?: string;
  dueDate?: string; // deprecated client alias
  dueAt?: string;
  completedAt?: string;
  createdAt?: string;
  updatedAt?: string;
}

export enum CaseTaskStatus {
  PENDING = 'PENDING',
  IN_PROGRESS = 'IN_PROGRESS',
  COMPLETED = 'COMPLETED',
  CANCELLED = 'CANCELLED',
}

export interface CaseAttachment {
  id?: number;
  caseId: number;
  fileName: string;
  fileUrl: string;
  fileType: string;
  fileSize?: number;
  uploadedByUserId?: number;
  uploadedByUsername?: string;
  uploadedAt?: string;
}

export interface CaseTimelineEntry {
  id?: number;
  caseId: number;
  eventType: string;
  description: string;
  performedByUserId?: number;
  performedByUsername?: string;
  eventData?: any;
  createdAt?: string;
}

export interface CaseFilter {
  status?: CaseStatus;
  severity?: IssueSeverity;
  category?: CaseCategory;
  assignedToUserId?: number;
  driverId?: number;
  vehicleId?: number;
  createdAfter?: string;
  createdBefore?: string;
  search?: string;
}

export interface CaseStatistics {
  total: number;
  open: number;
  investigation: number;
  pending_approval: number;
  closed: number;
}

/**
 * API Response wrapper
 */
export interface ApiResponse<T> {
  success: boolean;
  message: string;
  data: T;
  timestamp: string;
  requestId?: string;
}

export interface PagedResponse<T> {
  content: T[];
  pageable: {
    pageNumber: number;
    pageSize: number;
    sort: {
      sorted: boolean;
      unsorted: boolean;
      empty: boolean;
    };
    offset: number;
    paged: boolean;
    unpaged: boolean;
  };
  totalElements: number;
  totalPages: number;
  last: boolean;
  numberOfElements: number;
  first: boolean;
  size: number;
  number: number;
  sort: {
    sorted: boolean;
    unsorted: boolean;
    empty: boolean;
  };
  empty: boolean;
}
