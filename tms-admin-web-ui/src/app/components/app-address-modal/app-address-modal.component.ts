import { CommonModule } from '@angular/common';
import type { OnInit } from '@angular/core';
import { Component, EventEmitter, Output } from '@angular/core';
import { FormControl, ReactiveFormsModule } from '@angular/forms';
import { FormsModule } from '@angular/forms';
import { of } from 'rxjs';
import { debounceTime, distinctUntilChanged, catchError } from 'rxjs/operators';

// eslint-disable-next-line @typescript-eslint/consistent-type-imports
import { AddressService } from '../../services/address.service';

@Component({
  selector: 'app-address-modal',
  standalone: true,
  imports: [CommonModule, FormsModule, ReactiveFormsModule],
  templateUrl: './app-address-modal.component.html',
  styleUrls: ['./app-address-modal.component.css'],
})
export class AppAddressModalComponent implements OnInit {
  @Output() close = new EventEmitter<void>();
  @Output() select = new EventEmitter<any>();

  searchQuery = new FormControl('');
  filteredAddresses: any[] = [];
  isLoading: boolean = false;
  errorMessage: string = '';

  constructor(private readonly addressService: AddressService) {}

  ngOnInit(): void {
    this.setupSearchListener();
  }

  /**  Setup search input listener */
  setupSearchListener(): void {
    this.searchQuery.valueChanges
      .pipe(debounceTime(300), distinctUntilChanged())
      .subscribe((query: string | null) => {
        const searchValue = query?.trim() ?? ''; //  Ensure it's always a string
        if (searchValue) {
          this.searchAddresses(searchValue);
        } else {
          this.filteredAddresses = [];
          this.errorMessage = '';
        }
      });
  }

  /**  Fetch matching addresses from API */
  searchAddresses(query: string): void {
    this.isLoading = true;
    this.errorMessage = '';

    this.addressService
      .searchLocations(query)
      .pipe(
        catchError((err) => {
          console.error(' Error fetching addresses:', err);
          this.errorMessage = 'Failed to fetch addresses. Please try again.';
          this.isLoading = false;
          return of([]); //  Prevent breaking UI
        }),
      )
      .subscribe((data) => {
        this.filteredAddresses = data;
        this.isLoading = false;
      });
  }

  /**  Select Address */
  selectAddress(address: any): void {
    this.select.emit(address);
    this.close.emit();
  }
}
