export type SafetyResult = 'PASS' | 'FAIL';

export interface PreLoadingSafetyCheckRequest {
  dispatchId: number;
  driverPpeOk: boolean;
  fireExtinguisherOk: boolean;
  wheelChockOk: boolean;
  truckLeakageOk: boolean;
  truckCleanOk: boolean;
  truckConditionOk: boolean;
  result: SafetyResult;
  failReason?: string | null;
  checkedByUserId?: number | null;
  checkedAt?: string;
}

export interface PreLoadingSafetyCheck {
  id: number;
  dispatchId: number;
  driverPpeOk: boolean;
  fireExtinguisherOk: boolean;
  wheelChockOk: boolean;
  truckLeakageOk: boolean;
  truckCleanOk: boolean;
  truckConditionOk: boolean;
  result: SafetyResult;
  failReason?: string | null;
  checkedByUserId?: number | null;
  checkedByUsername?: string | null;
  checkedAt?: string;
  createdDate?: string;
}
