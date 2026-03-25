> [!WARNING]
> Legacy document notice: This file is kept for history and may be outdated.
> Use `/Users/sotheakh/Documents/develop/sv-tms/docs/README.md` for active documentation.

# 💻 Documents Page - Implementation Code Examples

**Guide:** Copy-paste ready code for top 5 improvements

---

## 1️⃣ Better Error Handling

### Step 1: Update driver.service.ts

```typescript
// Add this helper method to driver.service.ts

/**
 * Extract detailed error message from HTTP response
 */
private getDetailedErrorMessage(error: any): string {
  // Network error
  if (error.status === 0) {
    return 'Network connection error. Please check your internet connection.';
  }

  // Validation/Bad Request
  if (error.status === 400) {
    if (error.error?.errors) {
      return Array.isArray(error.error.errors)
        ? error.error.errors.join(', ')
        : error.error.errors;
    }
    return error.error?.message || 'Invalid input. Please check your data.';
  }

  // Unauthorized
  if (error.status === 401) {
    return 'Your session has expired. Please log in again.';
  }

  // Forbidden
  if (error.status === 403) {
    return 'You do not have permission to perform this action.';
  }

  // Not Found
  if (error.status === 404) {
    return 'Document not found. It may have been deleted by another user.';
  }

  // Conflict
  if (error.status === 409) {
    return error.error?.message || 'Document name already exists. Please use a different name.';
  }

  // Payload Too Large
  if (error.status === 413) {
    return 'File is too large. Maximum file size is 10MB.';
  }

  // Server Error
  if (error.status >= 500) {
    return 'Server error. Please try again later or contact support.';
  }

  // Fallback
  return error.error?.message || 'An unexpected error occurred. Please try again.';
}

/**
 * Updated deleteDriverDocument with better error handling
 */
deleteDriverDocument(documentId: number): Observable<ApiResponse<string>> {
  const url = `${this.apiUrl}/documents/${documentId}`;
  return this.http
    .delete<ApiResponse<string>>(url, { headers: this.getHeaders() })
    .pipe(
      tap((res) => {
        console.log('🗑️ Document deleted:', res);
      }),
      catchError((error) => {
        const errorMessage = this.getDetailedErrorMessage(error);
        this.showToast(errorMessage, 'Close', 4000);
        console.error('Error deleting document:', error);
        return throwError(() => error);
      })
    );
}

/**
 * Updated updateDriverDocument with better error handling
 */
updateDriverDocument(documentId: number, document: DriverDocument): Observable<ApiResponse<DriverDocument>> {
  const url = `${this.apiUrl}/documents/${documentId}`;
  return this.http
    .put<ApiResponse<DriverDocument>>(url, document, { headers: this.getHeaders() })
    .pipe(
      tap((res) => {
        console.log('📝 Document updated:', res);
      }),
      catchError((error) => {
        const errorMessage = this.getDetailedErrorMessage(error);
        this.showToast(errorMessage, 'Close', 4000);
        console.error('Error updating document:', error);
        return throwError(() => error);
      })
    );
}

/**
 * Updated uploadDocumentWithFile with better error handling
 */
uploadDocumentWithFile(
  driverId: number,
  file: File,
  name: string,
  category: string,
  expiryDate?: string,
  description?: string,
  isRequired: boolean = false
): Observable<ApiResponse<DriverDocument>> {
  const formData = new FormData();
  formData.append('file', file);
  formData.append('name', name);
  formData.append('category', category);
  if (expiryDate) formData.append('expiryDate', expiryDate);
  if (description) formData.append('description', description);
  formData.append('isRequired', String(isRequired));

  const url = `${this.apiUrl}/${driverId}/documents/upload`;
  const headers = new HttpHeaders({
    Authorization: `Bearer ${this.authService.getToken() || ''}`
  });

  return this.http
    .post<ApiResponse<DriverDocument>>(url, formData, { headers })
    .pipe(
      tap((res) => {
        console.log('📎 Document uploaded:', res);
      }),
      catchError((error) => {
        const errorMessage = this.getDetailedErrorMessage(error);
        
        // Special handling for file size
        if (file.size > 10 * 1024 * 1024) {
          this.showToast('File is too large. Maximum size is 10MB.', 'Close', 4000);
        } else {
          this.showToast(errorMessage, 'Close', 4000);
        }
        
        console.error('Error uploading document:', error);
        return throwError(() => error);
      })
    );
}
```

### Step 2: No changes needed in component
The improved error messages will automatically display in toasts.

---

## 2️⃣ Add Audit Trail (Updated By, Updated At)

### Step 1: Backend - Update DriverDocument Entity

```java
@Entity
@Table(name = "driver_documents")
public class DriverDocument {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "name", nullable = false)
    private String name;

    @Column(name = "category", nullable = false)
    private String category;

    @Column(name = "description")
    private String description;

    @Column(name = "file_url")
    private String fileUrl;

    @Column(name = "expiry_date")
    @Temporal(TemporalType.DATE)
    private Date expiryDate;

    @Column(name = "is_required")
    private boolean isRequired;

    @Column(name = "notes")
    private String notes;

    @Column(name = "upload_date")
    @Temporal(TemporalType.TIMESTAMP)
    private Date uploadDate;

    // ===== NEW FIELDS FOR AUDIT TRAIL =====
    @Column(name = "updated_by")
    private String updatedBy;

    @Column(name = "updated_at")
    @Temporal(TemporalType.TIMESTAMP)
    private Date updatedAt;

    @Column(name = "created_by")
    private String createdBy;

    @Column(name = "created_at")
    @Temporal(TemporalType.TIMESTAMP)
    private Date createdAt;

    // ... existing fields ...

    @PrePersist
    protected void onCreate() {
        createdAt = new Date();
        updatedAt = new Date();
        // Set createdBy from SecurityContext if needed
    }

    @PreUpdate
    protected void onUpdate() {
        updatedAt = new Date();
        // Set updatedBy from SecurityContext if needed
    }

    // Getters and Setters
    public String getUpdatedBy() { return updatedBy; }
    public void setUpdatedBy(String updatedBy) { this.updatedBy = updatedBy; }

    public Date getUpdatedAt() { return updatedAt; }
    public void setUpdatedAt(Date updatedAt) { this.updatedAt = updatedAt; }

    public String getCreatedBy() { return createdBy; }
    public void setCreatedBy(String createdBy) { this.createdBy = createdBy; }

    public Date getCreatedAt() { return createdAt; }
    public void setCreatedAt(Date createdAt) { this.createdAt = createdAt; }
}
```

### Step 2: Backend - Update DriverDocumentService

```java
@Service
@Transactional
public class DriverDocumentService {
    
    @Autowired
    private DriverDocumentRepository driverDocumentRepository;
    
    @Autowired
    private SecurityContext securityContext; // Or your auth service

    /**
     * Update document with audit trail
     */
    public DriverDocument updateDocument(Long documentId, Long driverId, DriverDocument documentDetails) {
        DriverDocument document = driverDocumentRepository.findById(documentId)
            .orElseThrow(() -> new ResourceNotFoundException("Document not found with id: " + documentId));

        // Update fields
        if (documentDetails.getName() != null) {
            document.setName(documentDetails.getName());
        }
        if (documentDetails.getCategory() != null) {
            document.setCategory(documentDetails.getCategory());
        }
        if (documentDetails.getDescription() != null) {
            document.setDescription(documentDetails.getDescription());
        }
        if (documentDetails.getExpiryDate() != null) {
            document.setExpiryDate(documentDetails.getExpiryDate());
        }
        document.setRequired(documentDetails.isRequired());
        if (documentDetails.getNotes() != null) {
            document.setNotes(documentDetails.getNotes());
        }

        // ===== ADD AUDIT TRAIL =====
        String username = getCurrentUsername(); // Get from SecurityContext
        document.setUpdatedBy(username);
        document.setUpdatedAt(new Date());
        // Note: @PreUpdate will also set updatedAt

        return driverDocumentRepository.save(document);
    }

    /**
     * Delete document with audit trail (soft delete option)
     */
    public void deleteDocument(Long documentId, Long driverId) {
        DriverDocument document = driverDocumentRepository.findById(documentId)
            .orElseThrow(() -> new ResourceNotFoundException("Document not found with id: " + documentId));

        // Option 1: Hard delete
        driverDocumentRepository.deleteById(documentId);

        // Option 2: Soft delete (recommended)
        // document.setDeleted(true);
        // document.setDeletedBy(getCurrentUsername());
        // document.setDeletedAt(new Date());
        // driverDocumentRepository.save(document);
    }

    /**
     * Get current authenticated username
     */
    private String getCurrentUsername() {
        Authentication authentication = SecurityContextHolder.getContext().getAuthentication();
        if (authentication != null && authentication.isAuthenticated()) {
            return authentication.getName();
        }
        return "SYSTEM";
    }
}
```

### Step 3: Frontend - Update Model

```typescript
// driver-document.model.ts
export interface DriverDocument {
  id?: number;
  name: string;
  category: string;
  description?: string;
  expiryDate?: string;
  isRequired: boolean;
  notes?: string;
  driverId: number;
  fileUrl: string;
  uploadDate: string;

  // ===== NEW AUDIT FIELDS =====
  updatedBy?: string;
  updatedAt?: string;
  createdBy?: string;
  createdAt?: string;
}
```

### Step 4: Frontend - Update Template

```html
<!-- In document detail modal, add this section -->

<div class="border-t pt-4 mt-4">
  <h4 class="text-sm font-medium text-gray-500 uppercase tracking-wide mb-3">Audit Information</h4>
  
  <div class="grid grid-cols-2 gap-4 text-sm">
    <!-- Created Info -->
    <div>
      <p class="text-gray-500">Created By</p>
      <p class="font-medium">{{ selectedDocument.createdBy || 'Unknown' }}</p>
    </div>
    <div>
      <p class="text-gray-500">Created On</p>
      <p class="font-medium">{{ selectedDocument.createdAt | date:'medium' }}</p>
    </div>

    <!-- Updated Info -->
    <div *ngIf="selectedDocument.updatedBy">
      <p class="text-gray-500">Last Updated By</p>
      <p class="font-medium">{{ selectedDocument.updatedBy }}</p>
    </div>
    <div *ngIf="selectedDocument.updatedAt">
      <p class="text-gray-500">Last Updated</p>
      <p class="font-medium">{{ selectedDocument.updatedAt | date:'medium' }}</p>
    </div>
  </div>
</div>
```

---

## 3️⃣ Add Bulk Operations

### Step 1: Update Component TypeScript

```typescript
// In driver-documents-tab.component.ts

export class DriverDocumentsTabComponent implements OnInit {
  // ... existing properties ...

  // ===== NEW: Bulk operations =====
  selectedDocuments = new Set<number>();
  isBulkSelectMode = false;

  // Toggle document selection
  toggleDocumentSelection(documentId: number, checked: boolean): void {
    if (checked) {
      this.selectedDocuments.add(documentId);
    } else {
      this.selectedDocuments.delete(documentId);
    }
    this.isBulkSelectMode = this.selectedDocuments.size > 0;
  }

  // Select all visible documents
  selectAllVisible(): void {
    this.filteredDocuments.forEach(doc => {
      if (doc.id) this.selectedDocuments.add(doc.id);
    });
    this.isBulkSelectMode = true;
  }

  // Deselect all
  deselectAll(): void {
    this.selectedDocuments.clear();
    this.isBulkSelectMode = false;
  }

  // Bulk delete
  bulkDelete(): void {
    if (this.selectedDocuments.size === 0) return;

    const count = this.selectedDocuments.size;
    if (!confirm(`Delete ${count} document(s)? This action cannot be undone.`)) {
      return;
    }

    this.isLoading = true;
    const ids = Array.from(this.selectedDocuments);

    this.driverService.bulkDeleteDocuments(ids).subscribe({
      next: () => {
        this.loadDocuments();
        this.selectedDocuments.clear();
        this.isBulkSelectMode = false;
        this.driverService.showToast(`Deleted ${count} document(s)`);
        this.isLoading = false;
      },
      error: (error) => {
        console.error('Error bulk deleting documents:', error);
        this.driverService.showToast('Failed to delete documents');
        this.isLoading = false;
      }
    });
  }

  // Bulk extend expiry date
  bulkExtendExpiry(days: number): void {
    if (this.selectedDocuments.size === 0) return;

    this.isLoading = true;
    const ids = Array.from(this.selectedDocuments);
    const newDate = new Date();
    newDate.setDate(newDate.getDate() + days);

    const payload = {
      expiryDate: newDate.toISOString().split('T')[0]
    };

    this.driverService.bulkUpdateDocuments(ids, payload).subscribe({
      next: () => {
        this.loadDocuments();
        this.selectedDocuments.clear();
        this.isBulkSelectMode = false;
        this.driverService.showToast(
          `Extended expiry for ${ids.length} document(s) by ${days} days`
        );
        this.isLoading = false;
      },
      error: (error) => {
        console.error('Error bulk updating documents:', error);
        this.driverService.showToast('Failed to update documents');
        this.isLoading = false;
      }
    });
  }

  // Download multiple documents as ZIP
  bulkDownload(): void {
    if (this.selectedDocuments.size === 0) return;

    const ids = Array.from(this.selectedDocuments);
    this.driverService.downloadDocumentsZip(ids).subscribe({
      next: (blob) => {
        const url = window.URL.createObjectURL(blob);
        const a = document.createElement('a');
        a.href = url;
        a.download = `documents-${new Date().getTime()}.zip`;
        a.click();
        window.URL.revokeObjectURL(url);
      },
      error: (error) => {
        console.error('Error downloading documents:', error);
        this.driverService.showToast('Failed to download documents');
      }
    });
  }
}
```

### Step 2: Add Methods to driver.service.ts

```typescript
/**
 * Bulk delete documents
 */
bulkDeleteDocuments(documentIds: number[]): Observable<ApiResponse<string>> {
  const url = `${this.apiUrl}/documents/bulk-delete`;
  return this.http
    .post<ApiResponse<string>>(url, { ids: documentIds }, { headers: this.getHeaders() })
    .pipe(
      tap((res) => console.log('📚 Bulk delete successful:', res)),
      catchError((error) => {
        const errorMessage = this.getDetailedErrorMessage(error);
        this.showToast(errorMessage);
        return throwError(() => error);
      })
    );
}

/**
 * Bulk update documents
 */
bulkUpdateDocuments(
  documentIds: number[],
  updates: Partial<DriverDocument>
): Observable<ApiResponse<DriverDocument[]>> {
  const url = `${this.apiUrl}/documents/bulk-update`;
  const payload = { ids: documentIds, updates };
  
  return this.http
    .put<ApiResponse<DriverDocument[]>>(url, payload, { headers: this.getHeaders() })
    .pipe(
      tap((res) => console.log('📚 Bulk update successful:', res)),
      catchError((error) => {
        const errorMessage = this.getDetailedErrorMessage(error);
        this.showToast(errorMessage);
        return throwError(() => error);
      })
    );
}

/**
 * Download multiple documents as ZIP
 */
downloadDocumentsZip(documentIds: number[]): Observable<Blob> {
  const url = `${this.apiUrl}/documents/bulk-download`;
  const params = new HttpParams().set('ids', documentIds.join(','));
  
  return this.http.get<Blob>(url, {
    headers: this.getHeaders(),
    params,
    responseType: 'blob' as any
  }).pipe(
    catchError((error) => {
      this.showToast('Failed to download documents');
      return throwError(() => error);
    })
  );
}
```

### Step 3: Update HTML Template

```html
<!-- Add bulk actions toolbar above document grid -->

<div *ngIf="isBulkSelectMode" class="mb-6 p-4 bg-blue-50 border border-blue-200 rounded-lg">
  <div class="flex flex-col gap-3 md:flex-row md:items-center md:justify-between">
    <div class="text-sm font-medium text-gray-900">
      {{ selectedDocuments.size }} document(s) selected
    </div>

    <div class="flex flex-wrap gap-2">
      <!-- Extend Expiry -->
      <button
        (click)="bulkExtendExpiry(30)"
        [disabled]="isLoading"
        class="px-3 py-1 text-sm bg-blue-600 text-white rounded hover:bg-blue-700 disabled:opacity-50"
        title="Extend expiry by 30 days"
      >
        📅 Extend 30 days
      </button>

      <!-- Bulk Download -->
      <button
        (click)="bulkDownload()"
        [disabled]="isLoading"
        class="px-3 py-1 text-sm bg-green-600 text-white rounded hover:bg-green-700 disabled:opacity-50"
      >
        📥 Download ZIP
      </button>

      <!-- Bulk Delete -->
      <button
        (click)="bulkDelete()"
        [disabled]="isLoading"
        class="px-3 py-1 text-sm bg-red-600 text-white rounded hover:bg-red-700 disabled:opacity-50"
      >
        🗑️ Delete
      </button>

      <!-- Clear Selection -->
      <button
        (click)="deselectAll()"
        [disabled]="isLoading"
        class="px-3 py-1 text-sm bg-gray-400 text-white rounded hover:bg-gray-500"
      >
        Cancel
      </button>
    </div>
  </div>
</div>

<!-- Document Grid - Add checkboxes -->
<div class="grid grid-cols-1 gap-4 md:grid-cols-2 lg:grid-cols-3">
  <div
    *ngFor="let document of filteredDocuments"
    class="relative p-4 border rounded-lg hover:shadow-md transition-shadow"
    [ngClass]="{
      'border-red-300 bg-red-50': isExpired(document),
      'border-yellow-300 bg-yellow-50': isExpiringSoon(document) && !isExpired(document),
      'border-blue-300 bg-blue-100': selectedDocuments.has(document.id!),
      'border-gray-200': !isExpired(document) && !isExpiringSoon(document) && !selectedDocuments.has(document.id!)
    }"
  >
    <!-- Checkbox -->
    <div class="absolute top-3 right-3">
      <input
        type="checkbox"
        [checked]="selectedDocuments.has(document.id!)"
        (change)="toggleDocumentSelection(document.id!, $event.target.checked)"
        class="h-4 w-4 text-blue-600 rounded focus:ring-blue-500"
      />
    </div>

    <!-- Rest of document card content unchanged -->
    <!-- ... -->
  </div>
</div>
```

---

## 4️⃣ Add ARIA Labels for Accessibility

### Quick Update to Template

```html
<!-- Update all action buttons -->

<!-- Download Button -->
<button
  (click)="$event.stopPropagation(); downloadDocument(document)"
  aria-label="Download {{ document.name }}"
  title="Download {{ document.name }}"
  class="p-1 text-gray-400 hover:text-blue-600 transition-colors"
>
  <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 10v6m0 0l-3-3m3 3l3-3m2 8H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z"></path>
  </svg>
</button>

<!-- Edit Button -->
<button
  (click)="$event.stopPropagation(); editDocument(document)"
  aria-label="Edit {{ document.name }}"
  title="Edit {{ document.name }}"
  class="p-1 text-gray-400 hover:text-green-600 transition-colors"
>
  <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M11 5H6a2 2 0 00-2 2v11a2 2 0 002 2h11a2 2 0 002-2v-5m-1.414-9.414a2 2 0 112.828 2.828L11.828 15H9v-2.828l8.586-8.586z"></path>
  </svg>
</button>

<!-- Delete Button -->
<button
  (click)="$event.stopPropagation(); onDelete(document)"
  aria-label="Delete {{ document.name }}"
  title="Delete {{ document.name }}"
  class="p-1 text-gray-400 hover:text-red-600 transition-colors"
>
  <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 7l-.867 12.142A2 2 0 0116.138 21H7.862a2 2 0 01-1.995-1.858L5 7m5 4v6m4-6v6m1-10V4a1 1 0 00-1-1h-4a1 1 0 00-1 1v3M4 7h16"></path>
  </svg>
</button>

<!-- Make upload zone keyboard accessible -->
<div 
  role="button"
  tabindex="0"
  (click)="fileInput.click()"
  (keydown.enter)="fileInput.click()"
  (keydown.space)="fileInput.click()"
  aria-label="Click to upload document file or drag and drop"
  class="border-2 border-dashed border-gray-300 rounded-lg p-6 hover:border-blue-500 transition-colors cursor-pointer focus:outline-none focus:ring-2 focus:ring-blue-500"
>
  <!-- Content unchanged -->
</div>
```

---

## 5️⃣ Add Loading Skeleton

### Update Component TypeScript

```typescript
// In driver-documents-tab.component.ts

// Create array for skeleton loading
skeletonItems = Array(6).fill(null); // 6 placeholder items
```

### Update Template

```html
<!-- Replace current loading state -->

<!-- OLD: Simple spinner -->
<!-- <div *ngIf="isLoading" class="flex justify-center py-12">
  <div class="animate-spin rounded-full h-8 w-8 border-b-2 border-blue-600"></div>
</div> -->

<!-- NEW: Skeleton loading -->
<div *ngIf="isLoading" class="grid grid-cols-1 gap-4 md:grid-cols-2 lg:grid-cols-3">
  <div *ngFor="let item of skeletonItems" class="animate-pulse">
    <!-- Skeleton Card -->
    <div class="p-4 border border-gray-200 rounded-lg">
      <!-- Header skeleton -->
      <div class="flex items-start justify-between mb-3">
        <div class="flex items-center gap-2">
          <div class="w-8 h-8 bg-gray-200 rounded"></div>
          <div class="flex-1">
            <div class="h-4 bg-gray-200 rounded w-3/4 mb-2"></div>
            <div class="h-3 bg-gray-100 rounded w-1/2"></div>
          </div>
        </div>
        <div class="w-12 h-6 bg-gray-200 rounded"></div>
      </div>

      <!-- Content skeleton -->
      <div class="space-y-2">
        <div class="h-3 bg-gray-100 rounded w-full"></div>
        <div class="h-3 bg-gray-100 rounded w-5/6"></div>
        <div class="h-3 bg-gray-100 rounded w-4/6"></div>
      </div>

      <!-- Footer skeleton -->
      <div class="flex justify-end gap-2 mt-3">
        <div class="w-6 h-6 bg-gray-200 rounded"></div>
        <div class="w-6 h-6 bg-gray-200 rounded"></div>
        <div class="w-6 h-6 bg-gray-200 rounded"></div>
      </div>
    </div>
  </div>
</div>

<!-- Show actual documents when loaded -->
<div *ngIf="!isLoading && filteredDocuments.length > 0" class="grid grid-cols-1 gap-4 md:grid-cols-2 lg:grid-cols-3">
  <!-- ... existing document grid code ... -->
</div>
```

---

## 🎯 Implementation Checklist

```
BETTER ERROR HANDLING
- [ ] Add getDetailedErrorMessage() to driver.service.ts
- [ ] Update all catch() blocks in document methods
- [ ] Test with various error scenarios
- [ ] Time: 1-2 hours

AUDIT TRAIL
- [ ] Backend: Add updatedBy, updatedAt fields
- [ ] Backend: Update @PreUpdate method
- [ ] Frontend: Update DriverDocument model
- [ ] Frontend: Add audit section to detail modal
- [ ] Test: Verify fields populate correctly
- [ ] Time: 3-4 hours

BULK OPERATIONS
- [ ] Add selection state to component
- [ ] Add bulk operation methods to component
- [ ] Add service methods to driver.service.ts
- [ ] Update template with checkboxes
- [ ] Add bulk actions toolbar
- [ ] Backend: Create /bulk-delete endpoint
- [ ] Backend: Create /bulk-update endpoint
- [ ] Backend: Create /bulk-download endpoint
- [ ] Test: Select, bulk delete, bulk update
- [ ] Time: 6-8 hours

ARIA LABELS
- [ ] Add aria-label to all buttons
- [ ] Make upload zone keyboard accessible
- [ ] Add form fieldset and legend
- [ ] Test with screen reader
- [ ] Time: 1-2 hours

LOADING SKELETON
- [ ] Add skeletonItems array to component
- [ ] Replace spinner with skeleton grid
- [ ] Add Tailwind animate-pulse class
- [ ] Test loading states
- [ ] Time: 1 hour
```

---

## 📚 Files Modified Summary

| File | Changes | Lines |
|------|---------|-------|
| `driver.service.ts` | Error handling, bulk operations | +60 |
| `driver-documents-tab.component.ts` | Bulk operations, audit | +50 |
| `driver-documents-tab.component.html` | Checkboxes, toolbar, skeleton, ARIA | +80 |
| `driver-document.model.ts` | Audit fields | +5 |
| Backend: `DriverDocument.java` | Audit fields | +15 |
| Backend: `DriverDocumentService.java` | Audit logic, bulk endpoints | +40 |

**Total Estimated Changes: ~250 lines of code**

---

**Created:** November 15, 2025  
**Status:** Ready to implement  
**Total Implementation Time:** ~12-16 hours (~2 sprint stories)
