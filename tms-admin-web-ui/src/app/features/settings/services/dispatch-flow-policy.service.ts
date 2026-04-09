import type { HttpErrorResponse } from '@angular/common/http';
import { HttpClient, HttpHeaders } from '@angular/common/http';
import { Injectable } from '@angular/core';
import type { Observable } from 'rxjs';
import { throwError } from 'rxjs';
import { catchError, map } from 'rxjs/operators';

import type { ApiResponse } from '../../../models/api-response.model';
import { environment } from '../../../environments/environment';
import { AuthService } from '../../../services/auth.service';

export type DispatchFlowActorType =
  | 'DRIVER'
  | 'LOADING'
  | 'SAFETY'
  | 'DISPATCH_MONITOR'
  | 'SYSTEM'
  | 'ADMIN'
  | 'SUPERADMIN';

export interface DispatchFlowTemplate {
  id: number;
  code: string;
  name: string;
  description?: string;
  active: boolean;
  activePublishedVersionId?: number;
}

export interface DispatchFlowTemplateVersion {
  id: number;
  templateId: number;
  versionNo: number;
  versionLabel: string;
  status: string;
  activePublished: boolean;
  publishedAt?: string;
  notes?: string;
}

export interface DispatchFlowTemplateUpsertRequest {
  code: string;
  name: string;
  description?: string;
  active?: boolean;
}

export interface DispatchFlowRule {
  id: number;
  templateId: number;
  fromStatus: string;
  toStatus: string;
  enabled: boolean;
  priority: number;
  requiresConfirmation: boolean;
  requiresInput: boolean;
  validationMessage?: string;
  metadataJson?: string;
  proofPolicy?: DispatchFlowProofPolicy;
  actors?: Partial<Record<DispatchFlowActorType, boolean>>;
}

export interface DispatchFlowProofPolicy {
  proofRequired?: boolean;
  requiredInputType?: 'NONE' | 'POL' | 'POD' | string;
  proofType?: 'POL' | 'POD' | string;
  proofSubmissionAllowedStatuses?: string[];
  proofSubmissionMode?: string;
  autoAdvanceStatusAfterProof?: string;
  proofReviewRequired?: boolean;
  allowLateProofRecovery?: boolean;
  blockMessage?: string;
  blockCode?: string;
  minImages?: number;
  maxImages?: number;
  signatureRequired?: boolean;
  locationRequired?: boolean;
  remarksRequired?: boolean;
  maxFileSizeBytes?: number;
  mimeTypes?: string[];
}

export interface DispatchFlowRuleUpsertRequest {
  fromStatus: string;
  toStatus: string;
  enabled?: boolean;
  priority?: number;
  requiresConfirmation?: boolean;
  requiresInput?: boolean;
  validationMessage?: string;
  metadataJson?: string;
  proofPolicy?: DispatchFlowProofPolicy;
}

export interface DispatchProofState {
  dispatchId: number;
  currentStatus: string;
  linkedTemplateCode: string;
  resolvedTemplateCode: string;
  workflowVersionId?: number;
  resolvedWorkflowVersionId?: number;
  polRequired: boolean;
  polSubmitted: boolean;
  polSubmittedAt?: string;
  podRequired: boolean;
  podSubmitted: boolean;
  podSubmittedAt?: string;
  podVerified?: boolean;
  loadProofPresent: boolean;
  unloadProofPresent: boolean;
}

export interface DispatchActionMetadata {
  targetStatus: string;
  actionLabel: string;
  allowedForCurrentUser: boolean;
  blockedReason?: string;
  blockedCode?: string;
  requiredInput?: string;
  inputRouteHint?: string;
  templateCode?: string;
  ruleId?: number;
  workflowVersionId?: number;
  proofSubmissionAllowedStatuses?: string[];
  proofSubmissionMode?: string;
  proofReviewRequired?: boolean;
  allowLateProofRecovery?: boolean;
  autoAdvanceStatusAfterProof?: string;
}

export interface DispatchFlowResolution {
  dispatchId: number;
  linkedTemplateCode: string;
  resolvedTemplateCode: string;
  resolvedTemplateName: string;
  workflowVersionId?: number;
  resolvedWorkflowVersionId?: number;
  fallbackToDefault: boolean;
  fallbackToStateMachine: boolean;
  currentStatus: string;
  proofState?: DispatchProofState;
  availableActions: DispatchActionMetadata[];
}

export interface DispatchWorkflowBinding {
  dispatchId: number;
  linkedTemplateCode: string;
  workflowVersionId?: number;
  resolvedTemplateCode: string;
  resolvedWorkflowVersionId?: number;
  fallbackToDefault: boolean;
  fallbackToStateMachine: boolean;
  proofState?: DispatchProofState;
}

export interface DispatchProofEvent {
  id: number;
  dispatchId: number;
  workflowVersionId?: number;
  proofType: string;
  actorUserId?: number;
  actorRolesSnapshot?: string;
  dispatchStatusAtSubmission?: string;
  accepted: boolean;
  blockCode?: string;
  blockReason?: string;
  idempotencyKey?: string;
  fileCount: number;
  reviewStatus: string;
  reviewNote?: string;
  reviewedBy?: number;
  reviewedAt?: string;
  submittedAt?: string;
}

export interface DispatchFlowSimulationRequest {
  dispatchId: number;
  targetStatus?: string;
  proofType?: string;
  actorTypes?: DispatchFlowActorType[];
}

export interface DispatchFlowSimulationResponse {
  dispatchId: number;
  linkedTemplateCode: string;
  resolvedTemplateCode: string;
  currentStatus: string;
  targetStatus?: string;
  proofType?: string;
  actorTypes?: DispatchFlowActorType[];
  allowed: boolean;
  blockedCode?: string;
  blockedReason?: string;
  proofPolicy?: DispatchFlowProofPolicy;
  proofState?: DispatchProofState;
  availableActions: DispatchActionMetadata[];
}

@Injectable({ providedIn: 'root' })
export class DispatchFlowPolicyService {
  private readonly baseUrl = `${environment.baseUrl}/api/admin/dispatch-flow`;

  constructor(
    private readonly http: HttpClient,
    private readonly auth: AuthService,
  ) {}

  private headers(): HttpHeaders {
    const token = this.auth.getToken();
    return new HttpHeaders({
      'Content-Type': 'application/json',
      Authorization: `Bearer ${token}`,
    });
  }

  private handleError(error: HttpErrorResponse) {
    const message = error?.error?.message ?? error?.message ?? 'Dispatch flow policy action failed';
    return throwError(() => new Error(message));
  }

  listTemplates(): Observable<DispatchFlowTemplate[]> {
    return this.http
      .get<ApiResponse<DispatchFlowTemplate[]>>(`${this.baseUrl}/templates`, {
        headers: this.headers(),
      })
      .pipe(
        map((res) => res.data ?? []),
        catchError((e) => this.handleError(e)),
      );
  }

  createTemplate(request: DispatchFlowTemplateUpsertRequest): Observable<DispatchFlowTemplate> {
    return this.http
      .post<ApiResponse<DispatchFlowTemplate>>(`${this.baseUrl}/templates`, request, {
        headers: this.headers(),
      })
      .pipe(
        map((res) => res.data),
        catchError((e) => this.handleError(e)),
      );
  }

  updateTemplate(
    id: number,
    request: DispatchFlowTemplateUpsertRequest,
  ): Observable<DispatchFlowTemplate> {
    return this.http
      .put<ApiResponse<DispatchFlowTemplate>>(`${this.baseUrl}/templates/${id}`, request, {
        headers: this.headers(),
      })
      .pipe(
        map((res) => res.data),
        catchError((e) => this.handleError(e)),
      );
  }

  deleteTemplate(id: number): Observable<void> {
    return this.http
      .delete<ApiResponse<void>>(`${this.baseUrl}/templates/${id}`, {
        headers: this.headers(),
      })
      .pipe(
        map(() => void 0),
        catchError((e) => this.handleError(e)),
      );
  }

  listRules(templateId: number): Observable<DispatchFlowRule[]> {
    return this.http
      .get<ApiResponse<DispatchFlowRule[]>>(`${this.baseUrl}/templates/${templateId}/rules`, {
        headers: this.headers(),
      })
      .pipe(
        map((res) => res.data ?? []),
        catchError((e) => this.handleError(e)),
      );
  }

  createRule(
    templateId: number,
    request: DispatchFlowRuleUpsertRequest,
  ): Observable<DispatchFlowRule> {
    return this.http
      .post<ApiResponse<DispatchFlowRule>>(
        `${this.baseUrl}/templates/${templateId}/rules`,
        request,
        {
          headers: this.headers(),
        },
      )
      .pipe(
        map((res) => res.data),
        catchError((e) => this.handleError(e)),
      );
  }

  reorderRules(templateId: number, ruleIds: number[]): Observable<DispatchFlowRule[]> {
    return this.http
      .put<
        ApiResponse<DispatchFlowRule[]>
      >(`${this.baseUrl}/templates/${templateId}/rules/reorder`, { ruleIds }, { headers: this.headers() })
      .pipe(
        map((res) => res.data ?? []),
        catchError((e) => this.handleError(e)),
      );
  }

  updateRule(ruleId: number, request: DispatchFlowRuleUpsertRequest): Observable<DispatchFlowRule> {
    return this.http
      .put<ApiResponse<DispatchFlowRule>>(`${this.baseUrl}/rules/${ruleId}`, request, {
        headers: this.headers(),
      })
      .pipe(
        map((res) => res.data),
        catchError((e) => this.handleError(e)),
      );
  }

  updateRuleActors(
    ruleId: number,
    actors: Partial<Record<DispatchFlowActorType, boolean>>,
  ): Observable<DispatchFlowRule> {
    return this.http
      .put<
        ApiResponse<DispatchFlowRule>
      >(`${this.baseUrl}/rules/${ruleId}/actors`, { actors }, { headers: this.headers() })
      .pipe(
        map((res) => res.data),
        catchError((e) => this.handleError(e)),
      );
  }

  deleteRule(ruleId: number): Observable<void> {
    return this.http
      .delete<ApiResponse<void>>(`${this.baseUrl}/rules/${ruleId}`, {
        headers: this.headers(),
      })
      .pipe(
        map(() => void 0),
        catchError((e) => this.handleError(e)),
      );
  }

  resolveDispatch(dispatchId: number): Observable<DispatchFlowResolution> {
    return this.http
      .get<ApiResponse<DispatchFlowResolution>>(`${this.baseUrl}/resolve/${dispatchId}`, {
        headers: this.headers(),
      })
      .pipe(
        map((res) => res.data),
        catchError((e) => this.handleError(e)),
      );
  }

  listVersions(templateId: number): Observable<DispatchFlowTemplateVersion[]> {
    return this.http
      .get<
        ApiResponse<DispatchFlowTemplateVersion[]>
      >(`${this.baseUrl}/templates/${templateId}/versions`, { headers: this.headers() })
      .pipe(
        map((res) => res.data ?? []),
        catchError((e) => this.handleError(e)),
      );
  }

  publishTemplateVersion(
    templateId: number,
    request: { versionLabel?: string; notes?: string } = {},
  ): Observable<DispatchFlowTemplateVersion> {
    return this.http
      .post<
        ApiResponse<DispatchFlowTemplateVersion>
      >(`${this.baseUrl}/templates/${templateId}/versions/publish`, request, { headers: this.headers() })
      .pipe(
        map((res) => res.data),
        catchError((e) => this.handleError(e)),
      );
  }

  rollbackVersion(
    versionId: number,
    request: { notes?: string } = {},
  ): Observable<DispatchFlowTemplateVersion> {
    return this.http
      .post<
        ApiResponse<DispatchFlowTemplateVersion>
      >(`${this.baseUrl}/versions/${versionId}/rollback`, request, { headers: this.headers() })
      .pipe(
        map((res) => res.data),
        catchError((e) => this.handleError(e)),
      );
  }

  getWorkflowBinding(dispatchId: number): Observable<DispatchWorkflowBinding> {
    return this.http
      .get<ApiResponse<DispatchWorkflowBinding>>(`${this.baseUrl}/binding/${dispatchId}`, {
        headers: this.headers(),
      })
      .pipe(
        map((res) => res.data),
        catchError((e) => this.handleError(e)),
      );
  }

  assignDispatches(request: {
    dispatchIds: number[];
    templateCode: string;
    allowOperationalOverride?: boolean;
    auditNote?: string;
  }): Observable<DispatchWorkflowBinding[]> {
    return this.http
      .post<ApiResponse<DispatchWorkflowBinding[]>>(`${this.baseUrl}/assign-dispatches`, request, {
        headers: this.headers(),
      })
      .pipe(
        map((res) => res.data ?? []),
        catchError((e) => this.handleError(e)),
      );
  }

  listPendingProofReview(): Observable<DispatchProofEvent[]> {
    return this.http
      .get<ApiResponse<DispatchProofEvent[]>>(`${this.baseUrl}/proof-review`, {
        headers: this.headers(),
      })
      .pipe(
        map((res) => res.data ?? []),
        catchError((e) => this.handleError(e)),
      );
  }

  reviewProofEvent(
    eventId: number,
    request: { approved: boolean; auditNote?: string },
  ): Observable<DispatchProofEvent> {
    return this.http
      .post<
        ApiResponse<DispatchProofEvent>
      >(`${this.baseUrl}/proof-review/${eventId}/decision`, request, { headers: this.headers() })
      .pipe(
        map((res) => res.data),
        catchError((e) => this.handleError(e)),
      );
  }

  simulate(request: DispatchFlowSimulationRequest): Observable<DispatchFlowSimulationResponse> {
    return this.http
      .post<ApiResponse<DispatchFlowSimulationResponse>>(`${this.baseUrl}/simulate`, request, {
        headers: this.headers(),
      })
      .pipe(
        map((res) => res.data),
        catchError((e) => this.handleError(e)),
      );
  }

  getProofState(dispatchId: number): Observable<DispatchProofState> {
    return this.http
      .get<ApiResponse<DispatchProofState>>(`${this.baseUrl}/proof-state/${dispatchId}`, {
        headers: this.headers(),
      })
      .pipe(
        map((res) => res.data),
        catchError((e) => this.handleError(e)),
      );
  }
}
