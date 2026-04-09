/* eslint-disable @typescript-eslint/consistent-type-imports */
import { CommonModule } from '@angular/common';
import { HttpClientModule } from '@angular/common/http';
import { OnInit } from '@angular/core';
import { Component } from '@angular/core';
import { FormsModule } from '@angular/forms';
import { ToastrService } from 'ngx-toastr';
import { ConfirmService } from '../../../services/confirm.service';

import type { MaintenanceTaskType } from '../../../models/maintenance-task-type.model';
import { MaintenanceTaskTypeService } from '../../../services/maintenance-task-type.service';

@Component({
  selector: 'app-maintenance-task-types',
  standalone: true,
  imports: [CommonModule, FormsModule, HttpClientModule],
  templateUrl: './maintenance-task-types.component.html',
  styleUrls: ['./maintenance-task-types.component.scss'],
})
export class MaintenanceTaskTypeListComponent implements OnInit {
  taskTypes: MaintenanceTaskType[] = [];

  selectedTaskType: MaintenanceTaskType = { name: '', description: '' };

  isEditing = false;
  isModalOpen = false;
  isLoading = false;

  currentPage = 0;
  pageSize = 10;
  totalItems = 0;
  searchQuery = '';

  constructor(
    private service: MaintenanceTaskTypeService,
    private toastr: ToastrService,
    private confirm: ConfirmService,
  ) {}

  ngOnInit(): void {
    this.loadTaskTypes();
  }

  loadTaskTypes(): void {
    this.isLoading = true;

    this.service.getAllPaged(this.searchQuery, this.currentPage, this.pageSize).subscribe({
      next: (res) => {
        this.taskTypes = res.data?.content || [];
        this.totalItems = res.data?.totalElements || 0;
        this.isLoading = false;
      },
      error: (err) => {
        this.toastr.error(err.message || 'Failed to load task types');
        this.isLoading = false;
      },
    });
  }

  openModal(type?: MaintenanceTaskType): void {
    this.selectedTaskType = type ? { ...type } : { name: '', description: '' };
    this.isEditing = !!type?.id;
    this.isModalOpen = true;
  }

  closeModal(): void {
    this.selectedTaskType = { name: '', description: '' };
    this.isEditing = false;
    this.isModalOpen = false;
  }

  saveTaskType(): void {
    if (!this.selectedTaskType.name?.trim()) {
      this.toastr.warning('Name is required');
      return;
    }

    this.isLoading = true;
    const payload: Partial<MaintenanceTaskType> = {
      name: this.selectedTaskType.name.trim(),
      description: this.selectedTaskType.description?.trim() || '',
    };

    const request$ =
      this.isEditing && this.selectedTaskType.id
        ? this.service.update(this.selectedTaskType.id, payload)
        : this.service.create(payload);

    request$.subscribe({
      next: () => {
        this.toastr.success(this.isEditing ? 'Updated successfully' : 'Created successfully');
        this.closeModal();
        this.loadTaskTypes();
      },
      error: (err) => {
        this.toastr.error(err.message || 'Something went wrong');
        this.isLoading = false;
      },
    });
  }

  async deleteTaskType(id: number): Promise<void> {
    if (!(await this.confirm.confirm('Are you sure you want to delete this task type?'))) return;

    this.isLoading = true;
    this.service.delete(id).subscribe({
      next: () => {
        this.toastr.success('Deleted successfully');
        this.loadTaskTypes();
      },
      error: (err) => {
        this.toastr.error(err.message || 'Delete failed');
        this.isLoading = false;
      },
    });
  }

  applyFilter(): void {
    this.currentPage = 0;
    this.loadTaskTypes();
  }

  get totalPages(): number {
    return Math.ceil(this.totalItems / this.pageSize);
  }

  nextPage(): void {
    if (this.currentPage < this.totalPages - 1) {
      this.currentPage++;
      this.loadTaskTypes();
    }
  }

  prevPage(): void {
    if (this.currentPage > 0) {
      this.currentPage--;
      this.loadTaskTypes();
    }
  }
}
