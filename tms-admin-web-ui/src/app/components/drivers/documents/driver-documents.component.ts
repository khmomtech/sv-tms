import { CommonModule } from '@angular/common';
import { Component, ViewChild, inject, OnInit, OnDestroy } from '@angular/core';
import { ConfirmService } from '../../../services/confirm.service';
import { FormsModule, ReactiveFormsModule } from '@angular/forms';
import { MatIconModule } from '@angular/material/icon';
import { MatSnackBar } from '@angular/material/snack-bar';
import { MatSnackBarModule } from '@angular/material/snack-bar';
import { DomSanitizer } from '@angular/platform-browser';
import type { SafeResourceUrl } from '@angular/platform-browser';
import { ActivatedRoute } from '@angular/router';
import { HttpEventType } from '@angular/common/http';
import { Subject, takeUntil } from 'rxjs';

import { environment } from '../../../environments/environment';
import type { DriverDocument } from '../../../models/driver-document.model';
import type { ApiResponse } from '../../../models/api-response.model';
import { AuthService } from '../../../services/auth.service';
import { DriverService } from '../../../services/driver.service';
import { DriverAutocompleteComponent } from '../../../shared/components/driver-autocomplete/driver-autocomplete.component';

interface DocumentCategory {
  key: string;
  label: string;
  icon: string;
  description: string;
  color: string;
}

interface DocumentStats {
  total: number;
  expired: number;
  expiringSoon: number;
  active: number;
  required: number;
}

interface ComplianceStatus {
  isCompliant: boolean;
  score: number;
  message: string;
  color: string;
  severity: 'success' | 'warning' | 'danger';
}

@Component({
  selector: 'app-driver-documents',
  standalone: true,
  imports: [
    CommonModule,
    FormsModule,
    ReactiveFormsModule,
    MatIconModule,
    MatSnackBarModule,
    DriverAutocompleteComponent,
  ],
  templateUrl: './driver-documents.component.html',
  styleUrls: ['./driver-documents.component.css'],
})
export class DriverDocumentsComponent implements OnInit, OnDestroy {
  @ViewChild('driverAutocomplete') driverAutocomplete!: DriverAutocompleteComponent;

  // Data
  drivers: any[] = [];
  documents: DriverDocument[] = [];
  filteredDocuments: DriverDocument[] = [];
  selectedDriverId: number | null = null;
  selectedDocument: DriverDocument | null = null;
  // Preview State
  previewLoading = false;
  previewError: string | null = null;
  previewObjectUrl: string | null = null;
  documentStats: DocumentStats = { total: 0, expired: 0, expiringSoon: 0, active: 0, required: 0 };

  // Compliance Status
  complianceStatus: ComplianceStatus = {
    isCompliant: true,
    score: 100,
    message: 'All documents current and compliant',
    color: 'green',
    severity: 'success',
  };

  // UI State
  isLoading = false;
  showDetailModal = false;
  showUploadModal = false;
  showEditModal = false;
  showDeleteConfirm = false;
  isDragging = false;
  uploadProgress = 0;

  // Form Data
  searchTerm = '';
  selectedCategory = '';
  selectedStatus = '';
  dateFrom = '';
  dateTo = '';
  sortBy: 'name' | 'category' | 'expiryDate' | 'uploadDate' | 'driverName' = 'uploadDate';
  sortOrder: 'asc' | 'desc' = 'desc';
  selectedFile: File | null = null;
  uploadCategory = ''; // Category selected in upload modal
  uploadExpiryDate = ''; // Expiry date selected in upload modal

  // Edit Form Data
  editingDocument: DriverDocument | null = null;
  editName = '';
  editCategory = '';
  editExpiryDate = '';
  editDescription = '';
  editIsRequired = false;
  editFile: File | null = null;
  editIsDragging = false;

  // Make Math available in template
  Math = Math;

  // Document Categories
  documentCategories: DocumentCategory[] = [
    {
      key: 'license',
      label: 'Driver License',
      icon: '🪪',
      description: 'Primary driving license',
      color: 'blue',
    },
    {
      key: 'insurance',
      label: 'Insurance',
      icon: '🛡️',
      description: 'Vehicle insurance certificate',
      color: 'green',
    },
    {
      key: 'registration',
      label: 'Vehicle Registration',
      icon: '📋',
      description: 'Vehicle registration',
      color: 'purple',
    },
    {
      key: 'medical',
      label: 'Medical Certificate',
      icon: '🏥',
      description: 'Medical fitness certificate',
      color: 'red',
    },
    {
      key: 'training',
      label: 'Training Certificate',
      icon: '🎓',
      description: 'Training or safety certification',
      color: 'amber',
    },
    {
      key: 'passport',
      label: 'Passport',
      icon: '🛂',
      description: 'Personal identification',
      color: 'indigo',
    },
    {
      key: 'permit',
      label: 'Special Permit',
      icon: '⚠️',
      description: 'Special driving permit',
      color: 'orange',
    },
    { key: 'other', label: 'Other', icon: '📄', description: 'Other documents', color: 'gray' },
  ];

  private destroy$ = new Subject<void>();

  private driverService = inject(DriverService);
  private authService = inject(AuthService);
  private snackBar = inject(MatSnackBar);
  private sanitizer = inject(DomSanitizer);
  private route = inject(ActivatedRoute);
  private confirm = inject(ConfirmService);

  ngOnInit(): void {
    // Check authentication before loading
    const token = this.authService.getToken();
    if (!token) {
      console.warn('⚠️ No authentication token found');
      this.snackBar.open('You are not logged in. Please login to view driver documents.', 'Close', {
        duration: 8000,
        panelClass: ['warning-snackbar'],
      });
      return;
    }

    console.log('Authentication token present, loading resolved data...');

    // Get resolved data from route
    const resolvedData = this.route.snapshot.data['driverData'];
    if (resolvedData) {
      this.drivers = resolvedData.drivers || [];

      // Check for resolver errors
      if (resolvedData.error) {
        console.warn('⚠️ Resolver error:', resolvedData.error);
        this.snackBar.open(`Warning: ${resolvedData.error}`, 'Close', {
          duration: 6000,
          panelClass: ['warning-snackbar'],
        });
      }

      console.log('Loaded drivers from resolver:', this.drivers.length);

      // If no drivers found, show a warning but don't fail
      if (this.drivers.length === 0) {
        console.warn('⚠️ No drivers found in the system');
        this.snackBar.open('No drivers found. Please add drivers first.', 'Close', {
          duration: 5000,
          panelClass: ['warning-snackbar'],
        });
        this.isLoading = false;
        return;
      }

      // Then load documents for ALL drivers
      this.loadAllDocuments();
    } else {
      console.warn('⚠️ No resolved data found, falling back to manual loading');
      this.loadAllDriversAndDocuments();
    }
  }

  ngOnDestroy(): void {
    // Clean up object URL to prevent memory leaks
    if (this.previewObjectUrl) {
      URL.revokeObjectURL(this.previewObjectUrl);
      this.previewObjectUrl = null;
    }
    this.destroy$.next();
    this.destroy$.complete();
  }

  loadAllDriversAndDocuments(): void {
    this.isLoading = true;
    console.log('🔄 Starting to load drivers and documents...');

    // First load all drivers
    this.driverService
      .getDrivers(0, 1000)
      .pipe(takeUntil(this.destroy$))
      .subscribe({
        next: (response: any) => {
          // Extract drivers from PageResponse structure with robust validation
          let driversData: any[] = [];

          if (response?.data?.content && Array.isArray(response.data.content)) {
            // Standard PageResponse format
            driversData = response.data.content;
          } else if (response?.data && Array.isArray(response.data)) {
            // Direct array in data property
            driversData = response.data;
          } else if (Array.isArray(response)) {
            // Direct array response
            driversData = response;
          } else {
            console.warn('⚠️ Unexpected driver response structure:', response);
            driversData = [];
          }

          this.drivers = driversData;
          console.log('Loaded drivers for autocomplete:', this.drivers.length);

          // If no drivers found, show a warning but don't fail
          if (this.drivers.length === 0) {
            console.warn('⚠️ No drivers found in the system');
            this.snackBar.open('No drivers found. Please add drivers first.', 'Close', {
              duration: 5000,
              panelClass: ['warning-snackbar'],
            });
            this.isLoading = false;
            return;
          }

          // Then load documents for ALL drivers
          this.loadAllDocuments();
        },
        error: (error: any) => {
          console.error('❌ Error loading drivers:', error);
          console.error('Error details:', {
            status: error.status,
            statusText: error.statusText,
            message: error.message,
            url: error.url,
          });

          this.handleLoadError(error, 'drivers');
        },
      });
  }

  /**
   * Enhanced error handler with retry option
   */
  private handleLoadError(error: any, resourceType: string): void {
    let errorMessage = `Failed to load ${resourceType}. `;
    let showRetry = true;
    let shouldLogout = false;

    // Check for specific database/user lookup errors
    const errorDetails = error.error?.errors || error.error?.message || error.message || '';
    if (errorDetails.includes('Unable to find') && errorDetails.includes('User with id')) {
      errorMessage =
        'Your account information is out of sync. Please log out and log back in to refresh your session.';
      showRetry = false;
      shouldLogout = true;
    } else if (error.status === 0) {
      errorMessage += 'Backend server is not responding. Please ensure the backend is running.';
      showRetry = true;
    } else if (error.status === 401) {
      errorMessage += 'Authentication required. Please login again.';
      showRetry = false;
      shouldLogout = true;
    } else if (error.status === 403) {
      errorMessage +=
        'Access denied. You need DRIVER_VIEW_ALL or DRIVER_MANAGE permission to view driver documents.';
      showRetry = false;
    } else if (error.status === 500) {
      // Check for specific 500 errors that indicate user/account issues
      if (
        errorDetails.includes('User with id') ||
        errorDetails.includes('account') ||
        errorDetails.includes('session')
      ) {
        errorMessage += 'Account synchronization issue. Please log out and log back in.';
        showRetry = false;
        shouldLogout = true;
      } else {
        errorMessage +=
          'Internal server error. This may be due to missing permissions or a database issue. Please check your account permissions.';
        showRetry = true;
      }
    } else if (error.status === 504) {
      errorMessage += 'Request timeout. The server took too long to respond.';
      showRetry = true;
    } else {
      errorMessage += `Error ${error.status}: ${error.statusText}`;
      showRetry = true;
    }

    // Show error with appropriate action
    const action = shouldLogout ? 'Logout' : showRetry ? 'Retry' : 'Close';
    const snackBarRef = this.snackBar.open(errorMessage, action, {
      duration: showRetry || shouldLogout ? 10000 : 8000,
      panelClass: ['error-snackbar'],
    });

    // Handle actions
    if (shouldLogout) {
      snackBarRef.onAction().subscribe(() => {
        console.log('🔐 Logging out due to account sync issue...');
        this.authService.forceClearSession();
        // Optionally redirect to login page
        window.location.href = '/login';
      });
    } else if (showRetry) {
      snackBarRef.onAction().subscribe(() => {
        console.log('🔄 Retrying load operation...');
        this.loadAllDriversAndDocuments();
      });
    }

    this.isLoading = false;

    // Initialize with empty data to allow UI to function
    this.drivers = [];
    this.documents = [];
    this.filteredDocuments = [];
  }

  loadAllDocuments(): void {
    const allDocuments: any[] = [];
    let loadedCount = 0;
    let errorCount = 0;

    if (this.drivers.length === 0) {
      console.log('ℹ️ No drivers available, skipping document load');
      this.isLoading = false;
      return;
    }

    console.log(`🔄 Loading documents for ${this.drivers.length} drivers...`);

    this.drivers.forEach((driver) => {
      // Validate driver has required ID
      if (!driver?.id) {
        console.warn('⚠️ Driver missing ID, skipping document load:', driver);
        loadedCount++;
        errorCount++;
        if (loadedCount === this.drivers.length) {
          this.finalizeDocumentLoad(allDocuments, errorCount);
        }
        return;
      }

      this.driverService
        .getDriverDocuments(driver.id)
        .pipe(takeUntil(this.destroy$))
        .subscribe({
          next: (response: ApiResponse<DriverDocument[]>) => {
            console.log(`📥 Raw API response for driver ${driver.id}:`, response);

            // Validate response structure
            if (!response || typeof response !== 'object') {
              console.error(`❌ Invalid response structure for driver ${driver.id}:`, response);
              errorCount++;
              loadedCount++;
              if (loadedCount === this.drivers.length) {
                this.finalizeDocumentLoad(allDocuments, errorCount);
              }
              return;
            }

            // Extract documents with validation
            let docs: DriverDocument[] = [];
            if (response.data && Array.isArray(response.data)) {
              docs = response.data;
            } else if (Array.isArray(response)) {
              // Fallback for direct array response
              docs = response as any;
            } else {
              console.warn(
                `⚠️ Unexpected document response structure for driver ${driver.id}:`,
                response,
              );
              docs = [];
            }

            console.log(`Extracted ${docs.length} documents for driver ${driver.id}`);

            // Add driver info to each document
            docs.forEach((doc: any) => {
              doc.driverName = `${driver.firstName || ''} ${driver.lastName || ''}`.trim();
              doc.driverId = driver.id;
              allDocuments.push(doc);
            });

            console.log(
              `Loaded ${docs.length} documents for driver ${driver.firstName} ${driver.lastName}`,
            );
            loadedCount++;

            if (loadedCount === this.drivers.length) {
              this.finalizeDocumentLoad(allDocuments, errorCount);
            }
          },
          error: (error: any) => {
            console.error(
              `❌ Error loading documents for driver ${driver.id} (${driver.licenseNumber || 'N/A'} ${driver.firstName} ${driver.lastName}):`,
              error,
            );
            errorCount++;
            loadedCount++;

            if (loadedCount === this.drivers.length) {
              this.finalizeDocumentLoad(allDocuments, errorCount);
            }
          },
        });
    });
  }

  /**
   * Finalize document loading with statistics and user feedback
   */
  private finalizeDocumentLoad(allDocuments: any[], errorCount: number): void {
    this.documents = allDocuments;
    this.calculateStats();
    this.applyFilters();
    this.isLoading = false;

    console.log(`Document loading complete: ${allDocuments.length} total documents loaded`);

    // Show warning if some drivers had errors
    if (errorCount > 0) {
      const successCount = this.drivers.length - errorCount;
      this.snackBar.open(
        `⚠️ Loaded documents for ${successCount}/${this.drivers.length} drivers. Some document requests failed.`,
        'Close',
        { duration: 5000, panelClass: ['warning-snackbar'] },
      );
    }
  }

  calculateStats(): void {
    // Debug: Log each document's expiry status
    console.log('📊 Calculating document stats...');
    this.documents.forEach((doc) => {
      const days = this.getDaysUntilExpiry(doc);
      const expired = this.isExpired(doc);
      const expiringSoon = this.isExpiringSoon(doc);
      console.log(`📄 ${doc.name}:`, {
        expiryDate: doc.expiryDate,
        daysUntilExpiry: days,
        isExpired: expired,
        isExpiringSoon: expiringSoon,
      });
    });

    const expiredDocs = this.documents.filter((doc) => this.isExpired(doc));
    const expiringSoonDocs = this.documents.filter((doc) => this.isExpiringSoon(doc));
    const activeDocs = this.documents.filter(
      (doc) => !this.isExpired(doc) && !this.isExpiringSoon(doc),
    );

    console.log('📊 Stats breakdown:', {
      total: this.documents.length,
      expired: expiredDocs.length,
      expiringSoon: expiringSoonDocs.length,
      active: activeDocs.length,
    });

    this.documentStats = {
      total: this.documents.length,
      expired: expiredDocs.length,
      expiringSoon: expiringSoonDocs.length,
      active: activeDocs.length,
      required: this.documents.filter((doc) => doc.isRequired).length,
    };
    this.updateComplianceStatus();
  }

  updateComplianceStatus(): void {
    const stats = this.documentStats;
    const totalDocs = stats.total;

    // Calculate compliance score
    let score = 100;
    if (totalDocs > 0) {
      score = Math.round(((totalDocs - stats.expired) / totalDocs) * 100);
    }

    // Determine compliance status
    const hasExpired = stats.expired > 0;
    const hasExpiringSoon = stats.expiringSoon > 0;
    const isCompliant = !hasExpired && !hasExpiringSoon;

    this.complianceStatus = {
      isCompliant: isCompliant,
      score: score,
      message: isCompliant
        ? 'All documents current and compliant'
        : hasExpired
          ? `⚠️ ${stats.expired} document(s) expired - Immediate action required`
          : `⏰ ${stats.expiringSoon} document(s) expiring soon - Renew within 30 days`,
      color: isCompliant ? 'green' : hasExpired ? 'red' : 'amber',
      severity: isCompliant ? 'success' : hasExpired ? 'danger' : 'warning',
    };
  }

  applyFilters(): void {
    let filtered = [...this.documents];

    // Search filter
    if (this.searchTerm.trim()) {
      const searchLower = this.searchTerm.toLowerCase();
      filtered = filtered.filter(
        (doc) =>
          doc.name.toLowerCase().includes(searchLower) ||
          doc.description?.toLowerCase().includes(searchLower) ||
          doc.notes?.toLowerCase().includes(searchLower) ||
          (doc as any).driverName?.toLowerCase().includes(searchLower),
      );
    }

    // Driver filter
    if (this.selectedDriverId) {
      filtered = filtered.filter((doc) => (doc as any).driverId === this.selectedDriverId);
    }

    // Category filter
    if (this.selectedCategory) {
      filtered = filtered.filter((doc) => doc.category === this.selectedCategory);
    }

    // Status filter
    if (this.selectedStatus === 'expired') {
      filtered = filtered.filter((doc) => this.isExpired(doc));
    } else if (this.selectedStatus === 'expiring') {
      filtered = filtered.filter((doc) => this.isExpiringSoon(doc));
    } else if (this.selectedStatus === 'active') {
      filtered = filtered.filter((doc) => !this.isExpired(doc) && !this.isExpiringSoon(doc));
    }

    // Date range filter
    if (this.dateFrom) {
      const fromDate = new Date(this.dateFrom);
      filtered = filtered.filter((doc) => {
        const uploadDate = new Date(doc.uploadDate || 0);
        return uploadDate >= fromDate;
      });
    }

    if (this.dateTo) {
      const toDate = new Date(this.dateTo);
      toDate.setHours(23, 59, 59, 999); // End of day
      filtered = filtered.filter((doc) => {
        const uploadDate = new Date(doc.uploadDate || 0);
        return uploadDate <= toDate;
      });
    }

    // Sort
    filtered.sort((a, b) => {
      let compareValue = 0;
      switch (this.sortBy) {
        case 'name':
          compareValue = a.name.localeCompare(b.name);
          break;
        case 'category':
          compareValue = (a.category || '').localeCompare(b.category || '');
          break;
        case 'expiryDate':
          compareValue =
            new Date(a.expiryDate || 0).getTime() - new Date(b.expiryDate || 0).getTime();
          break;
        case 'uploadDate':
          compareValue =
            new Date(b.uploadDate || 0).getTime() - new Date(a.uploadDate || 0).getTime();
          break;
        case 'driverName':
          compareValue = ((a as any).driverName || '').localeCompare((b as any).driverName || '');
          break;
      }
      return this.sortOrder === 'asc' ? compareValue : -compareValue;
    });

    this.filteredDocuments = filtered;
  }

  onSearchChange(): void {
    this.applyFilters();
  }

  onCategoryChange(): void {
    this.applyFilters();
  }

  onStatusChange(): void {
    this.applyFilters();
  }

  onSortChange(): void {
    this.applyFilters();
  }

  onFilterChange(): void {
    this.applyFilters();
  }

  getCategoryIcon(category: string): string {
    return this.documentCategories.find((cat) => cat.key === category)?.icon || '📄';
  }

  getCategoryLabel(category: string): string {
    return this.documentCategories.find((cat) => cat.key === category)?.label || category;
  }

  getDaysUntilExpiry(doc: DriverDocument): number | null {
    if (!doc.expiryDate) return null;
    const expiryDate = new Date(doc.expiryDate);
    const now = new Date();
    const daysUntilExpiry = Math.ceil(
      (expiryDate.getTime() - now.getTime()) / (1000 * 60 * 60 * 24),
    );
    return daysUntilExpiry;
  }

  isExpired(doc: DriverDocument): boolean {
    const days = this.getDaysUntilExpiry(doc);
    return days !== null && days < 0;
  }

  isExpiringSoon(doc: DriverDocument): boolean {
    const days = this.getDaysUntilExpiry(doc);
    return days !== null && days <= 30 && days >= 0;
  }

  getStatusBadgeClass(doc: DriverDocument): string {
    if (this.isExpired(doc)) return 'bg-red-100 text-red-700 border-red-300';
    if (this.isExpiringSoon(doc)) return 'bg-yellow-100 text-yellow-700 border-yellow-300';
    return 'bg-green-100 text-green-700 border-green-300';
  }

  getStatusLabel(doc: DriverDocument): string {
    if (this.isExpired(doc)) return 'Expired';
    if (this.isExpiringSoon(doc)) {
      const days = this.getDaysUntilExpiry(doc);
      return `Expires in ${days} day${days !== 1 ? 's' : ''}`;
    }
    return 'Active';
  }

  viewDocument(doc: DriverDocument): void {
    this.selectedDocument = doc;
    this.previewError = null;
    this.previewLoading = true;
    this.showDetailModal = true;

    // Always load via blob download for proper auth and URL handling
    this.loadBlobPreview(doc);
  }

  downloadDocument(doc: DriverDocument, event: Event): void {
    event.stopPropagation();
    if (!doc.driverId || !doc.id) {
      this.snackBar.open('Missing driver/document ID', 'Close', { duration: 3000 });
      return;
    }
    this.previewLoading = true;
    this.driverService
      .downloadDriverDocument(doc.driverId, doc.id)
      .pipe(takeUntil(this.destroy$))
      .subscribe({
        next: (blob: Blob) => {
          const objectUrl = URL.createObjectURL(blob);
          const a = document.createElement('a');
          a.href = objectUrl;
          a.download = doc.fileName || doc.name || 'document';
          a.click();
          setTimeout(() => URL.revokeObjectURL(objectUrl), 5000);
          this.previewLoading = false;
          this.snackBar.open('Document downloaded', 'Close', { duration: 2000 });
        },
        error: (error: any) => {
          console.error('Download failed:', error);
          this.previewLoading = false;
          this.snackBar.open('Failed to download document', 'Close', { duration: 3000 });
        },
      });
  }

  editDocument(doc: DriverDocument, event: Event): void {
    event.stopPropagation();
    this.editingDocument = doc;
    this.editName = doc.name;
    this.editCategory = doc.category;
    this.editExpiryDate = doc.expiryDate
      ? new Date(doc.expiryDate).toISOString().split('T')[0]
      : '';
    this.editDescription = doc.description || '';
    this.editIsRequired = doc.isRequired || false;
    this.editFile = null;
    this.editIsDragging = false;
    this.showEditModal = true;
  }

  onEditDragOver(event: DragEvent): void {
    event.preventDefault();
    event.stopPropagation();
    this.editIsDragging = true;
  }

  onEditDragLeave(event: DragEvent): void {
    event.preventDefault();
    event.stopPropagation();
    this.editIsDragging = false;
  }

  onEditDrop(event: DragEvent): void {
    event.preventDefault();
    event.stopPropagation();
    this.editIsDragging = false;
    const files = event.dataTransfer?.files;
    if (files && files.length > 0) {
      this.editFile = files[0];
    }
  }

  onEditFileSelected(event: Event): void {
    const input = event.target as HTMLInputElement;
    if (input.files && input.files.length > 0) {
      this.editFile = input.files[0];
    }
  }

  saveDocumentEdit(): void {
    if (!this.editingDocument) return;

    // Validation
    if (!this.editName.trim()) {
      this.snackBar.open('⚠️ Document name is required', 'Close', { duration: 3000 });
      return;
    }

    if (!this.editCategory) {
      this.snackBar.open('⚠️ Please select a category', 'Close', { duration: 3000 });
      return;
    }

    this.isLoading = true;

    // If a new file is selected, upload it as a replacement
    if (this.editFile) {
      // File size validation (50MB limit)
      const maxSizeInBytes = 50 * 1024 * 1024;
      if (this.editFile.size > maxSizeInBytes) {
        this.snackBar.open(
          '❌ File size exceeds 50MB limit. Please choose a smaller file.',
          'Close',
          { duration: 5000, panelClass: ['error-snackbar'] },
        );
        this.isLoading = false;
        return;
      }

      // File type validation
      const allowedTypes = [
        'application/pdf',
        'application/msword',
        'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
        'application/vnd.ms-excel',
        'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
        'image/jpeg',
        'image/jpg',
        'image/png',
        'image/gif',
        'application/zip',
        'application/x-zip-compressed',
      ];

      if (!allowedTypes.includes(this.editFile.type)) {
        console.warn('File type not in allowed list:', this.editFile.type);
        // Show warning and allow user to continue
        const snackBarRef = this.snackBar.open(
          `⚠️ File type "${this.editFile.type}" may not be supported. Continue anyway?`,
          'Continue',
          { duration: 8000 },
        );

        snackBarRef.onAction().subscribe(() => {
          this.performEditWithFileReplacement();
        });
        this.isLoading = false;
        return;
      }

      this.performEditWithFileReplacement();
    } else {
      // Just update metadata without changing the file
      this.performEditMetadataOnly();
    }
  }

  /**
   * Perform edit operation with file replacement
   */
  private performEditWithFileReplacement(): void {
    if (!this.editingDocument || !this.editFile) return;

    this.isLoading = true;

    // Use file replacement endpoint to preserve document ID
    const driverId = this.editingDocument.driverId!;
    const documentId = this.editingDocument.id!;

    this.driverService
      .updateDriverDocumentFile(driverId, documentId, this.editFile, {
        name: this.editName.trim(),
        category: this.editCategory,
        expiryDate: this.editExpiryDate || undefined,
        description: this.editDescription?.trim() || undefined,
        isRequired: this.editIsRequired,
      })
      .pipe(takeUntil(this.destroy$))
      .subscribe({
        next: () => {
          this.snackBar.open('Document updated with new file successfully', 'Close', {
            duration: 3000,
            panelClass: ['success-snackbar'],
          });
          this.closeEditModal();
          this.loadAllDocuments();
        },
        error: (error: any) => {
          console.error('Error updating document with file:', error);
          const errorMessage = error.error?.message || 'Failed to update document';
          this.snackBar.open(`❌ ${errorMessage}`, 'Close', {
            duration: 5000,
            panelClass: ['error-snackbar'],
          });
          this.isLoading = false;
        },
      });
  }

  /**
   * Perform edit operation with metadata only (no file replacement)
   */
  private performEditMetadataOnly(): void {
    if (!this.editingDocument) return;

    this.isLoading = true;

    // Just update metadata without changing the file
    const updateDto = {
      name: this.editName.trim(),
      category: this.editCategory,
      expiryDate: this.editExpiryDate || undefined,
      description: this.editDescription.trim() || undefined,
      isRequired: this.editIsRequired,
    };

    const driverId = this.editingDocument.driverId!;
    const documentId = this.editingDocument.id!;

    this.driverService
      .updateDriverDocument(driverId, documentId, updateDto)
      .pipe(takeUntil(this.destroy$))
      .subscribe({
        next: () => {
          this.snackBar.open('Document updated successfully', 'Close', {
            duration: 3000,
            panelClass: ['success-snackbar'],
          });
          this.closeEditModal();
          this.loadAllDocuments();
        },
        error: (error: any) => {
          console.error('Error updating document:', error);
          const errorMessage = error.error?.message || 'Failed to update document';
          this.snackBar.open(`❌ ${errorMessage}`, 'Close', {
            duration: 5000,
            panelClass: ['error-snackbar'],
          });
          this.isLoading = false;
        },
      });
  }

  closeEditModal(): void {
    this.showEditModal = false;
    this.editingDocument = null;
    this.editName = '';
    this.editCategory = '';
    this.editExpiryDate = '';
    this.editDescription = '';
    this.editIsRequired = false;
    this.editFile = null;
    this.editIsDragging = false;
  }

  async deleteDocument(doc: DriverDocument, event: Event): Promise<void> {
    event.stopPropagation();
    const ok = await this.confirm.confirm(`Are you sure you want to delete "${doc.name}"?`);
    if (!ok) return;
    this.isLoading = true;
    if (!doc.driverId || !doc.id) {
      this.snackBar.open('Missing driver or document ID', 'Close', { duration: 2500 });
      this.isLoading = false;
      return;
    }
    this.driverService
      .deleteDriverDocument(doc.driverId, doc.id)
      .pipe(takeUntil(this.destroy$))
      .subscribe({
        next: () => {
          this.snackBar.open('Document deleted successfully', 'Close', { duration: 2000 });
          this.loadAllDocuments();
        },
        error: (error: any) => {
          console.error('Error deleting document:', error);
          this.snackBar.open('Failed to delete document', 'Close', { duration: 3000 });
          this.isLoading = false;
        },
      });
  }

  closeDetailModal(): void {
    this.showDetailModal = false;
    this.selectedDocument = null;
    if (this.previewObjectUrl) {
      URL.revokeObjectURL(this.previewObjectUrl);
      this.previewObjectUrl = null;
    }
    this.previewLoading = false;
    this.previewError = null;
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

  onDrop(event: DragEvent): void {
    event.preventDefault();
    event.stopPropagation();
    this.isDragging = false;
    const files = event.dataTransfer?.files;
    if (files && files.length > 0) {
      this.selectedFile = files[0];
    }
  }

  onFileSelected(event: Event): void {
    const input = event.target as HTMLInputElement;
    if (input.files && input.files.length > 0) {
      this.selectedFile = input.files[0];
    }
  }

  uploadDocument(): void {
    // Validation
    if (!this.selectedFile) {
      this.snackBar.open('⚠️ Please select a file to upload', 'Close', { duration: 3000 });
      return;
    }

    if (!this.selectedDriverId) {
      this.snackBar.open('⚠️ Please select a driver', 'Close', { duration: 3000 });
      return;
    }

    if (!this.uploadCategory) {
      this.snackBar.open('⚠️ Please select a document category', 'Close', { duration: 3000 });
      return;
    }

    // File size validation (50MB limit)
    const maxSizeInBytes = 50 * 1024 * 1024; // 50MB
    if (this.selectedFile.size > maxSizeInBytes) {
      this.snackBar.open(
        '❌ File size exceeds 50MB limit. Please choose a smaller file.',
        'Close',
        {
          duration: 5000,
          panelClass: ['error-snackbar'],
        },
      );
      return;
    }

    // File type validation
    const allowedTypes = [
      'application/pdf',
      'application/msword',
      'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
      'application/vnd.ms-excel',
      'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
      'image/jpeg',
      'image/jpg',
      'image/png',
      'image/gif',
      'application/zip',
      'application/x-zip-compressed',
    ];

    if (!allowedTypes.includes(this.selectedFile.type)) {
      console.warn('File type not in allowed list:', this.selectedFile.type);
      // Still allow upload but show warning
      const snackBarRef = this.snackBar.open(
        `⚠️ File type "${this.selectedFile.type}" may not be supported. Continue anyway?`,
        'Continue',
        { duration: 8000 },
      );

      snackBarRef.onAction().subscribe(() => {
        this.performUpload();
      });
      return;
    }

    this.performUpload();
  }

  /**
   * Perform the actual upload operation
   */
  private performUpload(): void {
    if (!this.selectedFile || !this.selectedDriverId) return;

    this.isLoading = true;
    this.uploadProgress = 0;

    const uploadStartTime = Date.now();

    // Use the newer upload method that supports expiry date
    const documentName = this.selectedFile.name;
    this.driverService
      .uploadDriverDocumentWithProgress(this.selectedDriverId, this.selectedFile, {
        name: documentName,
        category: this.uploadCategory,
        expiryDate: this.uploadExpiryDate || undefined,
        description: undefined,
        isRequired: false,
      })
      .pipe(takeUntil(this.destroy$))
      .subscribe({
        next: (event) => {
          if (event.type === HttpEventType.UploadProgress) {
            const total = event.total || 1;
            this.uploadProgress = Math.min(100, Math.round((event.loaded / total) * 100));
            return;
          }

          if (event.type === HttpEventType.Response) {
            const uploadDuration = ((Date.now() - uploadStartTime) / 1000).toFixed(1);
            this.snackBar.open(`Document uploaded successfully in ${uploadDuration}s`, 'Close', {
              duration: 3000,
              panelClass: ['success-snackbar'],
            });

            // Reset form
            this.selectedFile = null;
            this.uploadCategory = '';
            this.uploadExpiryDate = '';
            this.uploadProgress = 100;
            this.showUploadModal = false;

            // Reload documents
            this.loadAllDocuments();
          }
        },
        error: (error: any) => {
          console.error('Error uploading document:', error);

          let errorMessage = 'Failed to upload document. ';
          if (error.status === 413) {
            errorMessage = '❌ File is too large. Maximum file size is 50MB.';
          } else if (error.status === 415) {
            errorMessage = '❌ Unsupported file type. Please check the file format.';
          } else if (error.status === 400) {
            errorMessage = `❌ ${error.error?.message || 'Invalid request. Please check your inputs.'}`;
          } else if (error.status === 500) {
            errorMessage = '❌ Server error. Please try again later.';
          } else if (error.status === 0) {
            errorMessage = '❌ Network error. Please check your connection.';
          } else {
            errorMessage += error.error?.message || error.message || 'Unknown error occurred.';
          }

          const snackBarRef = this.snackBar.open(errorMessage, 'Retry', {
            duration: 8000,
            panelClass: ['error-snackbar'],
          });

          snackBarRef.onAction().subscribe(() => {
            this.performUpload();
          });

          this.isLoading = false;
          this.uploadProgress = 0;
        },
      });
  }

  getFileSize(bytes: number): string {
    if (bytes === 0) return '0 B';
    const k = 1024;
    const sizes = ['B', 'KB', 'MB', 'GB'];
    const i = Math.floor(Math.log(bytes) / Math.log(k));
    return Math.round((bytes / Math.pow(k, i)) * 100) / 100 + ' ' + sizes[i];
  }

  getFileIcon(fileName: string): string {
    const ext = fileName.split('.').pop()?.toLowerCase();
    switch (ext) {
      case 'pdf':
        return '📄';
      case 'doc':
      case 'docx':
        return '📝';
      case 'xls':
      case 'xlsx':
        return '📊';
      case 'jpg':
      case 'jpeg':
      case 'png':
      case 'gif':
        return '🖼️';
      case 'zip':
      case 'rar':
        return '📦';
      default:
        return '📎';
    }
  }

  clearSearch(): void {
    this.searchTerm = '';
    this.applyFilters();
  }

  clearFilters(): void {
    this.searchTerm = '';
    this.selectedCategory = '';
    this.selectedStatus = '';
    this.selectedDriverId = null;
    this.dateFrom = '';
    this.dateTo = '';
    this.sortBy = 'uploadDate';
    this.sortOrder = 'desc';
    this.applyFilters();
  }

  // Live search handler for driver autocomplete
  onDriverSearch(searchQuery: string): void {
    console.log('🌐 Searching drivers via API:', searchQuery);

    this.driverService
      .searchDrivers(searchQuery)
      .pipe(takeUntil(this.destroy$))
      .subscribe({
        next: (response: any) => {
          const results = response.data || response || [];
          console.log('API returned', results.length, 'drivers');

          // Update autocomplete with results
          if (this.driverAutocomplete) {
            this.driverAutocomplete.updateSearchResults(results);
          }
        },
        error: (error: any) => {
          console.error('❌ Driver search failed:', error);
          // Update with empty results on error
          if (this.driverAutocomplete) {
            this.driverAutocomplete.updateSearchResults([]);
          }
        },
      });
  }

  getPendingReviewCount(): number {
    // Count documents with 'pending' status
    return this.documents.filter((doc) => {
      const status = this.getStatusLabel(doc).toLowerCase();
      return status.includes('pending') || status.includes('review');
    }).length;
  }

  // Document Preview Helper Methods

  /**
   * Get full URL for file access with authentication token
   */
  getFullFileUrl(relativeUrl: string): string {
    if (!relativeUrl) return '';
    return this.driverService.buildDocumentFileUrl(relativeUrl);
  }

  /**
   * Check if the document is a PDF file
   */
  isPdfDocument(doc: DriverDocument): boolean {
    if (!doc.fileUrl && !doc.fileName) return false;
    const fileName = doc.fileName || doc.fileUrl || '';
    return fileName.toLowerCase().endsWith('.pdf') || doc.mimeType === 'application/pdf';
  }

  /**
   * Check if the document is an image file
   */
  isImageDocument(doc: DriverDocument): boolean {
    if (!doc.fileUrl && !doc.fileName) return false;
    const fileName = doc.fileName || doc.fileUrl || '';
    const imageExtensions = ['.jpg', '.jpeg', '.png', '.gif', '.bmp', '.webp', '.svg'];
    const hasImageExtension = imageExtensions.some((ext) => fileName.toLowerCase().endsWith(ext));
    const hasImageMimeType = doc.mimeType?.startsWith('image/');
    return hasImageExtension || hasImageMimeType || false;
  }

  /**
   * Get safe URL for iframe embedding (for PDF preview)
   */
  getSafeUrl(url: string): SafeResourceUrl {
    return this.sanitizer.bypassSecurityTrustResourceUrl(url);
  }

  /**
   * Get file extension from filename
   */
  getFileExtension(fileName: string): string {
    const parts = fileName.split('.');
    return parts.length > 1 ? parts[parts.length - 1].toUpperCase() : 'UNKNOWN';
  }

  /**
   * Handle image loading errors
   */
  onImageError(event: Event): void {
    const img = event.target as HTMLImageElement;
    img.src =
      'data:image/svg+xml;base64,PHN2ZyB3aWR0aD0iMjAwIiBoZWlnaHQ9IjIwMCIgeG1sbnM9Imh0dHA6Ly93d3cudzMub3JnLzIwMDAvc3ZnIj48cmVjdCB3aWR0aD0iMjAwIiBoZWlnaHQ9IjIwMCIgZmlsbD0iI2YzZjRmNiIvPjx0ZXh0IHg9IjUwJSIgeT0iNTAlIiBmb250LWZhbWlseT0iQXJpYWwiIGZvbnQtc2l6ZT0iMTQiIGZpbGw9IiM5Y2EzYWYiIHRleHQtYW5jaG9yPSJtaWRkbGUiIGR5PSIuM2VtIj5JbWFnZSBub3QgYXZhaWxhYmxlPC90ZXh0Pjwvc3ZnPg==';
    this.snackBar.open('Failed to load image preview', 'Close', { duration: 3000 });
  }

  /**
   * Load document preview by downloading as blob and creating object URL.
   * This ensures proper authentication and works for all file types.
   */
  private loadBlobPreview(doc: DriverDocument): void {
    if (!doc.driverId || !doc.id) {
      this.previewError = 'Missing identifiers for preview.';
      this.previewLoading = false;
      return;
    }
    this.driverService
      .downloadDriverDocument(doc.driverId, doc.id)
      .pipe(takeUntil(this.destroy$))
      .subscribe({
        next: (blob: Blob) => {
          // Revoke previous object URL to prevent memory leaks
          if (this.previewObjectUrl) {
            URL.revokeObjectURL(this.previewObjectUrl);
          }
          // Create new object URL for preview
          this.previewObjectUrl = URL.createObjectURL(blob);
          this.previewLoading = false;
          console.log('Preview loaded successfully for document', doc.id);
        },
        error: (error: any) => {
          console.error('❌ Preview loading failed:', error);
          this.previewError =
            'Unable to load preview. ' +
            (error.error?.message || error.message || 'Please try downloading the file.');
          this.previewLoading = false;
        },
      });
  }

  /**
   * Open document in new tab using blob download
   */
  openInNewTab(doc: DriverDocument): void {
    if (!doc.driverId || !doc.id) {
      this.snackBar.open('Missing document information', 'Close', { duration: 3000 });
      return;
    }

    this.previewLoading = true;
    this.driverService
      .downloadDriverDocument(doc.driverId, doc.id)
      .pipe(takeUntil(this.destroy$))
      .subscribe({
        next: (blob: Blob) => {
          const objectUrl = URL.createObjectURL(blob);
          window.open(objectUrl, '_blank');
          // Clean up object URL after a delay
          setTimeout(() => URL.revokeObjectURL(objectUrl), 10000);
          this.previewLoading = false;
        },
        error: (error: any) => {
          console.error('Failed to open document:', error);
          this.snackBar.open('Failed to open document', 'Close', { duration: 3000 });
          this.previewLoading = false;
        },
      });
  }

  /**
   * Get preview URL - uses object URL from blob download
   */
  getPreviewUrl(): string {
    return this.previewObjectUrl || '';
  }
}
