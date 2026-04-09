import type { HttpErrorResponse } from '@angular/common/http';
// eslint-disable-next-line @typescript-eslint/consistent-type-imports
import { HttpClient } from '@angular/common/http';
import { HttpHeaders, HttpParams } from '@angular/common/http';
import { Injectable } from '@angular/core';
import type { Observable } from 'rxjs';
import { of, throwError } from 'rxjs';
import { catchError, map } from 'rxjs/operators';

import { environment } from '../environments/environment';
import type { ApiResponse } from '../models/api-response.model';
import type { DispatchStatusHistory } from '../models/dispatch-status-history.model';
import type { Dispatch } from '../models/dispatch.model';
import type { Driver } from '../models/driver.model';
import type { LoadProof } from '../models/load-proof.model';
import type { TransportOrder } from '../models/transport-order.model';
import type { OdometerLog } from '../models/odometer-log.model';
import type { FuelRequest } from '../models/fuel-request.model';
import type { CodSettlement } from '../models/cod-settlement.model';

// eslint-disable-next-line @typescript-eslint/consistent-type-imports
import { AuthService } from './auth.service';

interface PageResponse<T> {
  content: T[];
  totalElements: number;
  totalPages: number;
  number: number;
  size: number;
}

export interface DispatchActionMetadata {
  targetStatus: string;
  actionLabel: string;
  actionType?: string;
  iconName?: string;
  buttonColor?: string;
  requiresConfirmation?: boolean;
  requiresAdminApproval?: boolean;
  driverInitiated?: boolean;
  requiresInput?: boolean;
  validationMessage?: string;
  priority?: number;
  isDestructive?: boolean;
  allowedActorTypes?: string[];
  allowedForCurrentUser?: boolean;
  blockedReason?: string | null;
}

export interface DispatchStatusUpdateResponse {
  dispatchId: number;
  currentStatus: string;
  availableActions: DispatchActionMetadata[];
  canPerformActions: boolean;
  actionRestrictionMessage?: string | null;
  loadingTypeCode?: string;
  loadingTypeName?: string | null;
}

export interface PreEntrySafetyCheckUpsertRequest {
  dispatchId: number;
  vehicleId: number;
  driverId: number;
  warehouseCode?: string;
  remarks?: string;
  inspectionPhotoUrls?: string[];
  checkerSignatureUrl?: string;
  items: Array<{
    category: string;
    itemName: string;
    status: string;
    remarks?: string;
    photoUrl?: string;
  }>;
  [key: string]: any;
}

export interface SafetyEligibility {
  eligible: boolean;
  status?: string;
  message?: string;
  riskLevel?: string;
  safetyCheckId?: number;
}

@Injectable({
  providedIn: 'root',
})
export class DispatchService {
  private readonly apiUrl = `${environment.baseUrl}/api/admin/dispatches`;
  private readonly approvalsUrl = `${environment.baseUrl}/api/admin/dispatches/approvals`;
  private readonly closingUrl = `${environment.baseUrl}/api/admin/dispatches/closing`;

  constructor(
    private readonly http: HttpClient,
    private readonly authService: AuthService,
  ) {}

  // ===== Helpers =====
  private getHeaders(): HttpHeaders {
    const token = this.authService.getToken();
    return new HttpHeaders({
      'Content-Type': 'application/json',
      Authorization: `Bearer ${token}`,
    });
  }

  private getAuthHeaders(): HttpHeaders {
    const token = this.authService.getToken();
    return new HttpHeaders({
      Authorization: `Bearer ${token}`,
    });
  }

  private setIf(params: HttpParams, key: string, val?: string | number | null): HttpParams {
    if (val === undefined || val === null) return params;
    return params.set(key, String(val));
  }

  private handleError(error: HttpErrorResponse): Observable<never> {
    console.error('API Error:', error);
    // Rethrow the original HttpErrorResponse so callers can inspect status and server message
    return throwError(() => error);
  }

  // ===== Queries =====

  /** Get all dispatches (paged) */
  getAllDispatches(
    page: number = 0,
    size: number = 10,
  ): Observable<ApiResponse<PageResponse<Dispatch>>> {
    const params = new HttpParams().set('page', String(page)).set('size', String(size));
    return this.http
      .get<
        ApiResponse<PageResponse<Dispatch>>
      >(`${this.apiUrl}`, { headers: this.getHeaders(), params })
      .pipe(catchError(this.handleError));
  }

  /**
   * Filter dispatches by driverName/status/routeCode/free-text/date range (preferred).
   * Backend endpoint: GET /api/admin/dispatches/filter
   */
  filterDispatchesByDriverName(opts: {
    driverName?: string; // e.g. "Sok", "John"
    status?: string; // e.g. "IN_TRANSIT"
    routeCode?: string;
    q?: string; // free-text
    start?: string; // ISO: "YYYY-MM-DDTHH:mm:ss"
    end?: string; // ISO: "YYYY-MM-DDTHH:mm:ss"
    page?: number;
    size?: number;
  }): Observable<ApiResponse<PageResponse<Dispatch>>> {
    const { driverName, status, routeCode, q, start, end, page = 0, size = 10 } = opts;

    let params = new HttpParams().set('page', String(page)).set('size', String(size));

    if (driverName?.trim()) params = params.set('driverName', driverName.trim());
    if (status) params = params.set('status', status);
    if (routeCode?.trim()) params = params.set('routeCode', routeCode.trim());
    if (q?.trim()) params = params.set('q', q.trim());
    if (start) params = params.set('start', start);
    if (end) params = params.set('end', end);

    return this.http
      .get<ApiResponse<PageResponse<Dispatch>>>(`${this.apiUrl}/filter`, {
        headers: this.getHeaders(),
        params,
      })
      .pipe(catchError(this.handleError));
  }

  /** Get a single dispatch by id */
  getDispatchById(dispatchId: number): Observable<ApiResponse<Dispatch>> {
    return this.http
      .get<ApiResponse<Dispatch>>(`${this.apiUrl}/${dispatchId}`, {
        headers: this.getHeaders(),
      })
      .pipe(catchError(this.handleError));
  }

  /** Get backend-driven available actions for admin operations UI */
  getAvailableActions(dispatchId: number): Observable<ApiResponse<DispatchStatusUpdateResponse>> {
    return this.http
      .get<ApiResponse<DispatchStatusUpdateResponse>>(
        `${this.apiUrl}/${dispatchId}/available-actions`,
        {
          headers: this.getHeaders(),
        },
      )
      .pipe(
        catchError((error: HttpErrorResponse) => {
          // Backward compatibility and resilience:
          // fallback when admin endpoint is not yet deployed (404) or temporarily failing (5xx).
          if (error.status !== 404 && (error.status < 500 || error.status > 599)) {
            return this.handleError(error);
          }
          return this.http
            .get<
              ApiResponse<DispatchStatusUpdateResponse>
            >(`${environment.baseUrl}/api/driver/dispatches/${dispatchId}/available-actions`, { headers: this.getHeaders() })
            .pipe(
              catchError(() =>
                of({
                  success: true,
                  message: 'Available actions endpoint unavailable; fallback empty actions.',
                  data: {
                    dispatchId,
                    currentStatus: 'UNKNOWN',
                    availableActions: [],
                    canPerformActions: true,
                    actionRestrictionMessage: null,
                  },
                } as ApiResponse<DispatchStatusUpdateResponse>),
              ),
            );
        }),
      );
  }

  /**
   * Generic filter (overloaded).
   * New usage:    filterDispatches({ driverName?, vehicleId?, status?, routeCode?, q?, start?, end?, page?, size? })
   * Legacy usage: filterDispatches(driverId?, vehicleId?, status?, page?, size?)
   */
  filterDispatches(opts: {
    driverName?: string;
    vehicleId?: number;
    status?: string;
    routeCode?: string;
    q?: string;
    start?: string; // ISO datetime
    end?: string; // ISO datetime
    page?: number;
    size?: number;
    // NEW optional filters
    customerName?: string;
    toLocation?: string; // destination label/text
    truckPlate?: string;
    tripNo?: string;
  }): Observable<ApiResponse<any>>;
  filterDispatches(
    driverId?: number,
    vehicleId?: number,
    status?: string,
    page?: number,
    size?: number,
  ): Observable<ApiResponse<any>>;
  filterDispatches(
    a?:
      | number
      | {
          driverName?: string;
          vehicleId?: number;
          status?: string;
          routeCode?: string;
          q?: string;
          start?: string;
          end?: string;
          page?: number;
          size?: number;
          customerName?: string;
          toLocation?: string;
          truckPlate?: string;
          tripNo?: string;
        },
    b?: number,
    c?: string,
    d: number = 0,
    e: number = 10,
  ): Observable<ApiResponse<PageResponse<Dispatch>>> {
    let params = new HttpParams();

    if (typeof a === 'object' && a !== null) {
      // New-style call with object
      const {
        driverName,
        vehicleId,
        status,
        routeCode,
        q,
        start,
        end,
        page = 0,
        size = 10,
        customerName,
        toLocation,
        truckPlate,
        tripNo,
      } = a;

      params = params.set('page', String(page)).set('size', String(size));
      if (driverName?.trim()) params = params.set('driverName', driverName.trim());
      if (vehicleId != null) params = params.set('vehicleId', String(vehicleId));
      if (status) params = params.set('status', status);
      if (routeCode?.trim()) params = params.set('routeCode', routeCode.trim());
      if (q?.trim()) params = params.set('q', q.trim());
      if (start) params = params.set('start', start);
      if (end) params = params.set('end', end);
      if (customerName?.trim()) params = params.set('customerName', customerName.trim());
      if (toLocation?.trim()) params = params.set('destinationTo', toLocation.trim());
      if (truckPlate?.trim()) params = params.set('truckPlate', truckPlate.trim());
      if (tripNo?.trim()) params = params.set('tripNo', tripNo.trim());
    } else {
      // Legacy-style call with positional args
      const legacyDriverId = a as number | undefined;
      const vehicleId = b;
      const status = c;
      const page = d ?? 0;
      const size = e ?? 10;

      params = params.set('page', String(page)).set('size', String(size));
      if (legacyDriverId != null) params = params.set('driverId', String(legacyDriverId));
      if (vehicleId != null) params = params.set('vehicleId', String(vehicleId));
      if (status) params = params.set('status', status);
    }

    return this.http
      .get<ApiResponse<PageResponse<Dispatch>>>(`${this.apiUrl}/filter`, {
        headers: this.getHeaders(),
        params,
      })
      .pipe(catchError(this.handleError));
  }

  // ===== Approvals (KM/Fuel/COD) =====

  getOdometerLogs(dispatchId: number): Observable<ApiResponse<OdometerLog[]>> {
    const params = new HttpParams().set('dispatchId', String(dispatchId));
    return this.http
      .get<ApiResponse<OdometerLog[]>>(`${this.approvalsUrl}/odometer`, {
        headers: this.getHeaders(),
        params,
      })
      .pipe(catchError(this.handleError));
  }

  approveOdometer(id: number): Observable<ApiResponse<OdometerLog>> {
    return this.http
      .post<ApiResponse<OdometerLog>>(`${this.approvalsUrl}/odometer/${id}/approve`, null, {
        headers: this.getHeaders(),
      })
      .pipe(catchError(this.handleError));
  }

  rejectOdometer(id: number): Observable<ApiResponse<OdometerLog>> {
    return this.http
      .post<ApiResponse<OdometerLog>>(`${this.approvalsUrl}/odometer/${id}/reject`, null, {
        headers: this.getHeaders(),
      })
      .pipe(catchError(this.handleError));
  }

  getFuelRequests(dispatchId: number): Observable<ApiResponse<FuelRequest[]>> {
    const params = new HttpParams().set('dispatchId', String(dispatchId));
    return this.http
      .get<ApiResponse<FuelRequest[]>>(`${this.approvalsUrl}/fuel`, {
        headers: this.getHeaders(),
        params,
      })
      .pipe(catchError(this.handleError));
  }

  approveFuelRequest(id: number): Observable<ApiResponse<FuelRequest>> {
    return this.http
      .post<ApiResponse<FuelRequest>>(`${this.approvalsUrl}/fuel/${id}/approve`, null, {
        headers: this.getHeaders(),
      })
      .pipe(catchError(this.handleError));
  }

  rejectFuelRequest(id: number): Observable<ApiResponse<FuelRequest>> {
    return this.http
      .post<ApiResponse<FuelRequest>>(`${this.approvalsUrl}/fuel/${id}/reject`, null, {
        headers: this.getHeaders(),
      })
      .pipe(catchError(this.handleError));
  }

  getCodSettlements(dispatchId: number): Observable<ApiResponse<CodSettlement[]>> {
    const params = new HttpParams().set('dispatchId', String(dispatchId));
    return this.http
      .get<ApiResponse<CodSettlement[]>>(`${this.approvalsUrl}/cod`, {
        headers: this.getHeaders(),
        params,
      })
      .pipe(catchError(this.handleError));
  }

  approveCodSettlement(id: number): Observable<ApiResponse<CodSettlement>> {
    return this.http
      .post<ApiResponse<CodSettlement>>(`${this.approvalsUrl}/cod/${id}/approve`, null, {
        headers: this.getHeaders(),
      })
      .pipe(catchError(this.handleError));
  }

  rejectCodSettlement(id: number): Observable<ApiResponse<CodSettlement>> {
    return this.http
      .post<ApiResponse<CodSettlement>>(`${this.approvalsUrl}/cod/${id}/reject`, null, {
        headers: this.getHeaders(),
      })
      .pipe(catchError(this.handleError));
  }

  // ===== Daily Closing =====

  closeDispatchDay(date: string, reason?: string): Observable<ApiResponse<any>> {
    let params = new HttpParams().set('date', date);
    if (reason?.trim()) params = params.set('reason', reason.trim());
    return this.http
      .post<ApiResponse<any>>(`${this.closingUrl}/close`, null, {
        headers: this.getHeaders(),
        params,
      })
      .pipe(catchError(this.handleError));
  }

  reopenDispatchDay(date: string, reason?: string): Observable<ApiResponse<any>> {
    let params = new HttpParams().set('date', date);
    if (reason?.trim()) params = params.set('reason', reason.trim());
    return this.http
      .post<ApiResponse<any>>(`${this.closingUrl}/reopen`, null, {
        headers: this.getHeaders(),
        params,
      })
      .pipe(catchError(this.handleError));
  }

  getDispatchDayClosing(date: string): Observable<ApiResponse<any>> {
    const params = new HttpParams().set('date', date);
    return this.http
      .get<ApiResponse<any>>(`${this.closingUrl}`, {
        headers: this.getHeaders(),
        params,
      })
      .pipe(catchError(this.handleError));
  }

  // ===== Mutations =====

  createDispatch(dispatch: Dispatch): Observable<ApiResponse<Dispatch>> {
    return this.http
      .post<ApiResponse<Dispatch>>(this.apiUrl, dispatch, {
        headers: this.getHeaders(),
      })
      .pipe(catchError(this.handleError));
  }

  checkSafetyEligibility(
    driverId: number,
    vehicleId: number,
    date?: string,
  ): Observable<ApiResponse<SafetyEligibility>> {
    let params = new HttpParams()
      .set('driverId', String(driverId))
      .set('vehicleId', String(vehicleId));

    if (date?.trim()) {
      params = params.set('date', date.trim());
    }

    return this.http
      .get<ApiResponse<SafetyEligibility>>(
        `${environment.baseUrl}/api/dispatch/safety-eligibility`,
        {
          headers: this.getHeaders(),
          params,
        },
      )
      .pipe(catchError(this.handleError));
  }

  updateDispatch(dispatchId: number, dispatch: Dispatch): Observable<ApiResponse<Dispatch>> {
    return this.http
      .put<ApiResponse<Dispatch>>(`${this.apiUrl}/${dispatchId}`, dispatch, {
        headers: this.getHeaders(),
      })
      .pipe(catchError(this.handleError));
  }

  deleteDispatch(dispatchId: number): Observable<ApiResponse<string>> {
    return this.http
      .delete<ApiResponse<string>>(`${this.apiUrl}/${dispatchId}`, {
        headers: this.getHeaders(),
      })
      .pipe(catchError(this.handleError));
  }

  bulkDeleteDispatches(dispatchIds: number[]): Observable<ApiResponse<void>> {
    return this.http
      .delete<ApiResponse<void>>(`${this.apiUrl}/bulk-delete`, {
        headers: this.getHeaders(),
        body: dispatchIds,
      })
      .pipe(catchError(this.handleError));
  }

  updateDispatchStatus(
    dispatchId: number,
    status: string,
    reason?: string,
    options?: { forceOverride?: boolean },
  ): Observable<ApiResponse<Dispatch>> {
    let params = new HttpParams().set('status', status);
    if (reason && reason.trim()) {
      params = params.set('reason', reason.trim());
    }
    const body: any = {};
    if (options?.forceOverride === true) {
      body.forceOverride = true;
    }
    return this.http
      .patch<ApiResponse<Dispatch>>(`${this.apiUrl}/${dispatchId}/status`, body, {
        headers: this.getHeaders(),
        params,
      })
      .pipe(catchError(this.handleError));
  }

  assignDispatch(
    dispatchId: number,
    driverId: number,
    vehicleId: number,
  ): Observable<ApiResponse<any>> {
    const params = new HttpParams()
      .set('driverId', String(driverId))
      .set('vehicleId', String(vehicleId));
    return this.http
      .post<ApiResponse<any>>(
        `${this.apiUrl}/${dispatchId}/assign`,
        {},
        {
          headers: this.getHeaders(),
          params,
        },
      )
      .pipe(catchError(this.handleError));
  }

  changeDriver(dispatchId: number, driverId: number): Observable<ApiResponse<any>> {
    // Backend expects the driverId in the request body for change-driver endpoint.
    const body = { driverId };
    return this.http
      .put<ApiResponse<any>>(`${this.apiUrl}/${dispatchId}/change-driver`, body, {
        headers: this.getHeaders(),
      })
      .pipe(catchError(this.handleError));
  }

  changeTruck(dispatchId: number, vehicleId: number): Observable<ApiResponse<any>> {
    const params = new HttpParams().set('vehicleId', String(vehicleId));
    return this.http
      .put<ApiResponse<any>>(
        `${this.apiUrl}/${dispatchId}/change-truck`,
        {},
        {
          headers: this.getHeaders(),
          params,
        },
      )
      .pipe(catchError(this.handleError));
  }

  // ===== Proofs / status operations =====

  submitLoadProof(
    dispatchId: number,
    remarks: string,
    images: File[],
    signature?: File,
  ): Observable<ApiResponse<LoadProof>> {
    const formData = new FormData();
    if (remarks) formData.append('remarks', remarks);
    images.forEach((img) => formData.append('images', img));
    if (signature) formData.append('signature', signature);

    return this.http
      .post<ApiResponse<LoadProof>>(`${this.apiUrl}/${dispatchId}/load`, formData, {
        headers: new HttpHeaders({
          Authorization: `Bearer ${this.authService.getToken()}`,
        }),
      })
      .pipe(catchError(this.handleError));
  }

  markAsDelivered(dispatchId: number): Observable<ApiResponse<Dispatch>> {
    return this.updateDispatchStatus(dispatchId, 'DELIVERED');
  }

  markAsUnloaded(dispatchId: number, payload: FormData): Observable<ApiResponse<any>> {
    return this.http
      .post<ApiResponse<any>>(`${this.apiUrl}/${dispatchId}/unload`, payload, {
        headers: new HttpHeaders({
          Authorization: `Bearer ${this.authService.getToken()}`,
        }),
      })
      .pipe(catchError(this.handleError));
  }

  reportIssue(dispatchId: number, issueData: any): Observable<ApiResponse<any>> {
    return this.http
      .post<ApiResponse<any>>(`${this.apiUrl}/${dispatchId}/report-issue`, issueData, {
        headers: this.getHeaders(),
      })
      .pipe(catchError(this.handleError));
  }

  markAsFailed(dispatchId: number, reason: string): Observable<ApiResponse<any>> {
    return this.http
      .put<ApiResponse<any>>(
        `${this.apiUrl}/${dispatchId}/fail`,
        { reason },
        {
          headers: this.getHeaders(),
        },
      )
      .pipe(catchError(this.handleError));
  }

  // ===== Directory lookups =====

  getAvailableDrivers(): Observable<ApiResponse<Driver[]>> {
    return this.http
      .get<
        ApiResponse<Driver[]>
      >(`${environment.baseUrl}/api/admin/drivers/all`, { headers: this.getHeaders() })
      .pipe(catchError(this.handleError));
  }

  getAvailableTrucks(): Observable<ApiResponse<any[]>> {
    return this.http
      .get<
        ApiResponse<any[]>
      >(`${environment.baseUrl}/api/admin/vehicles/all`, { headers: this.getHeaders() })
      .pipe(catchError(this.handleError));
  }

  // ===== Timelines / related =====

  getStatusHistory(dispatchId: number): Observable<ApiResponse<DispatchStatusHistory[]>> {
    return this.http
      .get<
        ApiResponse<DispatchStatusHistory[]>
      >(`${this.apiUrl}/${dispatchId}/status-history`, { headers: this.getHeaders() })
      .pipe(catchError(this.handleError));
  }

  planTrip(tripPlan: {
    orderId: number;
    tripType: string;
    vehicleId: number;
    scheduleTime: string;
    estimatedDrop: string;
  }): Observable<ApiResponse<any>> {
    return this.http
      .post<ApiResponse<any>>(`${this.apiUrl}/plan-trip`, tripPlan, {
        headers: this.getHeaders(),
      })
      .pipe(catchError(this.handleError));
  }

  getOrderById(orderId: number): Observable<TransportOrder> {
    const url = `${environment.baseUrl}/api/admin/transportorders/${orderId}`;
    return this.http
      .get<ApiResponse<TransportOrder>>(url, {
        headers: this.getHeaders(),
      })
      .pipe(
        map((response) => response.data),
        catchError((error) => {
          console.error('Error loading order:', error);
          return throwError(() => error);
        }),
      );
  }

  // ===== Single-field ops =====

  assignDriverOnly(dispatchId: number, driverId: number): Observable<ApiResponse<any>> {
    const params = new HttpParams().set('driverId', String(driverId));
    return this.http
      .post<ApiResponse<any>>(
        `${this.apiUrl}/${dispatchId}/assign-driver`,
        {},
        {
          headers: this.getHeaders(),
          params,
        },
      )
      .pipe(catchError(this.handleError));
  }

  assignTruckOnly(dispatchId: number, vehicleId: number): Observable<ApiResponse<any>> {
    const params = new HttpParams().set('vehicleId', String(vehicleId));
    return this.http
      .post<ApiResponse<any>>(
        `${this.apiUrl}/${dispatchId}/assign-truck`,
        {},
        {
          headers: this.getHeaders(),
          params,
        },
      )
      .pipe(catchError(this.handleError));
  }

  notifyAssignedDriver(dispatchId: number): Observable<ApiResponse<any>> {
    return this.http
      .post<
        ApiResponse<any>
      >(`${this.apiUrl}/${dispatchId}/notify-assigned-driver`, {}, { headers: this.getHeaders() })
      .pipe(catchError(this.handleError));
  }

  /** Send an arbitrary message to the driver assigned to the dispatch (admin) */
  messageDriver(dispatchId: number, message: string): Observable<ApiResponse<any>> {
    return this.http
      .post<
        ApiResponse<any>
      >(`${this.apiUrl}/${dispatchId}/message-driver`, { message }, { headers: this.getHeaders() })
      .pipe(catchError(this.handleError));
  }

  // ===== Phase 2: Dispatch Approval Workflow =====

  /**
   * Get pending dispatch closures awaiting approval
   * Endpoint: GET /api/admin/dispatch-approval/pending
   */
  getPendingDispatchClosures(): Observable<ApiResponse<any>> {
    return this.http
      .get<ApiResponse<any>>(`${environment.baseUrl}/api/admin/dispatch-approval/pending`, {
        headers: this.getHeaders(),
      })
      .pipe(catchError(this.handleError));
  }

  /**
   * Approve a dispatch closure
   * Endpoint: POST /api/admin/dispatch-approval/{dispatchId}/approve
   */
  approveDispatchClosure(
    dispatchId: number,
    request: { remarks?: string; [key: string]: any },
  ): Observable<ApiResponse<any>> {
    return this.http
      .post<
        ApiResponse<any>
      >(`${environment.baseUrl}/api/admin/dispatch-approval/${dispatchId}/approve`, request, { headers: this.getHeaders() })
      .pipe(catchError(this.handleError));
  }

  /**
   * Reject a dispatch closure and require rework
   * Endpoint: POST /api/admin/dispatch-approval/{dispatchId}/reject
   */
  rejectDispatchClosure(
    dispatchId: number,
    request: { remarks?: string; [key: string]: any },
  ): Observable<ApiResponse<any>> {
    return this.http
      .post<
        ApiResponse<any>
      >(`${environment.baseUrl}/api/admin/dispatch-approval/${dispatchId}/reject`, request, { headers: this.getHeaders() })
      .pipe(catchError(this.handleError));
  }

  /**
   * Get SLA info for a dispatch approval
   * Endpoint: GET /api/admin/dispatch-approval/{dispatchId}/sla
   */
  getDispatchApprovalSLA(dispatchId: number): Observable<ApiResponse<any>> {
    return this.http
      .get<
        ApiResponse<any>
      >(`${environment.baseUrl}/api/admin/dispatch-approval/${dispatchId}/sla`, { headers: this.getHeaders() })
      .pipe(catchError(this.handleError));
  }

  // ===== Phase 2: Pre-Entry Safety Checks (Phase 3 Feature) =====

  /**
   * Submit pre-entry safety check for a dispatch
   * Endpoint: POST /api/admin/pre-entry-safety/submit
   */
  submitPreEntrySafetyCheck(request: {
    dispatchId: number;
    vehicleId: number;
    driverId: number;
    [key: string]: any;
  }): Observable<ApiResponse<any>> {
    return this.http
      .post<
        ApiResponse<any>
      >(`${environment.baseUrl}/api/admin/pre-entry-safety/submit`, request, { headers: this.getHeaders() })
      .pipe(catchError(this.handleError));
  }

  /**
   * Get pre-entry safety check for a dispatch
   * Endpoint: GET /api/admin/pre-entry-safety/dispatch/{dispatchId}
   */
  getPreEntrySafetyCheck(dispatchId: number): Observable<ApiResponse<any>> {
    return this.http
      .get<
        ApiResponse<any>
      >(`${environment.baseUrl}/api/admin/pre-entry-safety/dispatch/${dispatchId}`, { headers: this.getHeaders() })
      .pipe(catchError(this.handleError));
  }

  /**
   * Get all pending conditional overrides awaiting supervisor approval
   * Endpoint: GET /api/admin/pre-entry-safety/pending-overrides
   */
  getPendingConditionalOverrides(): Observable<ApiResponse<any>> {
    return this.http
      .get<
        ApiResponse<any>
      >(`${environment.baseUrl}/api/admin/pre-entry-safety/pending-overrides`, { headers: this.getHeaders() })
      .pipe(catchError(this.handleError));
  }

  /**
   * Approve conditional override for safety check (supervisory bypass)
   * Endpoint: POST /api/admin/pre-entry-safety/{checkId}/override
   */
  approveConditionalOverride(
    checkId: number,
    request: { remarks?: string; approvedBy?: string; [key: string]: any },
  ): Observable<ApiResponse<any>> {
    return this.http
      .post<
        ApiResponse<any>
      >(`${environment.baseUrl}/api/admin/pre-entry-safety/${checkId}/override`, request, { headers: this.getHeaders() })
      .pipe(catchError(this.handleError));
  }

  /**
   * List pre-entry safety checks with optional filters
   * Endpoint: GET /api/admin/pre-entry-safety
   */
  listPreEntrySafetyChecks(filters?: {
    status?: string;
    warehouseCode?: string;
    fromDate?: string;
    toDate?: string;
    dispatchIds?: number[];
  }): Observable<any[]> {
    let params = new HttpParams();
    if (filters?.status?.trim()) params = params.set('status', filters.status.trim());
    if (filters?.warehouseCode?.trim())
      params = params.set('warehouseCode', filters.warehouseCode.trim());
    if (filters?.fromDate?.trim()) params = params.set('fromDate', filters.fromDate.trim());
    if (filters?.toDate?.trim()) params = params.set('toDate', filters.toDate.trim());
    if (filters?.dispatchIds?.length) {
      for (const dispatchId of filters.dispatchIds) {
        params = params.append('dispatchIds', String(dispatchId));
      }
    }

    return this.http
      .get<
        any[]
      >(`${environment.baseUrl}/api/admin/pre-entry-safety`, { headers: this.getHeaders(), params })
      .pipe(catchError(this.handleError));
  }

  /**
   * Get pre-entry safety check by id
   * Endpoint: GET /api/admin/pre-entry-safety/{checkId}
   */
  getPreEntrySafetyCheckById(checkId: number): Observable<unknown> {
    return this.http
      .get<unknown>(`${environment.baseUrl}/api/admin/pre-entry-safety/${checkId}`, {
        headers: this.getHeaders(),
      })
      .pipe(catchError(this.handleError));
  }

  /**
   * Update existing pre-entry safety check
   * Endpoint: PUT /api/admin/pre-entry-safety/{checkId}
   */
  updatePreEntrySafetyCheck(
    checkId: number,
    request: PreEntrySafetyCheckUpsertRequest,
  ): Observable<unknown> {
    return this.http
      .put<unknown>(`${environment.baseUrl}/api/admin/pre-entry-safety/${checkId}`, request, {
        headers: this.getHeaders(),
      })
      .pipe(catchError(this.handleError));
  }

  /**
   * Upload pre-entry safety image
   * Endpoint: POST /api/admin/pre-entry-safety/photos/upload
   */
  uploadPreEntrySafetyPhoto(file: File): Observable<ApiResponse<{ url: string }>> {
    const formData = new FormData();
    formData.append('file', file);
    return this.http
      .post<
        ApiResponse<{ url: string }>
      >(`${environment.baseUrl}/api/admin/pre-entry-safety/photos/upload`, formData, { headers: this.getAuthHeaders() })
      .pipe(catchError(this.handleError));
  }

  /**
   * Delete pre-entry safety check
   * Endpoint: DELETE /api/admin/pre-entry-safety/{checkId}
   */
  deletePreEntrySafetyCheck(checkId: number): Observable<void> {
    return this.http
      .delete<void>(`${environment.baseUrl}/api/admin/pre-entry-safety/${checkId}`, {
        headers: this.getHeaders(),
      })
      .pipe(catchError(this.handleError));
  }
}
