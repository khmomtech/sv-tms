import { CommonModule } from '@angular/common';
import { Component, EventEmitter, Input, Output } from '@angular/core';
import { FormBuilder, ReactiveFormsModule, Validators } from '@angular/forms';
import { ToastrService } from 'ngx-toastr';

import type {
  PreLoadingSafetyCheckRequest,
  SafetyResult,
} from '../../models/pre-loading-safety-check.model';
import { SafetyCheckService } from '../../services/safety-check.service';

@Component({
  selector: 'app-safety-checklist',
  standalone: true,
  imports: [CommonModule, ReactiveFormsModule],
  templateUrl: './safety-checklist.component.html',
})
export class SafetyChecklistComponent {
  @Input() dispatchId!: number;
  @Input() dispatchCode?: string | null;
  @Output() closed = new EventEmitter<void>();
  @Output() saved = new EventEmitter<void>();

  loading = false;
  form = this.fb.group({
    driverPpeOk: [true, Validators.required],
    fireExtinguisherOk: [true, Validators.required],
    wheelChockOk: [true, Validators.required],
    truckLeakageOk: [true, Validators.required],
    truckCleanOk: [true, Validators.required],
    truckConditionOk: [true, Validators.required],
    result: ['PASS' as SafetyResult, Validators.required],
    failReason: [''],
  });

  constructor(
    private readonly fb: FormBuilder,
    private readonly safetyCheckService: SafetyCheckService,
    private readonly toastr: ToastrService,
  ) {}

  setResult(result: SafetyResult): void {
    this.form.patchValue({ result });
  }

  submit(): void {
    if (!this.dispatchId) {
      this.toastr.error('Missing dispatch id');
      return;
    }

    const value = this.form.value as unknown as PreLoadingSafetyCheckRequest;

    if (value.result === 'FAIL' && (!value.failReason || !value.failReason.trim())) {
      this.form.get('failReason')?.setErrors({ required: true });
      this.toastr.warning('Fail reason is required when result is FAIL.');
      return;
    }

    this.loading = true;
    const payload: PreLoadingSafetyCheckRequest = {
      ...value,
      dispatchId: this.dispatchId,
    };

    this.safetyCheckService.submitCheck(payload).subscribe({
      next: () => {
        this.toastr.success('Safety check saved.');
        this.loading = false;
        this.saved.emit();
        this.close();
      },
      error: (err) => {
        this.loading = false;
        console.error('Failed to save safety check', err);
        this.toastr.error(err?.error?.message || 'Unable to save safety check');
      },
    });
  }

  close(): void {
    this.closed.emit();
  }
}
