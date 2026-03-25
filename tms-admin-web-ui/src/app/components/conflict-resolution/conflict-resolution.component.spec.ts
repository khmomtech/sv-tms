import { ComponentFixture, TestBed } from '@angular/core/testing';
import { MAT_DIALOG_DATA, MatDialogRef } from '@angular/material/dialog';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { ConflictResolutionComponent, ConflictData } from './conflict-resolution.component';

describe('ConflictResolutionComponent', () => {
  let component: ConflictResolutionComponent;
  let fixture: ComponentFixture<ConflictResolutionComponent>;
  let mockDialogRef: jasmine.SpyObj<MatDialogRef<ConflictResolutionComponent>>;

  const mockConflictData: ConflictData = {
    resourceName: 'Vehicle #1',
    currentVersion: {
      id: 1,
      plateNumber: 'ABC-123',
      status: 'AVAILABLE',
      capacity: 1000,
      version: 1,
    },
    serverVersion: {
      id: 1,
      plateNumber: 'ABC-123',
      status: 'IN_USE',
      capacity: 1500,
      version: 2,
    },
    localChanges: {
      id: 1,
      plateNumber: 'ABC-123',
      status: 'AVAILABLE',
      capacity: 1000,
      version: 1,
    },
    conflictFields: ['status', 'capacity'],
  };

  beforeEach(async () => {
    const dialogRefSpy = jasmine.createSpyObj('MatDialogRef', ['close']);
    await TestBed.configureTestingModule({
      imports: [CommonModule, FormsModule],
      providers: [
        { provide: MAT_DIALOG_DATA, useValue: mockConflictData },
        { provide: MatDialogRef, useValue: dialogRefSpy },
      ],
    }).compileComponents();
    mockDialogRef = TestBed.inject(MatDialogRef) as jasmine.SpyObj<
      MatDialogRef<ConflictResolutionComponent>
    >;
    fixture = TestBed.createComponent(ConflictResolutionComponent);
    component = fixture.componentInstance;
    fixture.detectChanges();
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });

  it('should initialize with conflict data', () => {
    expect(component.data).toEqual(mockConflictData);
    expect(component.data.conflictFields.length).toBe(2);
  });

  it('should close dialog with useLocal resolution', () => {
    component.useLocal();
    expect(mockDialogRef.close).toHaveBeenCalledWith({
      action: 'use-local',
      mergedData: mockConflictData.localChanges,
    });
  });

  it('should close dialog with useServer resolution', () => {
    component.useServer();
    expect(mockDialogRef.close).toHaveBeenCalledWith({
      action: 'use-server',
      mergedData: mockConflictData.serverVersion,
    });
  });

  it('should close dialog with merge resolution', () => {
    component.mergeMode = true;
    component.mergeSelection['status'] = 'local';
    component.mergeSelection['capacity'] = 'server';
    component.toggleMerge();
    expect(mockDialogRef.close).toHaveBeenCalledWith({
      action: 'merge',
      mergedData: jasmine.objectContaining({
        status: 'AVAILABLE',
        capacity: 1500,
      }),
    });
  });

  it('should cancel and close dialog without resolution', () => {
    component.cancel();
    expect(mockDialogRef.close).toHaveBeenCalledWith(null);
  });

  it('should format values correctly', () => {
    expect(component.formatValue('AVAILABLE')).toBe('AVAILABLE');
    expect(component.formatValue(1000)).toBe('1000');
    expect(component.formatValue(null)).toBe('(empty)');
    expect(component.formatValue({ foo: 'bar' })).toBe('{"foo":"bar"}');
  });
});
