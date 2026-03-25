/* eslint-disable @typescript-eslint/consistent-type-imports */
import { CommonModule } from '@angular/common';
import { Component, EventEmitter, Input, Output, inject, OnInit } from '@angular/core';
import { FormGroup } from '@angular/forms';
import { FormBuilder } from '@angular/forms';
import { FormsModule, ReactiveFormsModule, Validators } from '@angular/forms';
import { finalize } from 'rxjs/operators';
import { HttpEventType } from '@angular/common/http';

import { environment } from '../../../../environments/environment';
import type { ApiResponse } from '../../../../models/api-response.model';
import type { DriverDocument } from '../../../../models/driver-document.model';
import { DriverService } from '../../../../services/driver.service';
import { ConfirmService } from '../../../../services/confirm.service';

interface DocumentCategory {
  key: string;
  label: string;
  icon: string;
  description?: string;
}

interface DocumentStats {
  total: number;
  expired: number;
  expiringSoon: number;
  required: number;
}

@Component({
  selector: 'app-driver-documents-tab',
  standalone: true,
  imports: [CommonModule, FormsModule, ReactiveFormsModule],
  templateUrl: './driver-documents-tab.component.html',
})
export class DriverDocumentsTabComponent implements OnInit {
  private confirm = inject(ConfirmService);
  @Input() driverId!: number;
  @Output() documentUpdated = new EventEmitter<DriverDocument | null>();

  documents: DriverDocument[] = [];
  filteredDocuments: DriverDocument[] = [];
  selectedDocument: DriverDocument | null = null;
  documentStats: DocumentStats = { total: 0, expired: 0, expiringSoon: 0, required: 0 };

  documentCategories: DocumentCategory[] = [
    { key: 'license', label: 'Driver License', icon: '🪪', description: 'Primary driving license' },
    {
      key: 'insurance',
      label: 'Insurance',
      icon: '🛡️',
      description: 'Vehicle insurance certificate',
    },
    {
      key: 'registration',
      label: 'Vehicle Registration',
      icon: '📋',
      description: 'Vehicle registration document',
    },
    {
      key: 'medical',
      label: 'Medical Certificate',
      icon: '🏥',
      description: 'Medical fitness certificate',
    },
    {
      key: 'training',
      label: 'Training Certificate',
      icon: '🎓',
      description: 'Training or safety certification',
    },
    {
      key: 'passport',
      label: 'Passport',
      icon: '🛂',
      description: 'Personal identification document',
    },
    {
      key: 'permit',
      label: 'Special Permit',
      icon: '⚠️',
      description: 'Special driving or hazmat permit',
    },
    { key: 'other', label: 'Other', icon: '📄', description: 'Other documents' },
  ];

  documentForm!: FormGroup;
  isEditing = false;
  isLoading = false;
  showModal = false;
  showDetailModal = false;

  selectedFile: File | null = null;
  uploadProgress = 0;
  isDragging = false;

  searchTerm = '';
  selectedCategory = '';
  sortBy: 'name' | 'category' | 'expiryDate' | 'uploadDate' = 'uploadDate';
  sortOrder: 'asc' | 'desc' = 'desc';

  constructor(
    private fb: FormBuilder,
    private driverService: DriverService,
  ) {}

  ngOnInit(): void {
    this.initForm();
    if (this.driverId) {
      this.loadDocuments();
    }
  }

  getCategoryIcon(category: string): string {
    return this.documentCategories.find((cat) => cat.key === category)?.icon || '📄';
  }

  getCategoryLabel(category: string): string {
    return this.documentCategories.find((cat) => cat.key === category)?.label || category;
  }

  getDaysUntilExpiry(document: DriverDocument): number | null {
    if (!document.expiryDate) return null;
    const expiryDate = new Date(document.expiryDate);
    const now = new Date();
    const daysUntilExpiry = Math.ceil(
      (expiryDate.getTime() - now.getTime()) / (1000 * 60 * 60 * 24),
    );
    return daysUntilExpiry;
  }

  isExpiringSoon(document: DriverDocument): boolean {
    const days = this.getDaysUntilExpiry(document);
    return days !== null && days <= 30 && days > 0;
  }

  isExpired(document: DriverDocument): boolean {
    if (!document.expiryDate) return false;
    return new Date(document.expiryDate) < new Date();
  }

  private initForm(): void {
    this.documentForm = this.fb.group({
      name: ['', Validators.required],
      category: ['', Validators.required],
      description: [''],
      expiryDate: [''],
      isRequired: [false],
      notes: [''],
    });
  }

  loadDocuments(): void {
    this.isLoading = true;
    this.driverService.getDriverDocuments(this.driverId).subscribe({
      next: (res: ApiResponse<DriverDocument[]>) => {
        this.documents = res.data;
        this.updateStats();
        this.applyFilters();
        this.isLoading = false;
      },
      error: () => {
        this.documents = [];
        this.filteredDocuments = [];
        this.updateStats();
        this.isLoading = false;
        this.driverService.showToast('Failed to load documents');
      },
    });
  }

  private updateStats(): void {
    this.documentStats = {
      total: this.documents.length,
      expired: this.documents.filter((d) => this.isExpired(d)).length,
      expiringSoon: this.documents.filter((d) => this.isExpiringSoon(d) && !this.isExpired(d))
        .length,
      required: this.documents.filter((d) => d.isRequired).length,
    };
  }

  getComplianceStatus(): { status: 'compliant' | 'warning' | 'critical'; message: string } {
    if (this.documentStats.expired > 0) {
      return {
        status: 'critical',
        message: `${this.documentStats.expired} document(s) expired - immediate action required`,
      };
    }
    if (this.documentStats.expiringSoon > 0) {
      return {
        status: 'warning',
        message: `${this.documentStats.expiringSoon} document(s) expiring soon`,
      };
    }
    const requiredDocs = this.documents.filter((d) => d.isRequired);
    const missingRequired = requiredDocs.filter((d) => !d.uploadDate);
    if (missingRequired.length > 0) {
      return {
        status: 'warning',
        message: `${missingRequired.length} required document(s) missing`,
      };
    }
    return {
      status: 'compliant',
      message: 'All documents current and compliant',
    };
  }

  applyFilters(): void {
    let filtered = [...this.documents];

    // Search filter
    if (this.searchTerm) {
      filtered = filtered.filter(
        (doc) =>
          doc.name.toLowerCase().includes(this.searchTerm.toLowerCase()) ||
          doc.description?.toLowerCase().includes(this.searchTerm.toLowerCase()),
      );
    }

    // Category filter
    if (this.selectedCategory) {
      filtered = filtered.filter((doc) => doc.category === this.selectedCategory);
    }

    // Sort
    filtered.sort((a, b) => {
      let aValue: any, bValue: any;

      switch (this.sortBy) {
        case 'name':
          aValue = a.name.toLowerCase();
          bValue = b.name.toLowerCase();
          break;
        case 'category':
          aValue = a.category;
          bValue = b.category;
          break;
        case 'expiryDate':
          aValue = a.expiryDate ? new Date(a.expiryDate).getTime() : 0;
          bValue = b.expiryDate ? new Date(b.expiryDate).getTime() : 0;
          break;
        case 'uploadDate':
        default:
          aValue = new Date(a.uploadDate).getTime();
          bValue = new Date(b.uploadDate).getTime();
          break;
      }

      if (this.sortOrder === 'asc') {
        return aValue > bValue ? 1 : -1;
      } else {
        return aValue < bValue ? 1 : -1;
      }
    });

    this.filteredDocuments = filtered;
  }

  onSearchChange(): void {
    this.applyFilters();
  }

  onCategoryFilterChange(): void {
    this.applyFilters();
  }

  onSortChange(): void {
    this.applyFilters();
  }

  openModal(): void {
    this.isEditing = false;
    this.documentForm.reset();
    this.selectedFile = null;
    this.uploadProgress = 0;
    this.showModal = true;
  }

  editDocument(document: DriverDocument): void {
    this.isEditing = true;
    const formValues = {
      ...document,
      expiryDate: document.expiryDate?.substring(0, 10) || '',
    };
    this.documentForm.patchValue(formValues);
    this.selectedDocument = document;
    this.showModal = true;
  }

  viewDocument(document: DriverDocument): void {
    this.selectedDocument = document;
    this.showDetailModal = true;
  }

  closeModal(): void {
    this.documentForm.reset();
    this.selectedFile = null;
    this.uploadProgress = 0;
    this.showModal = false;
    this.selectedDocument = null;
  }

  closeDetailModal(): void {
    this.showDetailModal = false;
    this.selectedDocument = null;
  }

  onFileSelect(event: Event): void {
    const input = event.target as HTMLInputElement;
    if (input.files && input.files.length > 0) {
      const file = input.files[0];

      // Validate file type
      const allowedTypes = ['application/pdf', 'image/jpeg', 'image/png', 'image/jpg'];
      if (!allowedTypes.includes(file.type)) {
        this.driverService.showToast('Only PDF and image files are allowed');
        return;
      }

      // Validate size (10MB max)
      const maxSize = 10 * 1024 * 1024;
      if (file.size > maxSize) {
        this.driverService.showToast('File size must be under 10MB');
        return;
      }

      this.selectedFile = file;
    }
  }

  onSubmit(): void {
    if (!this.documentForm.valid || !this.driverId || this.isLoading) {
      return;
    }

    this.isLoading = true;

    // If file is selected and editing is not active, upload with file
    if (this.selectedFile && !this.isEditing) {
      this.uploadDriverDocumentWithFile();
    } else {
      // Save document without file (create or update metadata only)
      this.saveDocument(this.selectedDocument?.fileUrl || '');
    }
  }

  private uploadDriverDocumentWithFile(): void {
    if (!this.selectedFile || !this.driverId) {
      this.isLoading = false;
      return;
    }
    this.driverService
      .uploadDriverDocumentWithProgress(this.driverId, this.selectedFile!, {
        name: this.documentForm.get('name')?.value || '',
        category: this.documentForm.get('category')?.value || '',
        expiryDate: this.documentForm.get('expiryDate')?.value || undefined,
        description: this.documentForm.get('description')?.value || undefined,
        isRequired: this.documentForm.get('isRequired')?.value || false,
      })
      .pipe(
        finalize(() => {
          this.isLoading = false;
          this.uploadProgress = 0;
        }),
      )
      .subscribe({
        next: (event) => {
          if (event.type === HttpEventType.UploadProgress) {
            const total = event.total || 1;
            this.uploadProgress = Math.min(100, Math.round((event.loaded / total) * 100));
            return;
          }

          if (event.type === HttpEventType.Response) {
            const res = event.body;
            this.loadDocuments();
            this.documentUpdated.emit(res?.data ?? null);
            this.driverService.showToast('Document uploaded successfully');
            this.closeModal();
          }
        },
        error: (error: any) => {
          console.error('Error uploading document:', error);
          // Error message already shown by service
        },
      });
  }

  private saveDocument(fileUrl: string): void {
    const payload: DriverDocument = {
      id: this.isEditing && this.selectedDocument ? this.selectedDocument.id : undefined,
      name: this.documentForm.get('name')?.value || '',
      category: this.documentForm.get('category')?.value || '',
      description: this.documentForm.get('description')?.value || '',
      expiryDate: this.documentForm.get('expiryDate')?.value || undefined,
      isRequired: this.documentForm.get('isRequired')?.value || false,
      notes: this.documentForm.get('notes')?.value || '',
      driverId: this.driverId,
      fileUrl: fileUrl,
      uploadDate:
        this.isEditing && this.selectedDocument
          ? this.selectedDocument.uploadDate
          : new Date().toISOString(),
    };

    const request =
      this.isEditing && this.selectedDocument && this.selectedDocument.id
        ? this.driverService.updateDriverDocument(this.driverId, this.selectedDocument.id, {
            name: payload.name,
            category: payload.category,
            expiryDate: payload.expiryDate,
            description: payload.description,
            isRequired: payload.isRequired,
          })
        : this.driverService.addDriverDocument(payload);

    request
      .pipe(
        finalize(() => {
          this.isLoading = false;
        }),
      )
      .subscribe({
        next: (res) => {
          this.loadDocuments();
          this.documentUpdated.emit(res.data);
          this.driverService.showToast(
            this.isEditing ? 'Document updated successfully' : 'Document uploaded successfully',
          );
          this.closeModal();
        },
        error: (error) => {
          console.error('Error saving document:', error);
          // Error message already shown by service
        },
      });
  }

  async onDelete(document: DriverDocument): Promise<void> {
    if (!(await this.confirm.confirm(`Are you sure you want to delete "${document.name}"?`)))
      return;

    this.isLoading = true;
    this.driverService
      .deleteDriverDocument(this.driverId, document.id!)
      .pipe(
        finalize(() => {
          this.isLoading = false;
        }),
      )
      .subscribe({
        next: () => {
          this.loadDocuments();
          this.driverService.showToast('Document deleted');
          this.documentUpdated.emit(null);
          this.closeDetailModal();
        },
        error: (error) => {
          console.error('Error deleting document:', error);
          // Error message already shown by service
        },
      });
  }

  downloadDocument(document: DriverDocument): void {
    if (!document.fileUrl) return;
    const full = this.driverService.buildDocumentFileUrl(document.fileUrl);
    window.open(full, '_blank');
  }

  isImageFile(fileUrl: string): boolean {
    if (!fileUrl) return false;
    const extension = fileUrl.toLowerCase().split('.').pop();
    return ['jpg', 'jpeg', 'png', 'gif', 'bmp', 'webp'].includes(extension || '');
  }

  onDragOver(event: DragEvent): void {
    event.preventDefault();
    event.stopPropagation();
    this.isDragging = true;
  }

  onDragLeave(event: DragEvent): void {
    event.preventDefault();
    event.stopPropagation();
    this.isDragging = false;
  }

  onFileDrop(event: DragEvent): void {
    event.preventDefault();
    event.stopPropagation();
    this.isDragging = false;

    const files = event.dataTransfer?.files;
    if (files && files.length > 0) {
      this.handleFileSelect(files[0]);
    }
  }

  private handleFileSelect(file: File): void {
    // Validate file type
    const allowedTypes = ['application/pdf', 'image/jpeg', 'image/png', 'image/jpg'];
    if (!allowedTypes.includes(file.type)) {
      this.driverService.showToast('Only PDF and image files are allowed');
      return;
    }

    // Validate size (10MB max)
    const maxSize = 10 * 1024 * 1024;
    if (file.size > maxSize) {
      this.driverService.showToast('File size must be under 10MB');
      return;
    }

    this.selectedFile = file;
  }

  clearFile(event: Event): void {
    event.preventDefault();
    event.stopPropagation();
    this.selectedFile = null;
  }

  // Keyboard Navigation Support
  onKeyDown(event: KeyboardEvent): void {
    // Close modal on Escape key
    if (event.key === 'Escape') {
      if (this.showModal) {
        this.closeModal();
      } else if (this.showDetailModal) {
        this.closeDetailModal();
      }
    }
  }
}
