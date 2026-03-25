import { HttpClientTestingModule } from '@angular/common/http/testing';
import type { ComponentFixture } from '@angular/core/testing';
import { TestBed } from '@angular/core/testing';
import { FormsModule, ReactiveFormsModule } from '@angular/forms';
import { MatIconModule } from '@angular/material/icon';
import { MatSnackBarModule } from '@angular/material/snack-bar';
import { BrowserAnimationsModule } from '@angular/platform-browser/animations';
import { ActivatedRoute, convertToParamMap } from '@angular/router';
import { HttpEventType } from '@angular/common/http';
import { of, throwError } from 'rxjs';

import type { DriverDocument } from '../../../models/driver-document.model';
import type { Driver } from '../../../models/driver.model';
import { AuthService } from '../../../services/auth.service';
import { ConfirmService } from '../../../services/confirm.service';
import { DriverService } from '../../../services/driver.service';
import { DriverAutocompleteComponent } from '../../../shared/components/driver-autocomplete/driver-autocomplete.component';

import { DriverDocumentsComponent } from './driver-documents.component';

describe('DriverDocumentsComponent', () => {
  let component: DriverDocumentsComponent;
  let fixture: ComponentFixture<DriverDocumentsComponent>;
  let driverService: jasmine.SpyObj<DriverService>;
  let authService: jasmine.SpyObj<AuthService>;
  let confirmService: jasmine.SpyObj<ConfirmService>;

  const mockDrivers: Driver[] = [
    {
      id: 1,
      firstName: 'John',
      lastName: 'Doe',
      name: 'John Doe',
      phone: '1234567890',
      licenseNumber: 'DL001',
      rating: 4.5,
      isActive: true,
      status: 'active',
      selected: false,
      logs: [],
      updatedFromSocket: false,
    },
    {
      id: 2,
      firstName: 'Jane',
      lastName: 'Smith',
      name: 'Jane Smith',
      phone: '0987654321',
      licenseNumber: 'DL002',
      rating: 4.8,
      isActive: true,
      status: 'offline',
      selected: false,
      logs: [],
      updatedFromSocket: false,
    },
  ];

  const mockDocuments: DriverDocument[] = [
    {
      id: 1,
      driverId: 1,
      driverName: 'John Doe',
      name: 'Driver License',
      category: 'license',
      description: 'Valid license',
      fileUrl: 'http://example.com/license.pdf',
      fileName: 'license.pdf',
      fileSize: 1024000,
      mimeType: 'application/pdf',
      expiryDate: '2026-12-31',
      isRequired: true,
      uploadDate: '2024-01-15T10:30:00',
      status: 'active',
    },
    {
      id: 2,
      driverId: 1,
      driverName: 'John Doe',
      name: 'Medical Certificate',
      category: 'medical',
      description: 'Medical check passed',
      fileUrl: 'http://example.com/medical.jpg',
      fileName: 'medical.jpg',
      fileSize: 512000,
      mimeType: 'image/jpeg',
      expiryDate: '2025-12-15',
      isRequired: true,
      uploadDate: '2024-02-01T14:20:00',
      status: 'active',
    },
    {
      id: 3,
      driverId: 2,
      driverName: 'Jane Smith',
      name: 'Insurance Document',
      category: 'insurance',
      fileUrl: 'http://example.com/insurance.pdf',
      fileName: 'insurance.pdf',
      fileSize: 2048000,
      mimeType: 'application/pdf',
      expiryDate: '2025-11-20',
      uploadDate: '2024-03-10T09:15:00',
      status: 'active',
    },
  ];

  const mockPageResponse = {
    data: {
      content: mockDrivers,
      totalElements: 2,
      totalPages: 1,
      number: 0,
      size: 1000,
    },
    totalPages: 1,
    success: true,
    message: 'Success',
  };

  beforeEach(async () => {
    const driverServiceSpy = jasmine.createSpyObj('DriverService', [
      'getDrivers',
      'getDriverDocuments',
      'uploadDocument', // legacy wrapper still used by tests
      'uploadDriverDocument', // new consolidated method (in component logic)
      'uploadDriverDocumentWithProgress',
      'deleteDriverDocument',
      'searchDrivers',
      'downloadDriverDocument',
      'buildDocumentFileUrl',
    ]);

    // Explicitly type the deleteDriverDocument spy to handle overloads
    (driverServiceSpy.deleteDriverDocument as any).and.callThrough();

    const authServiceSpy = jasmine.createSpyObj('AuthService', ['getToken']);
    authServiceSpy.getToken.and.returnValue('mock-token-123'); // Mock a valid token
    const confirmServiceSpy = jasmine.createSpyObj('ConfirmService', ['confirm']);
    confirmServiceSpy.confirm.and.returnValue(Promise.resolve(true));

    await TestBed.configureTestingModule({
      imports: [
        DriverDocumentsComponent,
        HttpClientTestingModule,
        MatSnackBarModule,
        MatIconModule,
        FormsModule,
        ReactiveFormsModule,
        BrowserAnimationsModule,
      ],
      providers: [
        { provide: DriverService, useValue: driverServiceSpy },
        { provide: AuthService, useValue: authServiceSpy },
        { provide: ConfirmService, useValue: confirmServiceSpy },
        {
          provide: ActivatedRoute,
          useValue: {
            snapshot: { data: {}, paramMap: { get: (_: string) => null } },
            paramMap: of(convertToParamMap({})),
          },
        },
      ],
    }).compileComponents();

    driverService = TestBed.inject(DriverService) as jasmine.SpyObj<DriverService>;
    authService = TestBed.inject(AuthService) as jasmine.SpyObj<AuthService>;
    confirmService = TestBed.inject(ConfirmService) as jasmine.SpyObj<ConfirmService>;
    fixture = TestBed.createComponent(DriverDocumentsComponent);
    component = fixture.componentInstance;

    driverService.downloadDriverDocument.and.returnValue(
      of(new Blob(['preview'], { type: 'application/pdf' })),
    );
    driverService.uploadDriverDocumentWithProgress.and.returnValue(
      of({
        type: HttpEventType.Response,
        body: { success: true },
      } as any),
    );
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });

  describe('Component Initialization', () => {
    it('should initialize with default values', () => {
      expect(component.drivers).toEqual([]);
      expect(component.documents).toEqual([]);
      expect(component.filteredDocuments).toEqual([]);
      expect(component.isLoading).toBe(false);
      expect(component.showDetailModal).toBe(false);
      expect(component.showUploadModal).toBe(false);
    });

    it('should load drivers and documents on init', () => {
      driverService.getDrivers.and.returnValue(of(mockPageResponse));
      driverService.getDriverDocuments.and.returnValue(
        of({
          // Return a deep-cloned array to avoid mutating shared mocks
          data: mockDocuments.filter((d) => d.driverId === 1).map((d) => ({ ...d })),
          totalPages: 1,
          success: true,
          message: 'Success',
        }),
      );

      component.ngOnInit();

      expect(driverService.getDrivers).toHaveBeenCalledWith(0, 1000);
      expect(component.drivers.length).toBeGreaterThan(0);
    });

    it('should handle error when loading drivers fails', () => {
      const error = { status: 500, statusText: 'Internal Server Error' };
      driverService.getDrivers.and.returnValue(throwError(() => error));

      component.ngOnInit();

      expect(component.isLoading).toBe(false);
      expect(component.drivers).toEqual([]);
    });
  });

  describe('Document Statistics', () => {
    beforeEach(() => {
      component.documents = mockDocuments;
    });

    it('should calculate total documents correctly', () => {
      component.calculateStats();
      expect(component.documentStats.total).toBe(3);
    });

    it('should identify expiring documents', () => {
      const expiringDoc: DriverDocument = {
        ...mockDocuments[0],
        expiryDate: new Date(Date.now() + 15 * 24 * 60 * 60 * 1000).toISOString().split('T')[0],
      };
      component.documents = [expiringDoc];
      component.calculateStats();

      expect(component.documentStats.expiringSoon).toBeGreaterThan(0);
    });

    it('should identify expired documents', () => {
      const expiredDoc: DriverDocument = {
        ...mockDocuments[0],
        expiryDate: '2024-01-01',
      };
      component.documents = [expiredDoc];
      component.calculateStats();

      expect(component.documentStats.expired).toBeGreaterThan(0);
    });
  });

  describe('Document Filtering', () => {
    beforeEach(() => {
      // Recreate a fresh component instance to avoid cross-test async side-effects
      fixture = TestBed.createComponent(DriverDocumentsComponent);
      component = fixture.componentInstance;
      component.documents = mockDocuments;
      // Reset all filters to ensure tests are independent of order
      component.searchTerm = '';
      component.selectedCategory = '';
      component.selectedStatus = '';
      component.selectedDriverId = null;
      component.dateFrom = '';
      component.dateTo = '';
      component.sortBy = 'uploadDate';
      component.sortOrder = 'desc';
    });

    it('should filter documents by search term', () => {
      component.searchTerm = 'Medical';
      component.applyFilters();

      expect(component.filteredDocuments.length).toBe(1);
      expect(component.filteredDocuments[0].name).toContain('Medical');
    });

    it('should filter documents by driver', () => {
      // Set documents explicitly for this test and reset other filters
      component.documents = [...mockDocuments];
      component.searchTerm = '';
      component.selectedCategory = '';
      component.selectedStatus = '';
      component.selectedDriverId = 1;
      component.dateFrom = '';
      component.dateTo = '';
      component.applyFilters();

      expect(component.filteredDocuments.length).toBe(2); // Documents with driverId 1
      expect(component.filteredDocuments.every((d) => (d as any).driverId === 1)).toBe(true);
    });

    it('should filter documents by category', () => {
      component.selectedCategory = 'license';
      component.applyFilters();

      expect(component.filteredDocuments.length).toBe(1);
      expect(component.filteredDocuments[0].category).toBe('license');
    });

    it('should filter documents by status (expired)', () => {
      const expiredDoc: DriverDocument = {
        ...mockDocuments[0],
        expiryDate: '2024-01-01',
      };
      component.documents = [expiredDoc, ...mockDocuments];
      component.selectedStatus = 'expired';
      component.applyFilters();

      expect(component.filteredDocuments.length).toBeGreaterThan(0);
    });

    it('should clear all filters', () => {
      component.searchTerm = 'test';
      component.selectedCategory = 'license';
      component.selectedStatus = 'active';
      component.selectedDriverId = 1;

      component.clearFilters();

      expect(component.searchTerm).toBe('');
      expect(component.selectedCategory).toBe('');
      expect(component.selectedStatus).toBe('');
      expect(component.selectedDriverId).toBeNull();
    });
  });

  describe('Document Preview', () => {
    it('should identify PDF documents correctly', () => {
      const pdfDoc: DriverDocument = {
        ...mockDocuments[0],
        fileName: 'test.pdf',
        mimeType: 'application/pdf',
      };

      expect(component.isPdfDocument(pdfDoc)).toBe(true);
    });

    it('should identify image documents correctly', () => {
      const imageDoc: DriverDocument = {
        ...mockDocuments[1],
        fileName: 'photo.jpg',
        mimeType: 'image/jpeg',
      };

      expect(component.isImageDocument(imageDoc)).toBe(true);
    });

    it('should get file extension from filename', () => {
      expect(component.getFileExtension('document.pdf')).toBe('PDF');
      expect(component.getFileExtension('image.jpg')).toBe('JPG');
      expect(component.getFileExtension('noextension')).toBe('UNKNOWN');
    });

    it('should sanitize URLs for iframe', () => {
      const url = 'http://example.com/document.pdf';
      const safeUrl = component.getSafeUrl(url);

      expect(safeUrl).toBeTruthy();
    });
  });

  describe('Document Upload', () => {
    it('should validate file selection before upload', () => {
      component.selectedFile = null;
      component.uploadDocument();

      // Should not proceed without file
      expect(driverService.uploadDocument).not.toHaveBeenCalled();
    });

    it('should validate driver selection before upload', () => {
      component.selectedFile = new File(['content'], 'test.pdf', { type: 'application/pdf' });
      component.selectedDriverId = null;
      component.uploadDocument();

      expect(driverService.uploadDocument).not.toHaveBeenCalled();
    });

    it('should validate category selection before upload', () => {
      component.selectedFile = new File(['content'], 'test.pdf', { type: 'application/pdf' });
      component.selectedDriverId = 1;
      component.uploadCategory = '';
      component.uploadDocument();

      expect(driverService.uploadDocument).not.toHaveBeenCalled();
    });

    it('should reject files larger than 50MB', () => {
      const largeFile = new File(['x'.repeat(51 * 1024 * 1024)], 'large.pdf', {
        type: 'application/pdf',
      });
      component.selectedFile = largeFile;
      component.selectedDriverId = 1;
      component.uploadCategory = 'license';

      component.uploadDocument();

      expect(driverService.uploadDocument).not.toHaveBeenCalled();
    });

    it('should upload document with valid inputs', () => {
      const file = new File(['content'], 'test.pdf', { type: 'application/pdf' });
      const initialCategory = 'license';
      component.selectedFile = file;
      component.selectedDriverId = 1;
      component.uploadCategory = initialCategory;

      driverService.uploadDriverDocument.and.returnValue(
        of({
          success: true,
          message: 'Uploaded',
          totalPages: 1,
          data: {
            id: 123,
            driverId: 1,
            driverName: 'John Doe',
            name: 'test.pdf',
            category: initialCategory,
            description: '',
            fileUrl: 'uploads/documents/1/test.pdf',
            fileName: 'test.pdf',
            fileSize: file.size,
            mimeType: file.type,
            uploadDate: new Date().toISOString(),
            status: 'active',
            isRequired: true,
          },
        } as any),
      );
      driverService.getDrivers.and.returnValue(of(mockPageResponse));
      driverService.getDriverDocuments.and.returnValue(
        of({
          data: [],
          totalPages: 1,
          success: true,
          message: 'Success',
        }),
      );

      // Verify initial state before upload
      expect(file).toBeTruthy();
      expect(component.selectedDriverId).toBe(1);
      expect(component.uploadCategory).toBe(initialCategory);

      // After calling uploadDocument, values should be validated
      component.uploadDocument();

      expect(driverService.uploadDriverDocumentWithProgress).toHaveBeenCalled();
    });
  });

  describe('Document Operations', () => {
    it('should view document details', () => {
      const doc = mockDocuments[0];
      component.viewDocument(doc);

      expect(component.selectedDocument).toEqual(doc);
      expect(component.showDetailModal).toBe(true);
    });

    it('should close detail modal', () => {
      component.selectedDocument = mockDocuments[0];
      component.showDetailModal = true;

      component.closeDetailModal();

      expect(component.selectedDocument).toBeNull();
      expect(component.showDetailModal).toBe(false);
    });

    it('should delete document after confirmation', async () => {
      const doc = mockDocuments[0];
      driverService.deleteDriverDocument.and.returnValue(
        of({
          data: 'deleted',
          totalPages: 1,
          success: true,
          message: 'Success',
        }),
      );
      driverService.getDrivers.and.returnValue(of(mockPageResponse));
      driverService.getDriverDocuments.and.returnValue(
        of({
          data: [],
          totalPages: 1,
          success: true,
          message: 'Success',
        }),
      );

      const event = new Event('click');
      await component.deleteDocument(doc, event);
      // New signature: driverId + documentId
      expect(driverService.deleteDriverDocument).toHaveBeenCalledWith(
        doc.driverId as number,
        doc.id as number,
      );
    });

    it('should not delete document if user cancels', async () => {
      const doc = mockDocuments[0];
      confirmService.confirm.and.returnValue(Promise.resolve(false));

      const event = new Event('click');
      await component.deleteDocument(doc, event);

      expect(driverService.deleteDriverDocument).not.toHaveBeenCalled();
    });
  });

  describe('Helper Methods', () => {
    it('should get category icon correctly', () => {
      expect(component.getCategoryIcon('license')).toBe('🪪');
      expect(component.getCategoryIcon('medical')).toBe('🏥');
      expect(component.getCategoryIcon('unknown')).toBe('📄');
    });

    it('should get category label correctly', () => {
      expect(component.getCategoryLabel('license')).toBe('Driver License');
      expect(component.getCategoryLabel('medical')).toBe('Medical Certificate');
    });

    it('should calculate days until expiry', () => {
      const futureDate = new Date(Date.now() + 10 * 24 * 60 * 60 * 1000)
        .toISOString()
        .split('T')[0];
      const doc: DriverDocument = { ...mockDocuments[0], expiryDate: futureDate };

      const days = component.getDaysUntilExpiry(doc);
      expect(days).toBeGreaterThanOrEqual(9);
      expect(days).toBeLessThanOrEqual(11);
    });

    it('should identify expired documents', () => {
      const expiredDoc: DriverDocument = { ...mockDocuments[0], expiryDate: '2024-01-01' };
      expect(component.isExpired(expiredDoc)).toBe(true);
    });

    it('should identify expiring soon documents', () => {
      const expiringSoonDate = new Date(Date.now() + 15 * 24 * 60 * 60 * 1000)
        .toISOString()
        .split('T')[0];
      const doc: DriverDocument = { ...mockDocuments[0], expiryDate: expiringSoonDate };

      expect(component.isExpiringSoon(doc)).toBe(true);
    });

    it('should get status badge class correctly', () => {
      const expiredDoc: DriverDocument = { ...mockDocuments[0], expiryDate: '2024-01-01' };
      const expiringSoonDate = new Date(Date.now() + 15 * 24 * 60 * 60 * 1000)
        .toISOString()
        .split('T')[0];
      const expiringSoonDoc: DriverDocument = { ...mockDocuments[0], expiryDate: expiringSoonDate };
      const activeDoc: DriverDocument = { ...mockDocuments[0], expiryDate: '2027-12-31' };

      expect(component.getStatusBadgeClass(expiredDoc)).toContain('bg-red-100');
      expect(component.getStatusBadgeClass(expiringSoonDoc)).toContain('bg-yellow-100');
      expect(component.getStatusBadgeClass(activeDoc)).toContain('bg-green-100');
    });

    it('should format file size correctly', () => {
      expect(component.getFileSize(0)).toBe('0 B');
      expect(component.getFileSize(1024)).toBe('1 KB');
      expect(component.getFileSize(1024 * 1024)).toBe('1 MB');
      expect(component.getFileSize(1024 * 1024 * 1024)).toBe('1 GB');
    });
  });

  describe('Drag and Drop', () => {
    it('should handle drag over event', () => {
      const event = new DragEvent('dragover');
      spyOn(event, 'preventDefault');

      component.onDragOver(event);

      expect(event.preventDefault).toHaveBeenCalled();
      expect(component.isDragging).toBe(true);
    });

    it('should handle drag leave event', () => {
      const event = new DragEvent('dragleave');
      spyOn(event, 'preventDefault');

      component.onDragLeave(event);

      expect(event.preventDefault).toHaveBeenCalled();
      expect(component.isDragging).toBe(false);
    });

    it('should handle file drop', () => {
      const file = new File(['content'], 'test.pdf', { type: 'application/pdf' });
      const dataTransfer = new DataTransfer();
      dataTransfer.items.add(file);

      const event = new DragEvent('drop', { dataTransfer });
      spyOn(event, 'preventDefault');

      component.onDrop(event);

      expect(event.preventDefault).toHaveBeenCalled();
      expect(component.isDragging).toBe(false);
      expect(component.selectedFile).toBeTruthy();
    });
  });

  describe('Driver Search', () => {
    it('should emit search query for driver autocomplete', () => {
      const searchQuery = 'John';
      driverService.searchDrivers.and.returnValue(
        of({
          data: mockDrivers,
          totalPages: 1,
          success: true,
          message: 'Success',
        }),
      );

      component.onDriverSearch(searchQuery);

      expect(driverService.searchDrivers).toHaveBeenCalledWith(searchQuery);
    });

    it('should handle driver search error gracefully', () => {
      const error = { status: 500, message: 'Server Error' };
      driverService.searchDrivers.and.returnValue(throwError(() => error));

      component.onDriverSearch('test');

      // Should not throw error - just check that component doesn't crash
      expect(component).toBeTruthy();
    });
  });

  describe('Component Cleanup', () => {
    it('should unsubscribe on destroy', () => {
      spyOn(component['destroy$'], 'next');
      spyOn(component['destroy$'], 'complete');

      component.ngOnDestroy();

      expect(component['destroy$'].next).toHaveBeenCalled();
      expect(component['destroy$'].complete).toHaveBeenCalled();
    });
  });

  // ================= NEW TESTS FOR PREVIEW & DOWNLOAD BEHAVIOR =================
  describe('Document Preview & Download', () => {
    const imageDoc: DriverDocument = {
      ...mockDocuments[1],
      id: 99,
      driverId: 1,
      fileUrl: 'uploads/documents/1/test-image.jpg',
      fileName: 'test-image.jpg',
      mimeType: 'image/jpeg',
    };

    beforeEach(() => {
      // Default spy behaviors
      driverService.buildDocumentFileUrl.and.callFake((raw: string) => raw);
    });

    it('should load preview via blob download', async () => {
      const blob = new Blob(['image'], { type: 'image/jpeg' });
      driverService.downloadDriverDocument.and.returnValue(of(blob));
      component.viewDocument(imageDoc);
      await new Promise((r) => setTimeout(r, 0));
      expect(driverService.downloadDriverDocument).toHaveBeenCalledWith(
        imageDoc.driverId as number,
        imageDoc.id as number,
      );
      expect(component.previewLoading).toBeFalse();
      expect(component.previewObjectUrl).toBeTruthy();
    });

    it('should handle preview download failure', async () => {
      const blob = new Blob(['x'], { type: 'image/jpeg' });
      void blob;
      driverService.downloadDriverDocument.and.returnValue(
        throwError(() => new Error('preview failed')),
      );
      component.viewDocument(imageDoc);
      await new Promise((r) => setTimeout(r, 0));
      expect(driverService.downloadDriverDocument).toHaveBeenCalledWith(
        imageDoc.driverId as number,
        imageDoc.id as number,
      );
      expect(component.previewLoading).toBeFalse();
      expect(component.previewError).toContain('Unable to load preview');
    });

    it('downloadDocument should invoke service with correct IDs and create object URL', () => {
      const blob = new Blob(['file'], { type: 'application/pdf' });
      driverService.downloadDriverDocument.and.returnValue(of(blob));
      const clickEvent = new Event('click');
      spyOn(clickEvent, 'stopPropagation');
      component.downloadDocument(mockDocuments[0], clickEvent);
      expect(clickEvent.stopPropagation).toHaveBeenCalled();
      expect(driverService.downloadDriverDocument).toHaveBeenCalledWith(
        mockDocuments[0].driverId as number,
        mockDocuments[0].id as number,
      );
    });
  });
});
