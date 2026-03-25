import { CommonModule } from '@angular/common';
import { Component, EventEmitter, Output, Input } from '@angular/core';
import {
  FormBuilder,
  FormGroup,
  Validators,
  ReactiveFormsModule,
  FormsModule,
} from '@angular/forms';
import { CustomerBillToAddressService } from '../../services/customer-bill-to-address.service';

@Component({
  selector: 'app-create-address-modal',
  standalone: true,
  imports: [CommonModule, FormsModule, ReactiveFormsModule],
  templateUrl: './create-address-modal.component.html',
  styleUrls: ['./create-address-modal.component.css'],
})
export class CreateAddressModalComponent {
  @Input() customerId!: number;
  @Output() close = new EventEmitter<void>();
  @Output() created = new EventEmitter<any>();
  @Output() search = new EventEmitter<string>();

  addressForm: FormGroup;
  loading = false;
  error: string = '';

  constructor(
    private fb: FormBuilder,
    private addressService: CustomerBillToAddressService,
  ) {
    this.addressForm = this.fb.group({
      name: ['', Validators.required],
      email: [''],
      address: ['', Validators.required],
      city: [''],
      state: [''],
      zip: [''],
      country: [''],
      contactName: [''],
      contactPhone: [''],
      taxId: [''],
      notes: [''],
      isPrimary: [true],
    });

    // Listen for name field changes for search
    this.addressForm.get('name')?.valueChanges.subscribe((term: string) => {
      if (term && term.length >= 2) {
        this.search.emit(term);
        // Optionally, you can call backend here for suggestions
        // this.addressService.searchAddresses(this.customerId, term).subscribe(...)
      }
    });
  }

  save() {
    if (this.addressForm.invalid) {
      this.addressForm.markAllAsTouched();
      return;
    }
    this.loading = true;
    this.error = '';
    const payload = { ...this.addressForm.value, customerId: this.customerId };
    this.addressService.create(this.customerId, payload).subscribe({
      next: (response) => {
        this.created.emit(response.data);
        this.loading = false;
      },
      error: (err) => {
        this.error = err?.message || 'Failed to create address.';
        this.loading = false;
      },
    });
  }
}
