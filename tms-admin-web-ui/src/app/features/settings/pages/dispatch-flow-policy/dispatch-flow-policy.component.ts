import { CommonModule } from '@angular/common';
import {
  CdkDrag,
  CdkDragDrop,
  CdkDragHandle,
  CdkDropList,
  moveItemInArray,
} from '@angular/cdk/drag-drop';
import { Component, OnInit } from '@angular/core';
import { FormsModule } from '@angular/forms';
import { finalize, firstValueFrom } from 'rxjs';

import {
  DispatchFlowPolicyService,
  type DispatchActionMetadata,
  type DispatchFlowActorType,
  type DispatchFlowProofPolicy,
  type DispatchFlowResolution,
  type DispatchFlowRule,
  type DispatchFlowSimulationResponse,
  type DispatchFlowTemplate,
  type DispatchFlowTemplateVersion,
  type DispatchWorkflowBinding,
  type DispatchProofEvent,
  type DispatchProofState,
} from '../../services/dispatch-flow-policy.service';

interface RuleDraft {
  id?: number;
  fromStatus: string;
  toStatus: string;
  enabled: boolean;
  priority: number;
  requiresConfirmation: boolean;
  requiresInput: boolean;
  validationMessage?: string;
  metadataJson?: string;
  proofPolicy: DispatchFlowProofPolicy;
  actors: Partial<Record<DispatchFlowActorType, boolean>>;
}

interface TemplateDraft {
  id: number;
  code: string;
  name: string;
  description: string;
  active: boolean;
}

@Component({
  selector: 'app-dispatch-flow-policy',
  standalone: true,
  imports: [CommonModule, FormsModule, CdkDropList, CdkDrag, CdkDragHandle],
  template: `
    <div class="relative rounded-lg bg-white p-6">
      <div class="flex flex-col gap-2 md:flex-row md:items-center md:justify-between">
        <div>
          <h2 class="text-xl font-bold">Shipment Flow Policy</h2>
          <p class="text-sm text-gray-500">
            Manage templates, actor ownership, proof policy, and live shipment diagnostics.
          </p>
        </div>
        <button
          class="rounded bg-blue-600 px-3 py-2 text-white"
          (click)="reloadAll()"
          [disabled]="loading"
        >
          {{ loading ? 'Loading...' : 'Reload' }}
        </button>
      </div>

      <div
        *ngIf="errorMessage"
        class="mt-3 rounded border border-red-200 bg-red-50 p-2 text-sm text-red-700"
      >
        {{ errorMessage }}
      </div>
      <div
        *ngIf="successMessage"
        class="mt-3 rounded border border-green-200 bg-green-50 p-2 text-sm text-green-700"
      >
        {{ successMessage }}
      </div>

      <div class="mt-6 grid grid-cols-1 gap-4 xl:grid-cols-12">
        <div class="rounded border p-4 xl:col-span-3">
          <h3 class="font-semibold">Templates</h3>

          <div class="mt-3 grid grid-cols-1 gap-2">
            <input
              class="rounded border p-2"
              [(ngModel)]="newTemplate.code"
              placeholder="Code (GENERAL)"
            />
            <input class="rounded border p-2" [(ngModel)]="newTemplate.name" placeholder="Name" />
            <input
              class="rounded border p-2"
              [(ngModel)]="newTemplate.description"
              placeholder="Description"
            />
            <label class="flex items-center gap-2 text-sm">
              <input type="checkbox" [(ngModel)]="newTemplate.active" />
              Active
            </label>
            <button
              class="rounded bg-slate-700 px-3 py-2 text-white"
              (click)="createTemplate()"
              [disabled]="saving"
            >
              Create Template
            </button>
            <button
              class="rounded bg-amber-600 px-3 py-2 text-white"
              (click)="cloneSelectedTemplate()"
              [disabled]="saving || !selectedTemplate"
            >
              Clone Selected
            </button>
          </div>

          <div class="mt-4 max-h-[520px] space-y-2 overflow-auto">
            <button
              *ngFor="let t of templates"
              class="w-full rounded border px-3 py-2 text-left"
              [class.border-blue-600]="selectedTemplate?.id === t.id"
              [class.bg-blue-50]="selectedTemplate?.id === t.id"
              (click)="selectTemplate(t)"
            >
              <div class="font-semibold">{{ t.code }} - {{ t.name }}</div>
              <div class="text-xs text-gray-500">{{ t.description || 'No description' }}</div>
              <div
                class="mt-1 text-xs"
                [class.text-green-600]="t.active"
                [class.text-red-600]="!t.active"
              >
                {{ t.active ? 'ACTIVE' : 'INACTIVE' }}
              </div>
            </button>
          </div>
        </div>

        <div class="rounded border p-4 xl:col-span-5">
          <div *ngIf="!selectedTemplate" class="text-sm text-gray-500">
            Select a template to manage transition rules.
          </div>

          <ng-container *ngIf="selectedTemplate as st">
            <div class="mb-4 grid grid-cols-1 gap-3 lg:grid-cols-2">
              <div class="rounded border bg-slate-50 p-3">
                <div class="mb-2 font-semibold">Template Details</div>
                <div *ngIf="templateDraft as draft" class="grid grid-cols-1 gap-2">
                  <input
                    class="rounded border p-2"
                    [(ngModel)]="draft.code"
                    placeholder="Template code"
                  />
                  <input
                    class="rounded border p-2"
                    [(ngModel)]="draft.name"
                    placeholder="Template name"
                  />
                  <input
                    class="rounded border p-2"
                    [(ngModel)]="draft.description"
                    placeholder="Template description"
                  />
                  <label class="flex items-center gap-2 text-sm">
                    <input type="checkbox" [(ngModel)]="draft.active" />
                    Active
                  </label>
                  <div class="flex flex-wrap gap-2">
                    <button
                      class="rounded bg-blue-600 px-3 py-2 text-white"
                      (click)="saveSelectedTemplate()"
                      [disabled]="saving || !hasTemplateDraftChanges()"
                    >
                      Save Template
                    </button>
                    <button
                      class="rounded bg-slate-300 px-3 py-2 text-slate-800"
                      (click)="resetTemplateDraft()"
                      [disabled]="saving || !hasTemplateDraftChanges()"
                    >
                      Reset
                    </button>
                    <button
                      class="rounded bg-red-600 px-3 py-2 text-white"
                      (click)="deleteSelectedTemplate()"
                      [disabled]="saving"
                    >
                      Delete
                    </button>
                  </div>
                </div>
              </div>

              <div class="rounded border bg-slate-50 p-3">
                <div class="mb-2 font-semibold">Published Versions</div>
                <div class="grid grid-cols-1 gap-2">
                  <input
                    class="rounded border p-2"
                    [(ngModel)]="publishForm.versionLabel"
                    placeholder="Version label (optional)"
                  />
                  <input
                    class="rounded border p-2"
                    [(ngModel)]="publishForm.notes"
                    placeholder="Publish notes"
                  />
                  <button
                    class="rounded bg-emerald-600 px-3 py-2 text-white"
                    (click)="publishSelectedTemplate()"
                    [disabled]="saving"
                  >
                    Publish Snapshot
                  </button>
                </div>
                <div class="mt-3 max-h-40 space-y-2 overflow-auto">
                  <div
                    *ngFor="let version of versions"
                    class="rounded border bg-white p-2 text-xs text-slate-700"
                  >
                    <div class="font-medium">{{ summarizeVersion(version) }}</div>
                    <div>{{ version.publishedAt || 'Unpublished' }}</div>
                    <div class="text-slate-500">{{ version.notes || 'No notes' }}</div>
                    <button
                      class="mt-2 rounded bg-amber-600 px-2 py-1 text-white"
                      (click)="rollbackVersion(version.id)"
                      [disabled]="saving || version.activePublished"
                    >
                      Rollback To This
                    </button>
                  </div>
                </div>
              </div>

              <div class="rounded border bg-slate-50 p-3">
                <div class="mb-2 font-semibold">Dispatch Assignment</div>
                <div class="grid grid-cols-1 gap-2">
                  <input
                    class="rounded border p-2"
                    [(ngModel)]="assignmentForm.dispatchIds"
                    placeholder="Dispatch IDs comma separated"
                  />
                  <input
                    class="rounded border p-2"
                    [(ngModel)]="assignmentForm.templateCode"
                    placeholder="Template code"
                  />
                  <label class="flex items-center gap-2 text-sm">
                    <input type="checkbox" [(ngModel)]="assignmentForm.allowOperationalOverride" />
                    Allow override after LOADING
                  </label>
                  <input
                    class="rounded border p-2"
                    [(ngModel)]="assignmentForm.auditNote"
                    placeholder="Audit note"
                  />
                  <button
                    class="rounded bg-indigo-600 px-3 py-2 text-white"
                    (click)="assignDispatches()"
                    [disabled]="saving"
                  >
                    Assign Template To Shipments
                  </button>
                </div>
              </div>
            </div>

            <div class="flex flex-wrap items-center justify-between gap-3">
              <div>
                <h3 class="font-semibold">Rules: {{ st.code }}</h3>
                <p class="mt-1 text-xs text-gray-500">
                  Drag rows to reorder priority. Proof policy is managed per transition.
                </p>
              </div>
              <div class="flex flex-wrap items-center gap-2">
                <button
                  class="rounded bg-slate-700 px-3 py-2 text-white"
                  (click)="openCreateRuleDrawer()"
                >
                  New Rule
                </button>
              </div>
            </div>

            <div class="mt-4 overflow-auto">
              <table class="w-full border-collapse text-sm">
                <thead>
                  <tr class="border-b bg-slate-50">
                    <th class="w-10 p-2 text-left"></th>
                    <th class="p-2 text-left">Transition</th>
                    <th class="p-2 text-left">Proof</th>
                    <th class="p-2 text-left">Actors</th>
                    <th class="p-2 text-left">Actions</th>
                  </tr>
                </thead>
                <tbody
                  cdkDropList
                  [cdkDropListData]="rules"
                  [cdkDropListDisabled]="saving"
                  (cdkDropListDropped)="onRuleDrop($event)"
                >
                  <tr
                    *ngFor="let r of rules"
                    class="cursor-pointer border-b align-top hover:bg-slate-50"
                    cdkDrag
                    cdkDragLockAxis="y"
                    (click)="openEditRuleDrawer(r)"
                  >
                    <td class="p-2 text-gray-400">
                      <button
                        type="button"
                        cdkDragHandle
                        class="cursor-move px-1 py-0.5 text-base leading-none"
                        (click)="$event.stopPropagation()"
                      >
                        ≡
                      </button>
                    </td>
                    <td class="p-2">
                      <div class="font-medium">{{ r.fromStatus }} → {{ r.toStatus }}</div>
                      <div class="text-xs text-gray-500">Priority {{ r.priority }}</div>
                      <div class="text-xs text-gray-500" *ngIf="r.validationMessage">
                        {{ r.validationMessage }}
                      </div>
                      <div class="mt-1 text-xs text-gray-500">
                        {{
                          r.enabled
                            ? r.requiresConfirmation
                              ? 'Needs confirmation'
                              : 'Enabled'
                            : 'Disabled'
                        }}
                        <span *ngIf="r.requiresInput"> • Input required</span>
                      </div>
                    </td>
                    <td class="p-2">
                      <div class="text-xs font-medium text-slate-700">
                        {{ summarizeProofPolicy(r.proofPolicy) }}
                      </div>
                      <div class="text-xs text-gray-500" *ngIf="r.proofPolicy?.blockCode">
                        {{ r.proofPolicy?.blockCode }}
                      </div>
                    </td>
                    <td class="p-2">
                      <div class="text-xs text-gray-700">
                        {{ summarizeActors(r) }}
                      </div>
                    </td>
                    <td class="p-2">
                      <button
                        class="rounded bg-blue-600 px-2 py-1 text-xs text-white"
                        (click)="openEditRuleDrawer(r); $event.stopPropagation()"
                      >
                        Edit
                      </button>
                      <button
                        class="ml-2 rounded bg-red-600 px-2 py-1 text-xs text-white"
                        (click)="deleteRuleFromRow(r); $event.stopPropagation()"
                      >
                        Delete
                      </button>
                    </td>
                  </tr>
                </tbody>
              </table>
            </div>
          </ng-container>
        </div>

        <div class="rounded border p-4 xl:col-span-4">
          <h3 class="font-semibold">Dispatch Diagnostics</h3>
          <p class="mt-1 text-xs text-gray-500">
            Resolve current workflow, inspect proof state, and simulate action or proof blocks.
          </p>

          <div class="mt-3 grid grid-cols-1 gap-2">
            <input
              class="rounded border p-2"
              [(ngModel)]="diagnostics.dispatchId"
              placeholder="Dispatch ID"
            />
            <div class="grid grid-cols-2 gap-2">
              <button class="rounded bg-slate-700 px-3 py-2 text-white" (click)="resolveDispatch()">
                Resolve
              </button>
              <button class="rounded bg-slate-700 px-3 py-2 text-white" (click)="fetchProofState()">
                Proof State
              </button>
            </div>
            <button
              class="rounded bg-slate-700 px-3 py-2 text-white"
              (click)="fetchWorkflowBinding()"
            >
              Workflow Binding
            </button>
            <select class="rounded border p-2" [(ngModel)]="diagnostics.targetStatus">
              <option value="">Simulate target status</option>
              <option *ngFor="let s of statuses" [value]="s">{{ s }}</option>
            </select>
            <select class="rounded border p-2" [(ngModel)]="diagnostics.proofType">
              <option value="">Simulate proof type</option>
              <option value="POL">POL</option>
              <option value="POD">POD</option>
            </select>
            <div class="rounded border p-3">
              <div class="mb-2 text-sm font-semibold">Actor simulation</div>
              <div class="grid grid-cols-2 gap-1 text-sm">
                <label *ngFor="let actor of actorTypes" class="flex items-center gap-2">
                  <input
                    type="checkbox"
                    [checked]="!!diagnostics.actorTypes[actor]"
                    (change)="diagnostics.actorTypes[actor] = $any($event.target).checked"
                  />
                  {{ formatActorLabel(actor) }}
                </label>
              </div>
            </div>
            <button class="rounded bg-blue-600 px-3 py-2 text-white" (click)="simulateDispatch()">
              Simulate
            </button>
          </div>

          <div *ngIf="resolution" class="mt-4 rounded border bg-slate-50 p-3">
            <div class="font-semibold">Resolved Flow</div>
            <div class="mt-2 text-xs text-gray-700">
              Linked: {{ resolution.linkedTemplateCode }} | Resolved:
              {{ resolution.resolvedTemplateCode }} | Status: {{ resolution.currentStatus }}
            </div>
            <div class="text-xs text-gray-700">
              Workflow version: {{ resolution.workflowVersionId || '-' }} | Resolved version:
              {{ resolution.resolvedWorkflowVersionId || '-' }}
            </div>
            <div class="text-xs text-gray-700">
              Fallback default: {{ resolution.fallbackToDefault ? 'YES' : 'NO' }} | State machine:
              {{ resolution.fallbackToStateMachine ? 'YES' : 'NO' }}
            </div>
            <div class="mt-2 text-xs text-gray-700">
              Actions:
              {{ summarizeActionList(resolution.availableActions) }}
            </div>
          </div>

          <div *ngIf="workflowBinding" class="mt-4 rounded border bg-slate-50 p-3">
            <div class="font-semibold">Workflow Binding</div>
            <div class="mt-2 text-xs text-gray-700">
              Linked: {{ workflowBinding.linkedTemplateCode }} | Pinned version:
              {{ workflowBinding.workflowVersionId || '-' }}
            </div>
            <div class="text-xs text-gray-700">
              Resolved: {{ workflowBinding.resolvedTemplateCode }} | Resolved version:
              {{ workflowBinding.resolvedWorkflowVersionId || '-' }}
            </div>
            <div class="text-xs text-gray-700">
              Fallback default: {{ workflowBinding.fallbackToDefault ? 'YES' : 'NO' }} | State
              machine: {{ workflowBinding.fallbackToStateMachine ? 'YES' : 'NO' }}
            </div>
          </div>

          <div *ngIf="proofState" class="mt-4 rounded border bg-slate-50 p-3">
            <div class="font-semibold">Proof State</div>
            <div class="mt-2 text-xs text-gray-700">
              POL: {{ proofState.polSubmitted ? 'submitted' : 'missing' }} | POD:
              {{ proofState.podSubmitted ? 'submitted' : 'missing' }}
            </div>
            <div class="text-xs text-gray-700">
              Workflow version: {{ proofState.workflowVersionId || '-' }} | Resolved version:
              {{ proofState.resolvedWorkflowVersionId || '-' }} | POD verified:
              {{ proofState.podVerified ? 'yes' : 'no' }}
            </div>
            <div class="text-xs text-gray-700">
              Files: load={{ proofState.loadProofPresent ? 'yes' : 'no' }} / unload={{
                proofState.unloadProofPresent ? 'yes' : 'no'
              }}
            </div>
          </div>

          <div *ngIf="simulation" class="mt-4 rounded border bg-slate-50 p-3">
            <div class="font-semibold">Simulation Result</div>
            <div class="mt-2 text-xs text-gray-700">
              Allowed: {{ simulation.allowed ? 'YES' : 'NO' }}
            </div>
            <div class="text-xs text-gray-700" *ngIf="simulation.blockedCode">
              {{ simulation.blockedCode }}: {{ simulation.blockedReason }}
            </div>
            <div class="mt-2 text-xs text-gray-700" *ngIf="simulation.proofPolicy">
              Policy: {{ summarizeProofPolicy(simulation.proofPolicy) }}
            </div>
          </div>

          <div class="mt-4 rounded border bg-slate-50 p-3">
            <div class="mb-2 flex items-center justify-between">
              <div class="font-semibold">Proof Review Queue</div>
              <button
                class="rounded bg-slate-700 px-3 py-1 text-white"
                (click)="loadProofReviewQueue()"
              >
                Refresh Queue
              </button>
            </div>
            <div *ngIf="proofReviewEvents.length === 0" class="text-xs text-gray-500">
              No pending proof reviews loaded.
            </div>
            <div
              *ngFor="let event of proofReviewEvents"
              class="mb-2 rounded border bg-white p-2 text-xs"
            >
              <div class="font-medium">
                Dispatch {{ event.dispatchId }} • {{ event.proofType }} • {{ event.reviewStatus }}
              </div>
              <div>Status: {{ event.dispatchStatusAtSubmission || '-' }}</div>
              <div>Workflow version: {{ event.workflowVersionId || '-' }}</div>
              <div>Actor: {{ event.actorRolesSnapshot || '-' }}</div>
              <div *ngIf="event.blockCode || event.blockReason">
                {{ event.blockCode || 'BLOCKED' }}: {{ event.blockReason }}
              </div>
              <div class="mt-2 flex gap-2">
                <button
                  class="rounded bg-emerald-600 px-2 py-1 text-white"
                  (click)="reviewProofEvent(event.id, true)"
                  [disabled]="saving"
                >
                  Approve
                </button>
                <button
                  class="rounded bg-red-600 px-2 py-1 text-white"
                  (click)="reviewProofEvent(event.id, false)"
                  [disabled]="saving"
                >
                  Reject
                </button>
              </div>
            </div>
          </div>
        </div>
      </div>

      <div *ngIf="drawerOpen" class="fixed inset-0 z-40 bg-black/30" (click)="closeDrawer()"></div>
      <aside
        *ngIf="drawerOpen && editingRule"
        class="fixed right-0 top-0 z-50 h-full w-full max-w-[560px] overflow-y-auto border-l bg-white p-5 shadow-2xl"
      >
        <div class="mb-4 flex items-center justify-between">
          <h3 class="text-lg font-semibold">{{ creatingRule ? 'Create Rule' : 'Edit Rule' }}</h3>
          <button class="text-gray-500" (click)="closeDrawer()">✕</button>
        </div>

        <div class="grid grid-cols-1 gap-3">
          <div class="grid grid-cols-2 gap-2">
            <div>
              <label class="text-xs text-gray-600">From status</label>
              <select class="w-full rounded border p-2" [(ngModel)]="editingRule.fromStatus">
                <option value="">Select</option>
                <option *ngFor="let s of statuses" [value]="s">{{ s }}</option>
              </select>
            </div>
            <div>
              <label class="text-xs text-gray-600">To status</label>
              <select class="w-full rounded border p-2" [(ngModel)]="editingRule.toStatus">
                <option value="">Select</option>
                <option *ngFor="let s of statuses" [value]="s">{{ s }}</option>
              </select>
            </div>
          </div>

          <div>
            <label class="text-xs text-gray-600">Priority (auto)</label>
            <div class="rounded border bg-slate-50 p-2 text-sm text-slate-700">
              {{ editingRule.priority }}
            </div>
          </div>

          <div>
            <label class="text-xs text-gray-600">Validation message</label>
            <input class="w-full rounded border p-2" [(ngModel)]="editingRule.validationMessage" />
          </div>

          <div class="grid grid-cols-1 gap-1 text-sm">
            <label class="flex items-center gap-2">
              <input type="checkbox" [(ngModel)]="editingRule.enabled" />
              Enabled
            </label>
            <label class="flex items-center gap-2">
              <input type="checkbox" [(ngModel)]="editingRule.requiresConfirmation" />
              Requires confirmation
            </label>
            <label class="flex items-center gap-2">
              <input type="checkbox" [(ngModel)]="editingRule.requiresInput" />
              Requires input
            </label>
          </div>

          <div class="rounded border p-3">
            <div class="mb-2 text-sm font-semibold">Proof policy</div>
            <div class="grid grid-cols-2 gap-2">
              <label class="col-span-2 flex items-center gap-2 text-sm">
                <input
                  type="checkbox"
                  [(ngModel)]="editingRule.proofPolicy.proofRequired"
                  (change)="onProofRequiredToggle()"
                />
                Proof required
              </label>
              <div>
                <label class="text-xs text-gray-600">Proof type</label>
                <select
                  class="w-full rounded border p-2"
                  [(ngModel)]="editingRule.proofPolicy.proofType"
                  (change)="syncProofType()"
                >
                  <option value="">None</option>
                  <option value="POL">POL</option>
                  <option value="POD">POD</option>
                </select>
              </div>
              <div>
                <label class="text-xs text-gray-600">Input type</label>
                <select
                  class="w-full rounded border p-2"
                  [(ngModel)]="editingRule.proofPolicy.requiredInputType"
                >
                  <option value="NONE">NONE</option>
                  <option value="POL">POL</option>
                  <option value="POD">POD</option>
                </select>
              </div>
              <div>
                <label class="text-xs text-gray-600">Submission mode</label>
                <select
                  class="w-full rounded border p-2"
                  [(ngModel)]="editingRule.proofPolicy.proofSubmissionMode"
                >
                  <option value="">Select</option>
                  <option value="BEFORE_TRANSITION">BEFORE_TRANSITION</option>
                  <option value="DURING_STAGE">DURING_STAGE</option>
                  <option value="RECOVERY_ALLOWED">RECOVERY_ALLOWED</option>
                </select>
              </div>
              <div>
                <label class="text-xs text-gray-600">Auto-advance status</label>
                <select
                  class="w-full rounded border p-2"
                  [(ngModel)]="editingRule.proofPolicy.autoAdvanceStatusAfterProof"
                >
                  <option value="">None</option>
                  <option *ngFor="let s of statuses" [value]="s">{{ s }}</option>
                </select>
              </div>
              <div class="col-span-2">
                <label class="text-xs text-gray-600"
                  >Allowed proof statuses (comma separated)</label
                >
                <input
                  class="w-full rounded border p-2"
                  [ngModel]="proofStatusesCsv(editingRule.proofPolicy)"
                  (ngModelChange)="updateProofStatuses($event)"
                />
              </div>
              <div>
                <label class="text-xs text-gray-600">Block code</label>
                <input
                  class="w-full rounded border p-2"
                  [(ngModel)]="editingRule.proofPolicy.blockCode"
                />
              </div>
              <div>
                <label class="text-xs text-gray-600">Min images</label>
                <input
                  class="w-full rounded border p-2"
                  type="number"
                  [(ngModel)]="editingRule.proofPolicy.minImages"
                />
              </div>
              <div class="col-span-2">
                <label class="text-xs text-gray-600">Block message</label>
                <input
                  class="w-full rounded border p-2"
                  [(ngModel)]="editingRule.proofPolicy.blockMessage"
                />
              </div>
              <label class="flex items-center gap-2 text-sm">
                <input
                  type="checkbox"
                  [(ngModel)]="editingRule.proofPolicy.allowLateProofRecovery"
                />
                Allow late recovery
              </label>
              <label class="flex items-center gap-2 text-sm">
                <input type="checkbox" [(ngModel)]="editingRule.proofPolicy.proofReviewRequired" />
                Review required
              </label>
              <label class="flex items-center gap-2 text-sm">
                <input type="checkbox" [(ngModel)]="editingRule.proofPolicy.signatureRequired" />
                Signature required
              </label>
              <label class="flex items-center gap-2 text-sm">
                <input type="checkbox" [(ngModel)]="editingRule.proofPolicy.locationRequired" />
                Location required
              </label>
              <label class="flex items-center gap-2 text-sm">
                <input type="checkbox" [(ngModel)]="editingRule.proofPolicy.remarksRequired" />
                Remarks required
              </label>
            </div>
          </div>

          <div>
            <label class="text-xs text-gray-600">Metadata JSON (preserved and merged)</label>
            <textarea
              class="min-h-[100px] w-full rounded border p-2"
              [(ngModel)]="editingRule.metadataJson"
            ></textarea>
          </div>

          <div class="rounded border p-3">
            <div class="mb-2 text-sm font-semibold">Actor permissions</div>
            <div class="grid grid-cols-2 gap-1 text-sm">
              <label *ngFor="let actor of actorTypes" class="flex items-center gap-2">
                <input
                  type="checkbox"
                  [checked]="!!editingRule.actors[actor]"
                  (change)="editingRule.actors[actor] = $any($event.target).checked"
                />
                {{ formatActorLabel(actor) }}
              </label>
            </div>
          </div>
        </div>

        <div class="mt-6 flex items-center justify-between gap-2">
          <button class="rounded border px-3 py-2" (click)="closeDrawer()">Cancel</button>
          <div class="flex items-center gap-2">
            <button
              *ngIf="!creatingRule"
              class="rounded bg-red-600 px-3 py-2 text-white"
              (click)="disableRuleFromDrawer()"
              [disabled]="saving"
            >
              Disable
            </button>
            <button
              *ngIf="!creatingRule"
              class="rounded bg-rose-800 px-3 py-2 text-white"
              (click)="deleteRuleFromDrawer()"
              [disabled]="saving"
            >
              Delete
            </button>
            <button
              class="rounded bg-blue-600 px-3 py-2 text-white"
              (click)="saveDrawerRule()"
              [disabled]="saving"
            >
              {{ saving ? 'Saving...' : creatingRule ? 'Create' : 'Save' }}
            </button>
          </div>
        </div>
      </aside>
    </div>
  `,
})
export class DispatchFlowPolicyComponent implements OnInit {
  templates: DispatchFlowTemplate[] = [];
  selectedTemplate: DispatchFlowTemplate | null = null;
  templateDraft: TemplateDraft | null = null;
  rules: DispatchFlowRule[] = [];
  versions: DispatchFlowTemplateVersion[] = [];
  resolution: DispatchFlowResolution | null = null;
  workflowBinding: DispatchWorkflowBinding | null = null;
  proofState: DispatchProofState | null = null;
  simulation: DispatchFlowSimulationResponse | null = null;
  proofReviewEvents: DispatchProofEvent[] = [];

  loading = false;
  saving = false;
  errorMessage: string | null = null;
  successMessage: string | null = null;

  drawerOpen = false;
  creatingRule = false;
  editingRule: RuleDraft | null = null;

  readonly statuses: string[] = [
    'PLANNED',
    'PENDING',
    'SCHEDULED',
    'ASSIGNED',
    'DRIVER_CONFIRMED',
    'APPROVED',
    'REJECTED',
    'ARRIVED_LOADING',
    'SAFETY_PASSED',
    'SAFETY_FAILED',
    'IN_QUEUE',
    'LOADING',
    'LOADED',
    'AT_HUB',
    'HUB_LOADING',
    'IN_TRANSIT',
    'ARRIVED_UNLOADING',
    'UNLOADING',
    'UNLOADED',
    'DELIVERED',
    'FINANCIAL_LOCKED',
    'CLOSED',
    'COMPLETED',
    'CANCELLED',
  ];

  readonly actorTypes: DispatchFlowActorType[] = [
    'DRIVER',
    'LOADING',
    'SAFETY',
    'DISPATCH_MONITOR',
    'SYSTEM',
    'ADMIN',
    'SUPERADMIN',
  ];

  newTemplate = { code: '', name: '', description: '', active: true };
  diagnostics: {
    dispatchId: string;
    targetStatus: string;
    proofType: string;
    actorTypes: Partial<Record<DispatchFlowActorType, boolean>>;
  } = {
    dispatchId: '',
    targetStatus: '',
    proofType: '',
    actorTypes: {},
  };

  publishForm = { versionLabel: '', notes: '' };
  assignmentForm = {
    dispatchIds: '',
    templateCode: '',
    allowOperationalOverride: false,
    auditNote: '',
  };

  constructor(private readonly policyService: DispatchFlowPolicyService) {}

  ngOnInit(): void {
    this.reloadAll();
  }

  reloadAll(): void {
    this.errorMessage = null;
    this.successMessage = null;
    this.loading = true;
    this.policyService
      .listTemplates()
      .pipe(finalize(() => (this.loading = false)))
      .subscribe({
        next: (templates) => {
          this.templates = templates;
          if (templates.length > 0) {
            const selected = this.selectedTemplate
              ? templates.find((t) => t.id === this.selectedTemplate?.id)
              : templates[0];
            if (selected) {
              this.selectTemplate(selected);
            }
          }
        },
        error: (err) => {
          this.errorMessage = err.message ?? 'Failed to load templates';
        },
      });
  }

  selectTemplate(template: DispatchFlowTemplate): void {
    this.selectedTemplate = template;
    this.templateDraft = this.createTemplateDraft(template);
    this.closeDrawer();
    this.loadRules(template.id);
    this.loadVersions(template.id);
    this.assignmentForm.templateCode = template.code;
  }

  loadRules(templateId: number): void {
    this.errorMessage = null;
    this.loading = true;
    this.policyService
      .listRules(templateId)
      .pipe(finalize(() => (this.loading = false)))
      .subscribe({
        next: (rules) => {
          this.rules = rules;
        },
        error: (err) => {
          this.rules = [];
          this.errorMessage = err.message ?? 'Failed to load rules';
        },
      });
  }

  loadVersions(templateId: number): void {
    this.policyService.listVersions(templateId).subscribe({
      next: (versions) => {
        this.versions = versions;
      },
      error: (err) => {
        this.versions = [];
        this.errorMessage = err.message ?? 'Failed to load template versions';
      },
    });
  }

  createTemplate(): void {
    if (!this.newTemplate.code.trim() || !this.newTemplate.name.trim()) {
      this.errorMessage = 'Code and name are required for template.';
      return;
    }

    this.saving = true;
    this.errorMessage = null;
    this.policyService
      .createTemplate({
        code: this.newTemplate.code.trim().toUpperCase(),
        name: this.newTemplate.name.trim(),
        description: this.newTemplate.description.trim() || undefined,
        active: this.newTemplate.active,
      })
      .pipe(finalize(() => (this.saving = false)))
      .subscribe({
        next: (template) => {
          this.successMessage = `Template ${template.code} created.`;
          this.newTemplate = { code: '', name: '', description: '', active: true };
          this.reloadAll();
        },
        error: (err) => {
          this.errorMessage = err.message ?? 'Failed to create template';
        },
      });
  }

  async cloneSelectedTemplate(): Promise<void> {
    if (!this.selectedTemplate) {
      return;
    }

    const code = window.prompt('New template code', `${this.selectedTemplate.code}_COPY`)?.trim();
    if (!code) {
      return;
    }

    const name =
      window.prompt('New template name', `${this.selectedTemplate.name} Copy`)?.trim() || code;

    this.errorMessage = null;
    this.saving = true;
    try {
      const clone = await firstValueFrom(
        this.policyService.createTemplate({
          code: code.toUpperCase(),
          name,
          description: `Cloned from ${this.selectedTemplate.code}`,
          active: false,
        }),
      );

      for (const rule of this.rules) {
        const created = await firstValueFrom(
          this.policyService.createRule(clone.id, {
            fromStatus: rule.fromStatus,
            toStatus: rule.toStatus,
            enabled: rule.enabled,
            priority: rule.priority,
            requiresConfirmation: rule.requiresConfirmation,
            requiresInput: rule.requiresInput,
            validationMessage: rule.validationMessage,
            metadataJson: rule.metadataJson,
            proofPolicy: rule.proofPolicy,
          }),
        );
        if (rule.actors && Object.keys(rule.actors).length > 0) {
          await firstValueFrom(this.policyService.updateRuleActors(created.id, rule.actors));
        }
      }

      this.successMessage = `Template ${clone.code} cloned from ${this.selectedTemplate.code}.`;
      this.reloadAll();
    } catch (err) {
      this.errorMessage = err instanceof Error ? err.message : 'Failed to clone template';
    } finally {
      this.saving = false;
    }
  }

  saveTemplate(template: DispatchFlowTemplate): void {
    this.saving = true;
    this.errorMessage = null;
    this.policyService
      .updateTemplate(template.id, {
        code: template.code,
        name: template.name,
        description: template.description,
        active: template.active,
      })
      .pipe(finalize(() => (this.saving = false)))
      .subscribe({
        next: (saved) => {
          this.replaceTemplate(saved);
          this.successMessage = `Template ${saved.code} updated.`;
        },
        error: (err) => {
          this.errorMessage = err.message ?? 'Failed to update template';
        },
      });
  }

  async publishSelectedTemplate(): Promise<void> {
    if (!this.selectedTemplate) {
      return;
    }
    this.saving = true;
    this.errorMessage = null;
    try {
      const version = await firstValueFrom(
        this.policyService.publishTemplateVersion(this.selectedTemplate.id, {
          versionLabel: this.publishForm.versionLabel || undefined,
          notes: this.publishForm.notes || undefined,
        }),
      );
      this.successMessage = `Published ${this.selectedTemplate.code} as ${version.versionLabel}.`;
      this.publishForm = { versionLabel: '', notes: '' };
      this.loadVersions(this.selectedTemplate.id);
      this.reloadAll();
    } catch (err) {
      this.errorMessage = err instanceof Error ? err.message : 'Failed to publish template version';
    } finally {
      this.saving = false;
    }
  }

  async rollbackVersion(versionId: number): Promise<void> {
    if (!this.selectedTemplate) {
      return;
    }
    if (!window.confirm('Rollback active published version to this snapshot?')) {
      return;
    }
    this.saving = true;
    this.errorMessage = null;
    try {
      const version = await firstValueFrom(
        this.policyService.rollbackVersion(versionId, {
          notes: `Rollback requested from admin UI at ${new Date().toISOString()}`,
        }),
      );
      this.successMessage = `Rolled back ${this.selectedTemplate.code} to ${version.versionLabel}.`;
      this.loadVersions(this.selectedTemplate.id);
      this.reloadAll();
    } catch (err) {
      this.errorMessage =
        err instanceof Error ? err.message : 'Failed to rollback template version';
    } finally {
      this.saving = false;
    }
  }

  deleteSelectedTemplate(): void {
    if (!this.selectedTemplate) {
      return;
    }
    const target = this.selectedTemplate;
    if (!window.confirm(`Delete template ${target.code}? This will remove all rules in it.`)) {
      return;
    }

    this.saving = true;
    this.errorMessage = null;
    this.policyService
      .deleteTemplate(target.id)
      .pipe(finalize(() => (this.saving = false)))
      .subscribe({
        next: () => {
          this.successMessage = `Template ${target.code} deleted.`;
          this.templates = this.templates.filter((template) => template.id !== target.id);
          this.selectedTemplate = null;
          this.templateDraft = null;
          this.rules = [];
          this.versions = [];
          this.closeDrawer();
          if (this.templates.length > 0) {
            this.selectTemplate(this.templates[0]);
          }
        },
        error: (err) => {
          this.errorMessage = err.message ?? 'Failed to delete template';
        },
      });
  }

  saveSelectedTemplate(): void {
    if (!this.selectedTemplate || !this.templateDraft) {
      return;
    }

    const code = this.templateDraft.code.trim().toUpperCase();
    const name = this.templateDraft.name.trim();
    if (!code || !name) {
      this.errorMessage = 'Template code and name are required.';
      return;
    }

    this.saveTemplate({
      ...this.selectedTemplate,
      code,
      name,
      description: this.templateDraft.description.trim(),
      active: this.templateDraft.active,
    });
  }

  resetTemplateDraft(): void {
    if (!this.selectedTemplate) {
      return;
    }
    this.templateDraft = this.createTemplateDraft(this.selectedTemplate);
  }

  hasTemplateDraftChanges(): boolean {
    if (!this.selectedTemplate || !this.templateDraft) {
      return false;
    }

    return (
      this.templateDraft.code.trim().toUpperCase() !== this.selectedTemplate.code ||
      this.templateDraft.name.trim() !== this.selectedTemplate.name ||
      this.templateDraft.description.trim() !== (this.selectedTemplate.description ?? '') ||
      this.templateDraft.active !== this.selectedTemplate.active
    );
  }

  openCreateRuleDrawer(): void {
    this.creatingRule = true;
    this.drawerOpen = true;
    this.editingRule = this.blankRuleDraft();
  }

  openEditRuleDrawer(rule: DispatchFlowRule): void {
    this.creatingRule = false;
    this.drawerOpen = true;
    this.editingRule = {
      id: rule.id,
      fromStatus: rule.fromStatus,
      toStatus: rule.toStatus,
      enabled: rule.enabled,
      priority: this.priorityForRuleId(rule.id),
      requiresConfirmation: rule.requiresConfirmation,
      requiresInput: rule.requiresInput,
      validationMessage: rule.validationMessage || '',
      metadataJson: rule.metadataJson || '',
      proofPolicy: { ...(rule.proofPolicy ?? this.defaultProofPolicy()) },
      actors: { ...(rule.actors ?? {}) },
    };
  }

  closeDrawer(): void {
    this.drawerOpen = false;
    this.creatingRule = false;
    this.editingRule = null;
  }

  async saveDrawerRule(): Promise<void> {
    if (!this.selectedTemplate || !this.editingRule) {
      return;
    }
    if (!this.editingRule.fromStatus || !this.editingRule.toStatus) {
      this.errorMessage = 'From status and to status are required.';
      return;
    }

    this.errorMessage = null;
    this.saving = true;
    try {
      const computedPriority = this.creatingRule
        ? this.nextPriority()
        : this.editingRule.id
          ? this.priorityForRuleId(this.editingRule.id)
          : Number(this.editingRule.priority ?? 100);

      const payload = {
        fromStatus: this.editingRule.fromStatus,
        toStatus: this.editingRule.toStatus,
        enabled: this.editingRule.enabled,
        priority: computedPriority,
        requiresConfirmation: this.editingRule.requiresConfirmation,
        requiresInput:
          this.editingRule.requiresInput || Boolean(this.editingRule.proofPolicy.proofRequired),
        validationMessage: this.editingRule.validationMessage || undefined,
        metadataJson: this.editingRule.metadataJson || undefined,
        proofPolicy: this.normalizedProofPolicy(this.editingRule.proofPolicy),
      };

      const savedRule = this.creatingRule
        ? await firstValueFrom(this.policyService.createRule(this.selectedTemplate.id, payload))
        : await firstValueFrom(this.policyService.updateRule(this.editingRule.id!, payload));

      if (Object.keys(this.editingRule.actors).length > 0) {
        await firstValueFrom(
          this.policyService.updateRuleActors(savedRule.id, this.editingRule.actors),
        );
      }

      this.successMessage = this.creatingRule
        ? 'Rule created successfully.'
        : 'Rule updated successfully.';
      this.closeDrawer();
      this.loadRules(this.selectedTemplate.id);
    } catch (err) {
      this.errorMessage = err instanceof Error ? err.message : 'Failed to save rule';
    } finally {
      this.saving = false;
    }
  }

  disableRuleFromDrawer(): void {
    if (!this.editingRule) {
      return;
    }
    this.editingRule.enabled = false;
    void this.saveDrawerRule();
  }

  deleteRuleFromRow(rule: DispatchFlowRule): void {
    if (
      !this.selectedTemplate ||
      !window.confirm(`Delete rule ${rule.fromStatus} -> ${rule.toStatus}?`)
    ) {
      return;
    }
    this.deleteRule(rule.id, false);
  }

  deleteRuleFromDrawer(): void {
    if (!this.editingRule?.id || !this.selectedTemplate) {
      return;
    }
    if (
      !window.confirm(`Delete rule ${this.editingRule.fromStatus} -> ${this.editingRule.toStatus}?`)
    ) {
      return;
    }
    this.deleteRule(this.editingRule.id, true);
  }

  async onRuleDrop(event: CdkDragDrop<DispatchFlowRule[]>): Promise<void> {
    if (!this.selectedTemplate || event.previousIndex === event.currentIndex) {
      return;
    }

    moveItemInArray(this.rules, event.previousIndex, event.currentIndex);
    this.rules = this.rules.map((rule, index) => ({ ...rule, priority: index + 1 }));

    this.errorMessage = null;
    this.saving = true;
    try {
      this.rules = await firstValueFrom(
        this.policyService.reorderRules(
          this.selectedTemplate.id,
          this.rules.map((rule) => rule.id),
        ),
      );
      this.successMessage = 'Rule order updated.';
    } catch (err) {
      this.errorMessage = err instanceof Error ? err.message : 'Failed to reorder rules';
      this.loadRules(this.selectedTemplate.id);
    } finally {
      this.saving = false;
    }
  }

  async resolveDispatch(): Promise<void> {
    const dispatchId = Number(this.diagnostics.dispatchId);
    if (!dispatchId) {
      this.errorMessage = 'Dispatch ID is required for diagnostics.';
      return;
    }
    try {
      this.resolution = await firstValueFrom(this.policyService.resolveDispatch(dispatchId));
      this.successMessage = `Resolved dispatch ${dispatchId}.`;
    } catch (err) {
      this.errorMessage = err instanceof Error ? err.message : 'Failed to resolve dispatch';
    }
  }

  async fetchProofState(): Promise<void> {
    const dispatchId = Number(this.diagnostics.dispatchId);
    if (!dispatchId) {
      this.errorMessage = 'Dispatch ID is required for proof state.';
      return;
    }
    try {
      this.proofState = await firstValueFrom(this.policyService.getProofState(dispatchId));
      this.successMessage = `Fetched proof state for dispatch ${dispatchId}.`;
    } catch (err) {
      this.errorMessage = err instanceof Error ? err.message : 'Failed to fetch proof state';
    }
  }

  async fetchWorkflowBinding(): Promise<void> {
    const dispatchId = Number(this.diagnostics.dispatchId);
    if (!dispatchId) {
      this.errorMessage = 'Dispatch ID is required for workflow binding.';
      return;
    }
    try {
      this.workflowBinding = await firstValueFrom(
        this.policyService.getWorkflowBinding(dispatchId),
      );
      this.successMessage = `Fetched workflow binding for dispatch ${dispatchId}.`;
    } catch (err) {
      this.errorMessage = err instanceof Error ? err.message : 'Failed to fetch workflow binding';
    }
  }

  async assignDispatches(): Promise<void> {
    const dispatchIds = this.assignmentForm.dispatchIds
      .split(',')
      .map((value) => Number(value.trim()))
      .filter((value) => Number.isFinite(value) && value > 0);
    if (dispatchIds.length === 0 || !this.assignmentForm.templateCode.trim()) {
      this.errorMessage = 'Dispatch IDs and template code are required for assignment.';
      return;
    }
    this.saving = true;
    this.errorMessage = null;
    try {
      const result = await firstValueFrom(
        this.policyService.assignDispatches({
          dispatchIds,
          templateCode: this.assignmentForm.templateCode.trim().toUpperCase(),
          allowOperationalOverride: this.assignmentForm.allowOperationalOverride,
          auditNote: this.assignmentForm.auditNote || undefined,
        }),
      );
      this.successMessage = `Assigned template to ${result.length} dispatch(es).`;
      if (dispatchIds.length === 1) {
        this.diagnostics.dispatchId = String(dispatchIds[0]);
        await this.fetchWorkflowBinding();
      }
    } catch (err) {
      this.errorMessage =
        err instanceof Error ? err.message : 'Failed to assign dispatch workflows';
    } finally {
      this.saving = false;
    }
  }

  async loadProofReviewQueue(): Promise<void> {
    try {
      this.proofReviewEvents = await firstValueFrom(this.policyService.listPendingProofReview());
      this.successMessage = `Loaded ${this.proofReviewEvents.length} pending proof review item(s).`;
    } catch (err) {
      this.errorMessage = err instanceof Error ? err.message : 'Failed to load proof review queue';
    }
  }

  async reviewProofEvent(eventId: number, approved: boolean): Promise<void> {
    const auditNote = window.prompt(approved ? 'Approval note (optional)' : 'Rejection note', '');
    if (auditNote === null) {
      return;
    }
    this.saving = true;
    this.errorMessage = null;
    try {
      await firstValueFrom(
        this.policyService.reviewProofEvent(eventId, {
          approved,
          auditNote: auditNote || undefined,
        }),
      );
      this.successMessage = `Proof event ${eventId} ${approved ? 'approved' : 'rejected'}.`;
      await this.loadProofReviewQueue();
    } catch (err) {
      this.errorMessage = err instanceof Error ? err.message : 'Failed to review proof event';
    } finally {
      this.saving = false;
    }
  }

  async simulateDispatch(): Promise<void> {
    const dispatchId = Number(this.diagnostics.dispatchId);
    if (!dispatchId) {
      this.errorMessage = 'Dispatch ID is required for simulation.';
      return;
    }
    try {
      this.simulation = await firstValueFrom(
        this.policyService.simulate({
          dispatchId,
          targetStatus: this.diagnostics.targetStatus || undefined,
          proofType: this.diagnostics.proofType || undefined,
          actorTypes: this.selectedActors(this.diagnostics.actorTypes),
        }),
      );
      this.successMessage = `Simulated dispatch ${dispatchId}.`;
    } catch (err) {
      this.errorMessage = err instanceof Error ? err.message : 'Failed to simulate dispatch';
    }
  }

  onProofRequiredToggle(): void {
    if (!this.editingRule) {
      return;
    }
    if (!this.editingRule.proofPolicy.proofRequired) {
      this.editingRule.proofPolicy = this.defaultProofPolicy();
    }
  }

  syncProofType(): void {
    if (!this.editingRule) {
      return;
    }
    const proofType = this.editingRule.proofPolicy.proofType || '';
    this.editingRule.proofPolicy.requiredInputType = proofType || 'NONE';
    if (proofType === 'POL') {
      this.editingRule.proofPolicy.autoAdvanceStatusAfterProof = 'LOADED';
      this.editingRule.proofPolicy.proofSubmissionAllowedStatuses = ['LOADING', 'LOADED'];
      this.editingRule.proofPolicy.blockCode =
        this.editingRule.proofPolicy.blockCode || 'POL_REQUIRED';
    } else if (proofType === 'POD') {
      this.editingRule.proofPolicy.autoAdvanceStatusAfterProof = 'UNLOADED';
      this.editingRule.proofPolicy.proofSubmissionAllowedStatuses = [
        'ARRIVED_UNLOADING',
        'UNLOADING',
        'UNLOADED',
        'DELIVERED',
        'FINANCIAL_LOCKED',
        'CLOSED',
        'COMPLETED',
      ];
      this.editingRule.proofPolicy.blockCode =
        this.editingRule.proofPolicy.blockCode || 'POD_REQUIRED';
    }
  }

  proofStatusesCsv(proofPolicy: DispatchFlowProofPolicy | undefined): string {
    return (proofPolicy?.proofSubmissionAllowedStatuses ?? []).join(', ');
  }

  updateProofStatuses(raw: string): void {
    if (!this.editingRule) {
      return;
    }
    this.editingRule.proofPolicy.proofSubmissionAllowedStatuses = raw
      .split(',')
      .map((item) => item.trim())
      .filter(Boolean);
  }

  summarizeActors(rule: DispatchFlowRule): string {
    const actors = this.actorTypes.filter((actor) => Boolean(rule.actors?.[actor]));
    return actors.length > 0
      ? actors.map((actor) => this.formatActorLabel(actor)).join(', ')
      : 'No actor assigned';
  }

  summarizeProofPolicy(proofPolicy?: DispatchFlowProofPolicy): string {
    if (
      !proofPolicy?.proofRequired ||
      !proofPolicy.requiredInputType ||
      proofPolicy.requiredInputType === 'NONE'
    ) {
      return 'No proof gate';
    }
    const statuses = proofPolicy.proofSubmissionAllowedStatuses?.join(', ') || 'current transition';
    return `${proofPolicy.requiredInputType} via ${proofPolicy.proofSubmissionMode || 'DEFAULT'} on ${statuses}`;
  }

  summarizeActionList(actions: DispatchActionMetadata[] | undefined): string {
    if (!actions || actions.length === 0) {
      return 'No actions';
    }
    return actions
      .map(
        (action) =>
          `${action.targetStatus}${action.requiredInput && action.requiredInput !== 'NONE' ? ` (${action.requiredInput})` : ''}`,
      )
      .join(', ');
  }

  summarizeVersion(version: DispatchFlowTemplateVersion): string {
    return `${version.versionLabel} (#${version.versionNo})${version.activePublished ? ' ACTIVE' : ''}`;
  }

  formatActorLabel(actor: DispatchFlowActorType): string {
    return actor.replaceAll('_', ' ');
  }

  private async deleteRule(ruleId: number, closeDrawerAfterDelete: boolean): Promise<void> {
    if (!this.selectedTemplate) {
      return;
    }
    this.saving = true;
    this.errorMessage = null;
    this.policyService
      .deleteRule(ruleId)
      .pipe(finalize(() => (this.saving = false)))
      .subscribe({
        next: () => {
          this.successMessage = 'Rule deleted successfully.';
          if (closeDrawerAfterDelete) {
            this.closeDrawer();
          }
          this.loadRules(this.selectedTemplate!.id);
        },
        error: (err) => {
          this.errorMessage = err.message ?? 'Failed to delete rule';
        },
      });
  }

  private blankRuleDraft(): RuleDraft {
    return {
      fromStatus: '',
      toStatus: '',
      enabled: true,
      priority: this.nextPriority(),
      requiresConfirmation: false,
      requiresInput: false,
      validationMessage: '',
      metadataJson: '',
      proofPolicy: this.defaultProofPolicy(),
      actors: {},
    };
  }

  private defaultProofPolicy(): DispatchFlowProofPolicy {
    return {
      proofRequired: false,
      requiredInputType: 'NONE',
      proofType: '',
      proofSubmissionAllowedStatuses: [],
      proofSubmissionMode: '',
      proofReviewRequired: false,
      allowLateProofRecovery: false,
      signatureRequired: false,
      locationRequired: false,
      remarksRequired: false,
    };
  }

  private normalizedProofPolicy(
    proofPolicy: DispatchFlowProofPolicy,
  ): DispatchFlowProofPolicy | undefined {
    if (!proofPolicy.proofRequired) {
      return undefined;
    }
    return {
      ...proofPolicy,
      requiredInputType: proofPolicy.requiredInputType || proofPolicy.proofType || 'NONE',
      proofType: proofPolicy.proofType || proofPolicy.requiredInputType || undefined,
      proofSubmissionAllowedStatuses: (proofPolicy.proofSubmissionAllowedStatuses ?? []).filter(
        Boolean,
      ),
    };
  }

  private selectedActors(
    actorTypes: Partial<Record<DispatchFlowActorType, boolean>>,
  ): DispatchFlowActorType[] | undefined {
    const selected = this.actorTypes.filter((actor) => Boolean(actorTypes[actor]));
    return selected.length > 0 ? selected : undefined;
  }

  private nextPriority(): number {
    return this.rules.length + 1;
  }

  private priorityForRuleId(ruleId: number): number {
    const index = this.rules.findIndex((rule) => rule.id === ruleId);
    return index < 0 ? 100 : index + 1;
  }

  private createTemplateDraft(template: DispatchFlowTemplate): TemplateDraft {
    return {
      id: template.id,
      code: template.code,
      name: template.name,
      description: template.description ?? '',
      active: template.active,
    };
  }

  private replaceTemplate(saved: DispatchFlowTemplate): void {
    this.templates = this.templates.map((template) => (template.id === saved.id ? saved : template));
    this.selectedTemplate = saved;
    this.templateDraft = this.createTemplateDraft(saved);
  }
}
