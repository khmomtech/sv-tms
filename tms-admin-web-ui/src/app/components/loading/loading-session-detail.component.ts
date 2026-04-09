import { CommonModule } from '@angular/common';
import { Component, type OnInit } from '@angular/core';
import { type FormArray, FormBuilder, type FormGroup, ReactiveFormsModule } from '@angular/forms';
import { FormsModule } from '@angular/forms';
import { ActivatedRoute, RouterModule } from '@angular/router';
import { ToastrService } from 'ngx-toastr';

import type { LoadingDocumentType } from '../../models/loading-document.model';
import type { LoadingSession } from '../../models/loading-session.model';
import { LoadingOpsService } from '../../services/loading-ops.service';

@Component({
  selector: 'app-loading-session-detail',
  standalone: true,
  imports: [CommonModule, ReactiveFormsModule, RouterModule, FormsModule],
  templateUrl: './loading-session-detail.component.html',
})
export class LoadingSessionDetailComponent implements OnInit {
  session?: LoadingSession;
  dispatchId!: number;
  loading = false;
  submitting = false;
  documentType: LoadingDocumentType = 'PACKING_LIST';
  documentFile?: File;

  form: FormGroup;

  constructor(
    private readonly fb: FormBuilder,
    private readonly route: ActivatedRoute,
    private readonly loadingOpsService: LoadingOpsService,
    private readonly toastr: ToastrService,
  ) {
    this.form = this.fb.group({
      remarks: [''],
      endedAt: [''],
      palletItems: this.fb.array([]),
      emptiesReturns: this.fb.array([]),
    });
  }

  ngOnInit(): void {
    this.dispatchId = Number(this.route.snapshot.paramMap.get('id'));
    if (this.dispatchId) {
      this.loadSession();
    }
  }

  get palletItems(): FormArray {
    return this.form.get('palletItems') as FormArray;
  }

  get emptiesReturns(): FormArray {
    return this.form.get('emptiesReturns') as FormArray;
  }

  addPallet(): void {
    this.palletItems.push(
      this.fb.group({
        itemDescription: [''],
        palletTag: [''],
        quantity: [0],
        unit: [''],
        conditionNote: [''],
        verifiedOk: [true],
      }),
    );
  }

  addEmptyReturn(): void {
    this.emptiesReturns.push(
      this.fb.group({
        itemName: [''],
        quantity: [0],
        unit: [''],
        conditionNote: [''],
      }),
    );
  }

  removePallet(idx: number): void {
    this.palletItems.removeAt(idx);
  }

  removeEmpty(idx: number): void {
    this.emptiesReturns.removeAt(idx);
  }

  loadSession(): void {
    this.loading = true;
    this.loadingOpsService.sessionForDispatch(this.dispatchId).subscribe({
      next: (session) => {
        this.session = session;
        this.loading = false;
        this.resetArrays(session);
        this.form.patchValue({
          remarks: session.remarks || '',
        });
      },
      error: (err) => {
        console.error(err);
        this.toastr.error(err?.error?.message || 'No active loading session for this dispatch');
        this.loading = false;
      },
    });
  }

  submit(): void {
    if (!this.session) return;
    this.submitting = true;
    const payload = {
      sessionId: this.session.id,
      remarks: this.form.value.remarks,
      endedAt: this.form.value.endedAt || undefined,
      palletItems: this.form.value.palletItems,
      emptiesReturns: this.form.value.emptiesReturns,
    };
    this.loadingOpsService.completeLoading(payload).subscribe({
      next: (res) => {
        this.toastr.success('Loading completed.');
        this.session = res;
        this.submitting = false;
      },
      error: (err) => {
        console.error(err);
        this.toastr.error(err?.error?.message || 'Unable to complete loading');
        this.submitting = false;
      },
    });
  }

  onDocumentFile(event: Event): void {
    const input = event.target as HTMLInputElement;
    const file = input.files?.[0];
    this.documentFile = file || undefined;
  }

  uploadDocument(): void {
    if (!this.session?.id || !this.documentFile) return;
    this.loadingOpsService
      .uploadDocument(this.session.id, this.documentType, this.documentFile)
      .subscribe({
        next: () => {
          this.toastr.success('Document uploaded.');
          this.documentFile = undefined;
          this.loadSession();
        },
        error: (err) => {
          console.error(err);
          this.toastr.error(err?.error?.message || 'Upload failed');
        },
      });
  }

  private resetArrays(session: LoadingSession): void {
    this.palletItems.clear();
    this.emptiesReturns.clear();
    (session.palletItems || []).forEach((item) => {
      this.palletItems.push(
        this.fb.group({
          itemDescription: [item.itemDescription],
          palletTag: [item.palletTag],
          quantity: [item.quantity],
          unit: [item.unit],
          conditionNote: [item.conditionNote],
          verifiedOk: [item.verifiedOk],
        }),
      );
    });
    (session.emptiesReturns || []).forEach((item) => {
      this.emptiesReturns.push(
        this.fb.group({
          itemName: [item.itemName],
          quantity: [item.quantity],
          unit: [item.unit],
          conditionNote: [item.conditionNote],
        }),
      );
    });
  }
}
