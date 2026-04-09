import { CommonModule } from '@angular/common';
import { Component, OnInit } from '@angular/core';
import { FormsModule } from '@angular/forms';
import { RouterModule } from '@angular/router';
import { forkJoin, of } from 'rxjs';
import { catchError } from 'rxjs/operators';

import { EmployeeService, type EmployeeDto } from '../../services/employee.service';
import { UserService, type UserDto } from '../../services/user.service';

@Component({
  selector: 'app-staff-management',
  standalone: true,
  imports: [CommonModule, RouterModule, FormsModule],
  templateUrl: './staff-management.html',
})
export class StaffManagementComponent implements OnInit {
  users: UserDto[] = [];
  employees: EmployeeDto[] = [];

  error = '';
  success = '';
  staffSearch = '';
  staffStatusFilter: 'all' | 'active' | 'inactive' = 'all';
  loading = false;
  private searchTimer?: number;

  formOpen = false;
  formMode: 'create' | 'edit' = 'create';
  formLoading = false;
  editingStaffId: number | null = null;

  employeeForm: {
    userId: number | null;
    firstName: string;
    lastName: string;
    email: string;
    phoneNumber: string;
    position: string;
    department: string;
    status: string;
  } = {
    userId: null,
    firstName: '',
    lastName: '',
    email: '',
    phoneNumber: '',
    position: '',
    department: '',
    status: 'ACTIVE',
  };

  constructor(
    private readonly userService: UserService,
    private readonly employeeService: EmployeeService,
  ) {}

  ngOnInit(): void {
    this.loadUsers();
    this.loadEmployees();
  }

  loadUsers(): void {
    this.userService.getAllUsers().subscribe({
      next: (users) => {
        this.users = users ?? [];
      },
      error: () => {
        this.users = [];
        this.error = 'Failed to load users.';
      },
    });
  }

  loadEmployees(): void {
    this.loading = true;
    const search = this.staffSearch.trim();
    this.employeeService.list({ page: 0, size: 200, search: search || undefined }).subscribe({
      next: (res) => {
        this.employees = res?.data?.content ?? [];
        this.error = '';
        this.loading = false;
      },
      error: () => {
        this.employees = [];
        this.error =
          'Failed to load employees. Check permissions or backend connection, then retry.';
        this.loading = false;
      },
    });
  }

  get filteredStaff(): EmployeeDto[] {
    const q = this.staffSearch.trim().toLowerCase();
    return this.employees.filter((m) => {
      const isInactive = (m.status || '').toLowerCase() === 'inactive';
      if (this.staffStatusFilter === 'active' && isInactive) return false;
      if (this.staffStatusFilter === 'inactive' && !isInactive) return false;
      if (!q) return true;
      const userLabel = m.userId ? `user:${m.userId}` : '';
      return (
        `${m.firstName} ${m.lastName}`.toLowerCase().includes(q) ||
        (m.email || '').toLowerCase().includes(q) ||
        (m.phoneNumber || '').toLowerCase().includes(q) ||
        (m.position || '').toLowerCase().includes(q) ||
        (m.department || '').toLowerCase().includes(q) ||
        userLabel.includes(q)
      );
    });
  }

  selectUserForStaff(user: UserDto): void {
    this.success = '';
    this.error = '';
    this.employeeForm = {
      userId: user.id,
      firstName: user.username,
      lastName: '',
      email: user.email || '',
      phoneNumber: '',
      position: '',
      department: '',
      status: 'ACTIVE',
    };
  }

  openCreate(): void {
    this.formMode = 'create';
    this.editingStaffId = null;
    this.success = '';
    this.error = '';
    this.employeeForm = {
      userId: null,
      firstName: '',
      lastName: '',
      email: '',
      phoneNumber: '',
      position: '',
      department: '',
      status: 'ACTIVE',
    };
    this.formOpen = true;
  }

  openEdit(member: EmployeeDto): void {
    if (!member.id) return;
    this.formMode = 'edit';
    this.editingStaffId = member.id;
    this.success = '';
    this.error = '';
    this.employeeForm = {
      userId: member.userId ?? null,
      firstName: member.firstName || '',
      lastName: member.lastName || '',
      email: member.email || '',
      phoneNumber: member.phoneNumber || '',
      position: member.position || '',
      department: member.department || '',
      status: member.status || 'ACTIVE',
    };
    this.formOpen = true;
  }

  closeForm(): void {
    this.formOpen = false;
    this.editingStaffId = null;
  }

  applySearch(): void {
    this.loadEmployees();
  }

  onSearchChange(): void {
    window.clearTimeout(this.searchTimer);
    this.searchTimer = window.setTimeout(() => this.loadEmployees(), 300);
  }

  submitStaff(): void {
    this.success = '';
    this.error = '';
    if (!this.employeeForm.firstName.trim()) {
      this.error = 'First name is required.';
      return;
    }
    if (!this.employeeForm.email.trim()) {
      this.error = 'Email is required.';
      return;
    }
    const payload: EmployeeDto = {
      userId: this.employeeForm.userId ?? undefined,
      firstName: this.employeeForm.firstName.trim(),
      lastName: this.employeeForm.lastName.trim(),
      email: this.employeeForm.email.trim(),
      phoneNumber: this.employeeForm.phoneNumber.trim() || undefined,
      position: this.employeeForm.position.trim() || undefined,
      department: this.employeeForm.department.trim() || undefined,
      status: this.employeeForm.status || 'ACTIVE',
    };
    this.formLoading = true;
    const request =
      this.formMode === 'edit' && this.editingStaffId
        ? this.employeeService.update(this.editingStaffId, payload)
        : this.employeeService.create(payload);
    request.subscribe({
      next: () => {
        this.success = this.formMode === 'edit' ? 'Employee updated.' : 'Employee created.';
        this.formLoading = false;
        this.formOpen = false;
        this.editingStaffId = null;
        this.loadEmployees();
      },
      error: () => {
        this.error =
          this.formMode === 'edit' ? 'Failed to update employee.' : 'Failed to create employee.';
        this.formLoading = false;
      },
    });
  }

  toggleStaffActive(member: EmployeeDto): void {
    if (!member.id) return;
    this.success = '';
    this.error = '';
    const nextStatus = (member.status || '').toLowerCase() === 'inactive' ? 'ACTIVE' : 'INACTIVE';
    this.employeeService.update(member.id, { status: nextStatus }).subscribe({
      next: (res) => {
        const updated = res?.data;
        if (updated) {
          this.employees = this.employees.map((m) => (m.id === updated.id ? updated : m));
        }
        this.success = 'Employee updated.';
      },
      error: () => {
        this.error = 'Failed to update employee.';
      },
    });
  }

  deleteEmployee(member: EmployeeDto): void {
    if (!member.id) return;
    const label = `${member.firstName || ''} ${member.lastName || ''}`.trim() || 'this employee';
    if (!window.confirm(`Delete ${label}? This cannot be undone.`)) return;
    this.success = '';
    this.error = '';
    this.employeeService.delete(member.id).subscribe({
      next: () => {
        this.success = 'Employee deleted.';
        this.employees = this.employees.filter((m) => m.id !== member.id);
      },
      error: () => {
        this.error = 'Failed to delete employee.';
      },
    });
  }

  getUserLabel(userId?: number): string {
    if (!userId) return '—';
    const user = this.users.find((u) => u.id === userId);
    return user ? user.username || user.email || `User #${userId}` : `User #${userId}`;
  }

  exportCsv(): void {
    const rows = [
      [
        'firstName',
        'lastName',
        'email',
        'phoneNumber',
        'position',
        'department',
        'status',
        'userId',
      ],
      ...this.filteredStaff.map((m) => [
        m.firstName || '',
        m.lastName || '',
        m.email || '',
        m.phoneNumber || '',
        m.position || '',
        m.department || '',
        m.status || 'ACTIVE',
        m.userId ? String(m.userId) : '',
      ]),
    ];
    const csv = rows
      .map((row) =>
        row
          .map((cell) => {
            const value = String(cell ?? '');
            if (value.includes(',') || value.includes('"') || value.includes('\n')) {
              return `"${value.replace(/"/g, '""')}"`;
            }
            return value;
          })
          .join(','),
      )
      .join('\n');
    const blob = new Blob([csv], { type: 'text/csv;charset=utf-8;' });
    const url = URL.createObjectURL(blob);
    const link = document.createElement('a');
    link.href = url;
    link.download = 'employees.csv';
    link.click();
    URL.revokeObjectURL(url);
  }

  importCsv(file?: File | null): void {
    if (!file) return;
    const reader = new FileReader();
    reader.onload = () => {
      const text = String(reader.result || '');
      const rows = this.parseCsv(text);
      if (!rows.length) return;
      const [header, ...data] = rows;
      const idx = (name: string) => header.findIndex((h) => h.toLowerCase() === name);
      const iFirst = idx('firstname');
      const iLast = idx('lastname');
      const iEmail = idx('email');
      const iPhone = idx('phonenumber');
      const iJob = idx('position');
      const iDept = idx('department');
      const iStatus = idx('status');
      const iUserId = idx('userid');

      const requests = data
        .map((row) => {
          const firstName = row[iFirst] || '';
          if (!firstName.trim()) return null;
          const payload: EmployeeDto = {
            firstName: firstName.trim(),
            lastName: row[iLast] || '',
            email: row[iEmail] || '',
            phoneNumber: row[iPhone] || undefined,
            position: row[iJob] || undefined,
            department: row[iDept] || undefined,
            status: row[iStatus] || 'ACTIVE',
            userId: row[iUserId] ? Number(row[iUserId]) : undefined,
          };
          return this.employeeService.create(payload).pipe(catchError(() => of(null)));
        })
        .filter((x) => !!x);

      if (!requests.length) return;
      forkJoin(requests).subscribe({
        next: () => {
          this.success = 'Import completed.';
          this.loadEmployees();
        },
        error: () => {
          this.error = 'Import failed.';
        },
      });
    };
    reader.readAsText(file);
  }

  private parseCsv(text: string): string[][] {
    const rows: string[][] = [];
    let current: string[] = [];
    let cell = '';
    let inQuotes = false;
    for (let i = 0; i < text.length; i++) {
      const char = text[i];
      const next = text[i + 1];
      if (char === '"' && inQuotes && next === '"') {
        cell += '"';
        i++;
        continue;
      }
      if (char === '"') {
        inQuotes = !inQuotes;
        continue;
      }
      if (char === ',' && !inQuotes) {
        current.push(cell);
        cell = '';
        continue;
      }
      if ((char === '\n' || char === '\r') && !inQuotes) {
        if (cell.length || current.length) {
          current.push(cell);
          rows.push(current.map((v) => v.trim()));
          current = [];
          cell = '';
        }
        continue;
      }
      cell += char;
    }
    if (cell.length || current.length) {
      current.push(cell);
      rows.push(current.map((v) => v.trim()));
    }
    return rows;
  }
}
