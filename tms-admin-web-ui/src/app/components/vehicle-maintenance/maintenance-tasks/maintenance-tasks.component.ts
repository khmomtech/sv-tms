/* eslint-disable @typescript-eslint/consistent-type-imports */
import { NgIf, NgFor, NgClass, DatePipe } from '@angular/common'; // ⬅️ NgClass & DatePipe added
import { OnInit } from '@angular/core';
import { Component } from '@angular/core';
import { FormGroup } from '@angular/forms';
import { FormBuilder } from '@angular/forms';
import { ReactiveFormsModule, FormsModule } from '@angular/forms';
import { ToastrService } from 'ngx-toastr';

import type { MaintenanceTask } from '../../../models/maintenance-task.model';
import type { Page } from '../../../models/page.model';
import type { Vehicle } from '../../../models/vehicle.model';
import { MaintenanceTaskService } from '../../../services/maintenance-task.service';
import { VehicleService } from '../../../services/vehicle.service';
import { ConfirmService } from '../../../services/confirm.service';

@Component({
  selector: 'app-maintenance-tasks',
  standalone: true,
  templateUrl: './maintenance-tasks.component.html',
  styleUrls: ['./maintenance-tasks.component.scss'],
  imports: [
    FormsModule,
    ReactiveFormsModule,
    NgIf,
    NgFor,
    NgClass, //  Required for [ngClass]
    DatePipe, //  Required for | date pipe
  ],
})
export class MaintenanceTasksComponent implements OnInit {
  tasks: MaintenanceTask[] = [];
  pageData!: Page<MaintenanceTask>;
  searchForm!: FormGroup;
  isLoading = false;

  currentPage = 0;
  pageSize = 10;
  vehicleMap: Record<number, string> = {};

  //  Declare this to fix vehicleOptions error
  vehicleOptions: Vehicle[] = [];

  constructor(
    private maintenanceTaskService: MaintenanceTaskService,
    private vehicleService: VehicleService, //  Add this
    private fb: FormBuilder,
    private toastr: ToastrService,
    private confirm: ConfirmService,
  ) {}

  ngOnInit(): void {
    this.initForm();
    this.loadTasks();
    this.loadVehicles(); //  fetch from backend
  }

  loadVehicles(): void {
    this.vehicleService.getAllVehicles().subscribe({
      next: (res) => {
        if (res.success) {
          this.vehicleOptions = res.data;
        } else {
          this.toastr.warning(res.message || 'Failed to load vehicles.');
        }
      },
      error: (err) => {
        this.toastr.error(err.message || 'Failed to fetch vehicle list.');
      },
    });
  }

  initForm(): void {
    this.searchForm = this.fb.group({
      keyword: [''],
      status: [''],
      vehicleId: [null],
      dueBefore: [''],
      dueAfter: [''],
    });
  }

  loadTasks(): void {
    this.isLoading = true;

    const filters = this.searchForm.value;

    this.maintenanceTaskService.getTasks(this.currentPage, this.pageSize, filters).subscribe({
      next: (res) => {
        if (res.success) {
          this.pageData = res.data;
          this.tasks = res.data.content;
        } else {
          this.toastr.warning(res.message || 'Failed to load tasks.');
        }
      },
      error: (err) => {
        this.toastr.error(err.message);
      },
      complete: () => {
        this.isLoading = false;
      },
    });
  }

  onSearch(): void {
    this.currentPage = 0;
    this.loadTasks();
  }

  onPageChange(page: number): void {
    this.currentPage = page;
    this.loadTasks();
  }

  clearFilters(): void {
    this.searchForm.reset();
    this.currentPage = 0;
    this.loadTasks();
  }
  editTask(task: any): void {
    console.log('Edit task:', task);
    // TODO: Open modal or navigate to edit page
    // Example: this.router.navigate(['/maintenance/tasks/edit', task.id]);
  }

  async deleteTask(task: any): Promise<void> {
    if (!(await this.confirm.confirm(`Are you sure you want to delete "${task.title}"?`))) return;
    // TODO: Call your delete API or service
    console.log('Delete task:', task);
  }
}
