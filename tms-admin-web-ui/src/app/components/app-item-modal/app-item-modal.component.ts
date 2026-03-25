import { CommonModule } from '@angular/common';
import type { OnInit } from '@angular/core';
import { Component, EventEmitter, Output } from '@angular/core';
import type { FormGroup } from '@angular/forms';
// eslint-disable-next-line @typescript-eslint/consistent-type-imports
import { FormBuilder } from '@angular/forms';
import { FormControl, Validators } from '@angular/forms';
import { FormsModule, ReactiveFormsModule } from '@angular/forms';
import { debounceTime, distinctUntilChanged } from 'rxjs/operators';

// eslint-disable-next-line @typescript-eslint/consistent-type-imports
import { ItemService } from '../../services/item.service';

@Component({
  selector: 'app-item-modal',
  standalone: true,
  templateUrl: './app-item-modal.component.html',
  styleUrls: ['./app-item-modal.component.css'],
  imports: [CommonModule, FormsModule, ReactiveFormsModule],
})
export class AppItemModalComponent implements OnInit {
  @Output() close = new EventEmitter<void>();
  @Output() save = new EventEmitter<any>();

  itemForm!: FormGroup;
  searchQuery = new FormControl('');
  items: any[] = [];
  isLoading = false;
  showAutocomplete = false;
  hideTimeout: any;

  unitOptions = [
    'kg',
    'g',
    'lbs',
    'ton',
    'pcs',
    'boxes',
    'packs',
    'bottles',
    'liters',
    'ml',
    'gallons',
    'meters',
    'cm',
    'feet',
    'square meters',
    'square feet',
    'cubic meters',
    'cubic feet',
  ];

  constructor(
    private readonly fb: FormBuilder,
    private readonly itemService: ItemService,
  ) {}

  ngOnInit(): void {
    this.initializeForm();
    this.setupSearchListener();
  }

  /** Initialize the item form */
  initializeForm(): void {
    this.itemForm = this.fb.group({
      itemId: ['', Validators.required],
      itemName: ['', Validators.required],
      itemType: ['', Validators.required],
      quantity: [1, [Validators.required, Validators.min(1)]],
      unitOfMeasurement: ['kg', Validators.required],
      palletType: [''],
      size: [''],
      weight: [''],
      fromDestination: [''],
      toDestination: [''],
      warehouse: [''],
      department: [''],
    });
  }

  /** Setup search listener */
  setupSearchListener(): void {
    this.searchQuery.valueChanges
      .pipe(debounceTime(300), distinctUntilChanged())
      .subscribe((query) => {
        if (query?.trim()) {
          this.searchItems(query);
          this.showAutocomplete = true;
        } else {
          this.items = [];
          this.showAutocomplete = false;
        }
      });
  }

  /** Call API to search items */
  searchItems(query: string): void {
    this.isLoading = true;
    this.itemService.searchItems(query).subscribe({
      next: (data) => {
        this.items = data;
        this.isLoading = false;
      },
      error: (error) => {
        console.error(' Error fetching items:', error);
        this.isLoading = false;
      },
    });
  }

  /** Select item from list */
  selectItem(item: any): void {
    console.log(' Selected Item:', item);
    this.itemForm.patchValue({
      itemId: item.id,
      itemName: item.itemName,
      itemType: item.itemType || '',
      palletType: item.palletType || '',
      size: item.size || '',
      weight: item.weight || '',
      unitOfMeasurement: item.unit || 'kg',
      quantity: item.quantity || 1,
      fromDestination: item.fromDestination || '',
      toDestination: item.toDestination || '',
      warehouse: item.warehouse || '',
      department: item.department || '',
    });

    // Update input and hide dropdown
    this.searchQuery.setValue(item.itemName, { emitEvent: false });
    this.showAutocomplete = false;
    this.items = [];
  }

  /** Hide autocomplete dropdown with slight delay */
  hideAutocompleteWithDelay(): void {
    this.hideTimeout = setTimeout(() => {
      this.showAutocomplete = false;
    }, 150); // allows click event to fire first
  }

  /** Trigger save */
  saveItem(): void {
    if (this.itemForm.valid) {
      console.log('💾 Saving Item:', this.itemForm.value);
      this.save.emit(this.itemForm.value);
      this.closeModal();
    } else {
      console.warn('⚠️ Form is invalid!');
      this.markFormAsTouched();
    }
  }

  /** Touch all controls */
  markFormAsTouched(): void {
    Object.values(this.itemForm.controls).forEach((control) => control.markAsTouched());
  }

  /** Close the modal */
  closeModal(): void {
    this.close.emit();
  }
}
