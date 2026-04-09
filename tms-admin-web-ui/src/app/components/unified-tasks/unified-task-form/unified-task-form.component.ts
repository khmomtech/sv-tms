import { CommonModule } from '@angular/common';
import { Component, inject, signal, type OnInit, OnDestroy } from '@angular/core';
import { ReactiveFormsModule, FormBuilder, Validators, type FormGroup } from '@angular/forms';
import { ActivatedRoute, Router } from '@angular/router';
import { NgSelectModule } from '@ng-select/ng-select';
import { ToastrService } from 'ngx-toastr';
import { Subject, debounceTime, distinctUntilChanged, takeUntil } from 'rxjs';

import { TaskService } from '../../../services/task.service';
import { TaskStatus, TaskPriority, type Task } from '../../../models/task.model';

@Component({
  selector: 'app-unified-task-form',
  standalone: true,
  imports: [CommonModule, ReactiveFormsModule, NgSelectModule],
  templateUrl: './unified-task-form.component.html',
  styleUrls: ['./unified-task-form.component.css'],
})
export class UnifiedTaskFormComponent implements OnInit, OnDestroy {
  private fb = inject(FormBuilder);
  private route = inject(ActivatedRoute);
  private router = inject(Router);
  private taskService = inject(TaskService);
  private toastr = inject(ToastrService);

  form: FormGroup;
  isEdit = signal(false);
  loading = signal(false);
  saving = signal(false);
  taskId: number | null = null;

  statuses = Object.values(TaskStatus);
  priorities = Object.values(TaskPriority);

  relationOptions = signal<Task[]>([]);
  relationLoading = signal(false);
  relationSearch$ = new Subject<string>();
  private destroy$ = new Subject<void>();
  relationTypeOptions = [
    { value: 'TASK', label: 'Task', group: 'Tasks' },
    { value: 'INCIDENT', label: 'Incident', group: 'Incidents' },
    { value: 'VEHICLE', label: 'Vehicle', group: 'Fleet' },
    { value: 'CASE', label: 'Case', group: 'Cases' },
    { value: 'WORK_ORDER', label: 'Work Order', group: 'Maintenance' },
  ];

  constructor() {
    this.form = this.fb.group({
      title: ['', [Validators.required, Validators.maxLength(255)]],
      description: [''],
      status: [TaskStatus.OPEN, Validators.required],
      priority: [TaskPriority.MEDIUM, Validators.required],
      dueDate: [''],
      estimatedMinutes: [null],
      relationType: ['TASK'],
      relationId: [null],
    });
  }

  ngOnInit(): void {
    const idParam = this.route.snapshot.paramMap.get('id');
    this.setupRelationSearch();
    this.watchRelationTypeChanges();
    if (idParam) {
      this.taskId = +idParam;
      this.isEdit.set(true);
      this.loadTask(this.taskId);
    } else {
      this.prefillFromQuery();
      if (!this.form.value.relationType) {
        this.form.patchValue({ relationType: 'TASK' });
      }
    }
  }

  getRelationTypeLabel(item: any): string {
    if (!item) return 'Task';
    const value = item.value ?? item;
    const match = this.relationTypeOptions.find((opt) => opt.value === value);
    return match?.label ?? 'Task';
  }

  selectRelationById(id: any): void {
    if (!id) {
      this.onRelationSelected(null);
      return;
    }
    const match = this.relationOptions().find((o) => o.id === id);
    this.onRelationSelected(match ?? null);
  }

  ngOnDestroy(): void {
    this.destroy$.next();
    this.destroy$.complete();
  }

  prefillFromQuery(): void {
    const q = this.route.snapshot.queryParams;
    const relationId = q['relationId'] ? Number(q['relationId']) : null;
    this.form.patchValue({
      relationType: this.normalizeRelationType(
        q['relationType'] ? q['relationType'] : this.form.value.relationType || 'TASK',
      ),
      relationId,
      title: q['title'] ? `Follow-up: ${q['title']}` : '',
    });
  }

  loadTask(id: number): void {
    this.loading.set(true);
    this.taskService.getTaskById(id).subscribe({
      next: (resp) => {
        const task = resp.data as Task;
        this.form.patchValue({
          title: task.title,
          description: task.description,
          status: task.status,
          priority: task.priority,
          dueDate: task.dueDate ? task.dueDate.slice(0, 16) : '',
          estimatedMinutes: task.estimatedMinutes ?? null,
          relationType: this.normalizeRelationType(
            task.relationType ?? this.form.value.relationType ?? 'TASK',
          ),
          relationId: task.relationId ?? null,
        });
        this.loading.set(false);
      },
      error: (err) => {
        this.loading.set(false);
        this.toastr.error('Failed to load task', 'Error');
        console.error('Load task failed', err);
      },
    });
  }

  private setupRelationSearch(): void {
    this.relationSearch$
      .pipe(debounceTime(300), distinctUntilChanged(), takeUntil(this.destroy$))
      .subscribe((term) => {
        this.searchRelations(term);
      });
    // seed with initial blank search to show some options
    this.searchRelations('');
  }

  private watchRelationTypeChanges(): void {
    const control = this.form.get('relationType');
    if (!control) return;
    control.valueChanges.pipe(distinctUntilChanged(), takeUntil(this.destroy$)).subscribe((val) => {
      const normalized = this.normalizeRelationType(val);
      if (normalized !== val) {
        control.patchValue(normalized, { emitEvent: false });
      }
      this.form.patchValue({ relationType: normalized, relationId: null }, { emitEvent: false });
      this.relationOptions.set([]);
    });
  }

  onRelationTypeahead(term: string): void {
    this.relationSearch$.next(term);
  }

  onRelationSelected(task: Task | null): void {
    if (!task) {
      this.form.patchValue({ relationId: null });
      return;
    }
    this.form.patchValue({
      relationType: this.normalizeRelationType(
        task.relationType || this.form.value.relationType || 'TASK',
      ),
      relationId: task.id ?? null,
    });
  }

  private searchRelations(term: string): void {
    this.relationLoading.set(true);
    this.taskService.getTasks({ keyword: term }, 0, 10).subscribe({
      next: (resp) => {
        const list = (resp.data?.content ?? []).map((item: any) => ({
          ...item,
          relationType: this.normalizeRelationType(item.relationType || 'TASK'),
          relationGroup: this.normalizeRelationType(item.relationType || 'TASK'),
        }));
        this.relationOptions.set(list);
        this.relationLoading.set(false);
      },
      error: (err) => {
        console.error('Relation search failed', err);
        this.relationOptions.set([]);
        this.relationLoading.set(false);
      },
    });
  }

  submit(): void {
    if (this.form.invalid) {
      this.form.markAllAsTouched();
      return;
    }
    this.saving.set(true);
    const formValue = this.form.value as Task;
    const payload: Task = {
      ...formValue,
      relationType: this.normalizeRelationType(formValue.relationType || 'TASK'),
      dueDate: formValue.dueDate ? this.normalizeDateTime(formValue.dueDate) : undefined,
    };
    const req = this.isEdit()
      ? this.taskService.updateTask(this.taskId!, payload)
      : this.taskService.createTask(payload);
    req.subscribe({
      next: (resp) => {
        this.saving.set(false);
        const id = resp.data.id;
        this.toastr.success('Task saved', 'Success');
        this.router.navigate(['/tasks', id]);
      },
      error: (err) => {
        this.saving.set(false);
        this.toastr.error('Failed to save task', 'Error');
        console.error('Save task failed', err);
      },
    });
  }

  cancel(): void {
    if (this.isEdit() && this.taskId) {
      this.router.navigate(['/tasks', this.taskId]);
    } else {
      this.router.navigate(['/tasks']);
    }
  }

  private normalizeDateTime(value: string): string {
    // Ensure datetime-local string includes seconds for backend LocalDateTime parsing
    if (!value) return value;
    return value.length === 16 ? `${value}:00` : value;
  }

  private normalizeRelationType(value: string | undefined | null): string {
    if (!value) return 'TASK';
    return String(value).toUpperCase();
  }
}
