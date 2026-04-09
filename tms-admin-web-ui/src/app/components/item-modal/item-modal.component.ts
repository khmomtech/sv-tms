/* eslint-disable @typescript-eslint/consistent-type-imports */
import { CommonModule } from '@angular/common';
import { Component, EventEmitter, Output, Input } from '@angular/core';
import { FormGroup } from '@angular/forms';
import { FormBuilder } from '@angular/forms';
import { FormsModule, ReactiveFormsModule, Validators } from '@angular/forms';

@Component({
  selector: 'app-item-modal',
  standalone: true,
  imports: [CommonModule, FormsModule, ReactiveFormsModule],
  templateUrl: './item-modal.component.html',
  styleUrls: ['./item-modal.component.css'],
})
export class ItemModalComponent {
  @Output() close = new EventEmitter<void>(); // Close the modal
  @Output() save = new EventEmitter<any>(); // Save item data
  @Input() itemData: any; // Input for editing existing item

  itemForm!: FormGroup;

  //  Define Unit Options
  unitOptions: string[] = ['Kg', 'Gram', 'Ton', 'Pallet', 'Box', 'Litre', 'Piece'];

  //  Define Item Name Options
  itemOptions: string[] = [
    'Electronics',
    'Furniture',
    'Food',
    'Books',
    'Clothing',
    'Chemicals',
    'Machinery',
  ];

  constructor(private fb: FormBuilder) {}

  ngOnInit(): void {
    this.itemForm = this.fb.group({
      quantity: [this.itemData?.quantity || 1, [Validators.required, Validators.min(1)]],
      unit: [this.itemData?.unit || '', Validators.required],
      itemName: [this.itemData?.itemName || '', Validators.required],
      palletType: [this.itemData?.palletType || ''],
      size: [this.itemData?.size || ''],
      volume: [this.itemData?.volume || ''],
      weight: [this.itemData?.weight || ''],
      loadmeters: [this.itemData?.loadmeters || ''],
    });
  }

  closeModal(): void {
    this.close.emit();
  }

  saveItem(): void {
    if (this.itemForm.valid) {
      this.save.emit(this.itemForm.value);
    }
  }
}
