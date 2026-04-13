import { ComponentFixture, TestBed, fakeAsync, tick } from '@angular/core/testing';
import { FormsModule } from '@angular/forms';
import { CommonModule } from '@angular/common';
import { of, throwError } from 'rxjs';

import { ItemImportComponent } from './item-import.component';
import { ItemService } from '../../../../services/item.service';
import type { Item } from '../../../../models/item.model';

// ── Helpers ──────────────────────────────────────────────────────────────────

function makeFile(name = 'items.xlsx', type = 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet'): File {
  return new File(['dummy'], name, { type });
}

function makeDragEvent(files: File[]): DragEvent {
  const dt = { files: { 0: files[0], length: files.length, item: (i: number) => files[i] } } as any;
  const event = new Event('drop') as DragEvent;
  Object.defineProperty(event, 'dataTransfer', { value: dt });
  Object.defineProperty(event, 'preventDefault', { value: jasmine.createSpy() });
  Object.defineProperty(event, 'stopPropagation', { value: jasmine.createSpy() });
  return event;
}

// ── Tests ─────────────────────────────────────────────────────────────────────

describe('ItemImportComponent', () => {
  let component: ItemImportComponent;
  let fixture: ComponentFixture<ItemImportComponent>;
  let itemServiceSpy: jasmine.SpyObj<ItemService>;

  beforeEach(async () => {
    itemServiceSpy = jasmine.createSpyObj('ItemService', ['createItem']);

    await TestBed.configureTestingModule({
      imports: [ItemImportComponent, CommonModule, FormsModule],
      providers: [{ provide: ItemService, useValue: itemServiceSpy }],
    }).compileComponents();

    fixture = TestBed.createComponent(ItemImportComponent);
    component = fixture.componentInstance;
    fixture.detectChanges();
  });

  // ── Creation ────────────────────────────────────────────────────────────────

  it('should create', () => {
    expect(component).toBeTruthy();
  });

  it('should initialise with no file and empty state', () => {
    expect(component.file).toBeNull();
    expect(component.previewItems).toEqual([]);
    expect(component.failedItems).toEqual([]);
    expect(component.isPreviewReady).toBeFalse();
    expect(component.isDragging).toBeFalse();
    expect(component.loading).toBeFalse();
  });

  // ── Drag & Drop ─────────────────────────────────────────────────────────────

  it('should set isDragging=true on dragover', () => {
    const event = { preventDefault: jasmine.createSpy(), stopPropagation: jasmine.createSpy() } as any as DragEvent;
    component.onDragOver(event);
    expect(component.isDragging).toBeTrue();
    expect(event.preventDefault).toHaveBeenCalled();
  });

  it('should set isDragging=false on dragleave', () => {
    component.isDragging = true;
    const event = { preventDefault: jasmine.createSpy(), stopPropagation: jasmine.createSpy() } as any as DragEvent;
    component.onDragLeave(event);
    expect(component.isDragging).toBeFalse();
  });

  it('should set isDragging=false on drop', () => {
    component.isDragging = true;
    const event = makeDragEvent([makeFile()]);
    // Spy on loadFile to avoid ExcelJS real call
    spyOn<any>(component, 'loadFile');
    component.onDrop(event);
    expect(component.isDragging).toBeFalse();
  });

  it('should call loadFile with dropped file', () => {
    const file = makeFile();
    const loadFileSpy = spyOn<any>(component, 'loadFile');
    const event = makeDragEvent([file]);
    component.onDrop(event);
    expect(loadFileSpy).toHaveBeenCalledWith(file);
  });

  // ── File Type Validation ────────────────────────────────────────────────────

  it('should reject non-xlsx files with a toast error', async () => {
    const badFile = makeFile('data.csv', 'text/csv');
    const toastSpy = spyOn(component, 'showToastMessage');
    await (component as any).loadFile(badFile);
    expect(toastSpy).toHaveBeenCalledWith(
      'Only .xlsx files are supported',
      'error',
    );
    expect(component.file).toBeNull();
  });

  it('should reject .xls files', async () => {
    const xlsFile = makeFile('data.xls', 'application/vnd.ms-excel');
    const toastSpy = spyOn(component, 'showToastMessage');
    await (component as any).loadFile(xlsFile);
    expect(toastSpy).toHaveBeenCalledWith('Only .xlsx files are supported', 'error');
    expect(component.file).toBeNull();
  });

  // ── File Input Change ───────────────────────────────────────────────────────

  it('should call loadFile when file input changes', () => {
    const file = makeFile();
    const loadFileSpy = spyOn<any>(component, 'loadFile');
    const event = { target: { files: [file] } } as any as Event;
    component.onFileInputChange(event);
    expect(loadFileSpy).toHaveBeenCalledWith(file);
  });

  it('should not call loadFile when file input is cleared', () => {
    const loadFileSpy = spyOn<any>(component, 'loadFile');
    const event = { target: { files: [] } } as any as Event;
    component.onFileInputChange(event);
    expect(loadFileSpy).not.toHaveBeenCalled();
  });

  // ── confirmImport ──────────────────────────────────────────────────────────

  it('should import all items and show success toast', fakeAsync(async () => {
    const items: Item[] = [
      { itemName: 'Item A', quantity: 1 },
      { itemName: 'Item B', quantity: 2 },
    ];
    component.previewItems = items;
    itemServiceSpy.createItem.and.returnValue(of(items[0]));

    const resetSpy = spyOn<any>(component, 'resetInput');
    const toastSpy = spyOn(component, 'showToastMessage');

    await component.confirmImport();
    tick();

    expect(itemServiceSpy.createItem).toHaveBeenCalledTimes(2);
    expect(toastSpy).toHaveBeenCalledWith('Imported: 2  Failed: 0', 'success');
    expect(resetSpy).toHaveBeenCalled();
    expect(component.loading).toBeFalse();
    expect(component.previewItems).toEqual([]);
    expect(component.isPreviewReady).toBeFalse();
  }));

  it('should track failed items and show success toast with count', fakeAsync(async () => {
    const items: Item[] = [
      { itemName: 'Good', quantity: 1 },
      { itemName: 'Bad', quantity: 0 },
    ];
    component.previewItems = [...items];
    itemServiceSpy.createItem.and.returnValues(
      of(items[0]),
      throwError(() => new Error('Server error')),
    );

    const toastSpy = spyOn(component, 'showToastMessage');
    await component.confirmImport();
    tick();

    expect(component.failedItems).toEqual([items[1]]);
    expect(toastSpy).toHaveBeenCalledWith('Imported: 1  Failed: 1', 'success');
  }));

  it('should show error toast when all items fail', fakeAsync(async () => {
    component.previewItems = [{ itemName: 'Bad', quantity: 0 }];
    itemServiceSpy.createItem.and.returnValue(throwError(() => new Error('fail')));

    const toastSpy = spyOn(component, 'showToastMessage');
    await component.confirmImport();
    tick();

    expect(toastSpy).toHaveBeenCalledWith('Failed to import any items', 'error');
  }));

  // ── Reset / Reimport ───────────────────────────────────────────────────────

  it('should clear file, excelColumns and columnMapping after reset', () => {
    component.file = makeFile();
    component.excelColumns = ['Col A', 'Col B'];
    component.columnMapping['itemName'] = 'Col A';

    // Mock ViewChild fileInput
    (component as any).fileInput = { nativeElement: { value: 'something' } };

    (component as any).resetInput();

    expect(component.file).toBeNull();
    expect(component.excelColumns).toEqual([]);
    expect(component.columnMapping['itemName']).toBe('');
    expect((component as any).fileInput.nativeElement.value).toBe('');
  });

  it('should allow reimport by resetting native input value', () => {
    const nativeInput = { value: 'items.xlsx' };
    (component as any).fileInput = { nativeElement: nativeInput };
    (component as any).resetInput();
    expect(nativeInput.value).toBe('');
  });

  // ── Toast ──────────────────────────────────────────────────────────────────

  it('should show toast and auto-hide after duration', fakeAsync(() => {
    component.showToastMessage('Hello', 'success', 1000);
    expect(component.showToast).toBeTrue();
    expect(component.toastMessage).toBe('Hello');
    expect(component.toastType).toBe('success');
    tick(1000);
    expect(component.showToast).toBeFalse();
  }));

  it('should show error toast type', fakeAsync(() => {
    component.showToastMessage('Oops', 'error', 500);
    expect(component.toastType).toBe('error');
    tick(500);
    expect(component.showToast).toBeFalse();
  }));

  // ── Download Template ──────────────────────────────────────────────────────

  it('should trigger xlsx download when downloadTemplate is called', async () => {
    const anchor = document.createElement('a');
    spyOn(document, 'createElement').and.returnValue(anchor);
    spyOn(anchor, 'click');
    spyOn(URL, 'createObjectURL').and.returnValue('blob:mock');
    spyOn(URL, 'revokeObjectURL');

    await component.downloadTemplate();

    expect(anchor.click).toHaveBeenCalled();
    expect(anchor.download).toBe('items_import_template.xlsx');
    expect(URL.revokeObjectURL).toHaveBeenCalledWith('blob:mock');
  });

  // ── Export Failed ──────────────────────────────────────────────────────────

  it('should trigger xlsx download for failed items', async () => {
    component.failedItems = [{ itemName: 'Failed', quantity: 1 }];
    const anchor = document.createElement('a');
    spyOn(document, 'createElement').and.returnValue(anchor);
    spyOn(anchor, 'click');
    spyOn(URL, 'createObjectURL').and.returnValue('blob:failed');
    spyOn(URL, 'revokeObjectURL');

    await component.exportFailedToExcel();

    expect(anchor.click).toHaveBeenCalled();
    expect(anchor.download).toBe('failed_items.xlsx');
  });

  // ── generatePreview guard ──────────────────────────────────────────────────

  it('should not generate preview if no file is loaded', async () => {
    component.file = null;
    await component.generatePreview();
    expect(component.isPreviewReady).toBeFalse();
  });
});
