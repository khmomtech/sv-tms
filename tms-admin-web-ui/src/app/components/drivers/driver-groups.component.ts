import { CommonModule } from '@angular/common';
import { Component, OnInit } from '@angular/core';
import { FormsModule } from '@angular/forms';
import type { DriverGroup } from '../../services/driver.service';
import { DriverService } from '../../services/driver.service';
import { ConfirmService } from '../../services/confirm.service';

@Component({
  standalone: true,
  selector: 'app-driver-groups',
  templateUrl: './driver-groups.component.html',
  styleUrls: ['./driver-groups.component.css'],
  imports: [CommonModule, FormsModule],
})
export class DriverGroupsComponent implements OnInit {
  groups: DriverGroup[] = [];
  loading = false;
  error = '';
  success = '';
  showModal = false;

  form: Partial<DriverGroup> = {
    name: '',
    code: '',
    description: '',
    active: true,
  };
  editingId: number | null = null;

  constructor(
    private driverService: DriverService,
    private confirm: ConfirmService,
  ) {}

  ngOnInit(): void {
    this.loadGroups();
  }

  loadGroups(): void {
    this.loading = true;
    this.error = '';
    this.success = '';
    this.driverService.getDriverGroups().subscribe({
      next: (res) => {
        this.groups = res.data || [];
        this.loading = false;
      },
      error: () => {
        this.error = 'Failed to load groups';
        this.loading = false;
      },
    });
  }

  resetForm(): void {
    this.editingId = null;
    this.form = { name: '', code: '', description: '', active: true };
  }

  save(): void {
    if (!this.form.name?.trim()) {
      this.error = 'Name is required';
      return;
    }
    const payload = {
      name: this.form.name?.trim(),
      code: this.form.code?.trim() || undefined,
      description: this.form.description?.trim() || undefined,
      active: this.form.active ?? true,
    };
    const action = this.editingId
      ? this.driverService.updateDriverGroup(this.editingId, payload)
      : this.driverService.createDriverGroup(payload);
    this.loading = true;
    action.subscribe({
      next: () => {
        this.success = this.editingId ? 'Group updated' : 'Group added';
        this.resetForm();
        this.showModal = false;
        this.loadGroups();
      },
      error: () => {
        this.error = 'Failed to save group';
        this.loading = false;
      },
    });
  }

  async delete(group: DriverGroup): Promise<void> {
    const ok = await this.confirm.confirm(`Delete driver group "${group.name}"?`);
    if (!ok) return;
    this.loading = true;
    this.driverService.deleteDriverGroup(group.id).subscribe({
      next: () => this.loadGroups(),
      error: () => {
        this.error = 'Failed to delete group';
        this.loading = false;
      },
    });
  }

  get totalGroups(): number {
    return this.groups.length;
  }

  get activeGroups(): number {
    return this.groups.filter((g) => g.active !== false).length;
  }

  openNewGroup(): void {
    this.resetForm();
    this.showModal = true;
  }

  startEdit(group: DriverGroup): void {
    this.editingId = group.id;
    this.form = { ...group };
    this.showModal = true;
  }

  closeModal(): void {
    this.showModal = false;
    this.error = '';
  }
}
