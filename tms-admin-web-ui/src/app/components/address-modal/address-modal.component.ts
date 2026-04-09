import { CommonModule } from '@angular/common';
import type { OnInit } from '@angular/core';
import { Component, EventEmitter, Output } from '@angular/core';
import { FormsModule, ReactiveFormsModule } from '@angular/forms';
import { debounceTime, distinctUntilChanged } from 'rxjs/operators';

// eslint-disable-next-line @typescript-eslint/consistent-type-imports
import { AddressService } from '../../services/address.service';

@Component({
  selector: 'app-address-modal',
  standalone: true,
  imports: [CommonModule, FormsModule, ReactiveFormsModule],
  templateUrl: './address-modal.component.html',
  styleUrls: ['./address-modal.component.css'],
})
export class AddressModalComponent implements OnInit {
  @Output() close = new EventEmitter<void>();
  @Output() select = new EventEmitter<any>();

  searchText: string = '';
  addresses: any[] = []; //  Store addresses fetched from API
  filteredAddresses: any[] = []; //  Store filtered addresses

  constructor(private readonly addressService: AddressService) {} //  Inject API service

  ngOnInit(): void {
    this.fetchAddresses();
  }

  /**  Fetch addresses from API */
  fetchAddresses(): void {
    this.addressService.getAllAddresses().subscribe({
      next: (data) => {
        console.log(' Addresses Fetched:', data);
        this.addresses = data;
        this.filteredAddresses = [...data]; //  Initialize filtered list
      },
      error: (err) => console.error(' Error fetching addresses:', err),
    });
  }

  /**  Filter Address List */
  filterAddresses(): void {
    this.filteredAddresses = this.addresses.filter(
      (address) =>
        address.name.toLowerCase().includes(this.searchText.toLowerCase()) ||
        address.address.toLowerCase().includes(this.searchText.toLowerCase()),
    );
  }

  /**  Select an Address */
  selectAddress(address: any): void {
    console.log(' Selected Address:', address);
    this.select.emit(address); //  Emit selected address
    this.close.emit(); //  Close modal
  }
}
