import { Component, OnInit } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormArray, FormBuilder, ReactiveFormsModule, Validators } from '@angular/forms';
import { SafetyService } from '../../core/safety.service';
import { FileService } from '../../core/file.service';
import { NotificationService } from '../../core/notification.service';

@Component({
  selector: 'app-check-form',
  standalone: true,
  imports: [CommonModule, ReactiveFormsModule],
  template: `
    <h3 class="text-lg font-medium">Create Daily Safety Check</h3>
    <form [formGroup]="form" (ngSubmit)="submit()" class="space-y-4 mt-4">
      <div>
        <label>Driver ID</label>
        <input formControlName="driverId" class="border p-2 rounded w-64" />
      </div>
      <div>
        <label>Vehicle ID</label>
        <input formControlName="vehicleId" class="border p-2 rounded w-64" />
      </div>
      <div formArrayName="items">
        <div *ngFor="let it of items.controls; let i=index" [formGroupName]="i" class="p-2 border rounded">
          <div class="flex justify-between items-center">
            <div>
              <strong>{{it.value.nameKh}} / {{it.value.nameEn}}</strong>
            </div>
            <div class="space-x-2">
              <label><input type="radio" formControlName="result" value="OK" /> OK</label>
              <label><input type="radio" formControlName="result" value="NOT_OK" /> NOT_OK</label>
              <label><input type="radio" formControlName="result" value="NA" /> NA</label>
            </div>
          </div>
          <div *ngIf="it.value.requiresPhotoOnFail && it.get('result')?.value === 'NOT_OK'" class="mt-2">
            <label>Evidence photo (required)</label>
            <input type="file" (change)="onFile($event, i)" />
            <div *ngIf="uploading[i]" class="text-sm text-gray-600">Uploading: {{uploading[i]}}%</div>
            <div *ngIf="!uploading[i] && it.get('evidenceUrl')?.value" class="text-sm text-green-600">Uploaded</div>
            <textarea formControlName="comment" placeholder="Comment" class="w-full border p-2 mt-2"></textarea>
          </div>
        </div>
      </div>
      <div>
        <button class="px-4 py-2 bg-blue-600 text-white rounded" [disabled]="form.invalid || submitting">
          <span *ngIf="!submitting">Submit</span>
          <span *ngIf="submitting">Submitting...</span>
        </button>
      </div>
    </form>
  `
})
export class CheckFormComponent implements OnInit {
  form = this.fb.group({ driverId: ['', Validators.required], vehicleId: ['', Validators.required], items: this.fb.array([]) });

  uploading: Record<number, number> = {};
  submitting = false;
  missingEvidenceCount = 0;

  constructor(private fb: FormBuilder, private safety: SafetyService, private file: FileService, private notify: NotificationService) {}

  ngOnInit(){
    this.safety.getItems().subscribe((items: any) => {
      const arr = this.form.get('items') as FormArray;
      (items || []).forEach((it: any) => {
        arr.push(this.fb.group({
          id: [it.id],
          nameKh: [it.nameKh],
          nameEn: [it.nameEn],
          requiresPhotoOnFail: [it.requiresPhotoOnFail],
          result: ['OK'],
          comment: [''],
          evidenceUrl: ['']
        }));
      });
    });
  }

  get items(){ return this.form.get('items') as FormArray; }

  onFile(event: any, index: number){
    const file = event.target.files[0];
    if(!file) return;
    this.uploading[index] = 0;
    this.file.upload(file).subscribe((res: any) => {
      // res: {progress, url?}
      if(res.progress !== undefined) this.uploading[index] = res.progress;
      if(res.url){
        const control = this.items.at(index);
        control.patchValue({ evidenceUrl: res.url });
        delete this.uploading[index];
      }
    }, err => {
      console.error('upload failed', err);
      delete this.uploading[index];
      this.notify.error('File upload failed');
    });
  }

  submit(){
    if(this.form.invalid) return;

    const values = this.form.value;
    // validate evidence for failed items
    const missing = (values.items || []).filter((it: any) => it.requiresPhotoOnFail && it.result === 'NOT_OK' && !it.evidenceUrl);
    if(missing.length){ this.notify.error('Please attach evidence photos for failed items before submitting'); return; }
    // prevent submit while uploads in progress
    if(Object.keys(this.uploading).length){ this.notify.error('Please wait for file uploads to complete'); return; }

    // build payload with date at local ISO
    const now = new Date();
    const payload = { date: now.toISOString(), ...values };

    // compute start/end of day in ISO for unique-per-day check
    const start = new Date(now); start.setHours(0,0,0,0);
    const end = new Date(now); end.setHours(23,59,59,999);

    this.safety.getChecks({ dateFrom: start.toISOString(), dateTo: end.toISOString(), driverId: payload.driverId, vehicleId: payload.vehicleId }).subscribe((r:any)=>{
      const exists = (r && r.content && r.content.length) || 0;
      if(exists){ this.notify.error('A check for this driver/vehicle already exists for today'); return; }
      this.safety.createCheck(payload).subscribe(()=> this.notify.success('Check created'), err => { console.error(err); this.notify.error('Failed to create check'); });
    }, err=>{ console.error(err); this.notify.error('Failed to validate existing checks'); });
  }
}
