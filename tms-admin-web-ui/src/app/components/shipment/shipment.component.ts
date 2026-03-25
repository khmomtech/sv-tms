/* eslint-disable @typescript-eslint/consistent-type-imports */
import { CommonModule } from '@angular/common';
import { OnInit } from '@angular/core';
import { Component } from '@angular/core';
import { FormsModule } from '@angular/forms';
import { Router } from '@angular/router';

import type { Shipment } from '../../models/shipment.model';
import { ShipmentService } from '../../services/shipment.service';
import { ConfirmService } from '../../services/confirm.service';

@Component({
  selector: 'app-shipment',
  templateUrl: './shipment.component.html',
  standalone: true,
  imports: [CommonModule, FormsModule],
  styleUrls: ['./shipment.component.css'],
})
export class ShipmentComponent implements OnInit {
  shipments: Shipment[] = [];
  filteredList: Shipment[] = [];
  searchQuery = '';
  isModalOpen = false;
  isEditing = false;
  selectedShipment: Shipment = {} as Shipment;
  dropdownOpen: number | null = null;
  currentPage = 0;
  totalPages = 1;
  errorMessage: string | null = null;
  isLoading = false;

  constructor(
    private shipmentService: ShipmentService,
    private router: Router,
    private confirm: ConfirmService,
  ) {}

  ngOnInit() {
    this.loadShipments();
  }

  loadShipments() {
    this.isLoading = true;
    this.shipmentService.getShipments(this.currentPage, 5).subscribe({
      next: (response) => {
        this.isLoading = false;
        if (response.success) {
          this.shipments = response.data?.content || [];
          this.filteredList = [...this.shipments];
          this.totalPages = response.data?.totalPages || 1;
        } else {
          this.errorMessage = 'Failed to load shipments.';
        }
      },
      error: (error) => {
        this.isLoading = false;
        this.errorMessage = error.message;
      },
    });
  }

  filterShipments() {
    this.filteredList = this.shipments.filter((shipment) =>
      shipment.trackingNumber.toLowerCase().includes(this.searchQuery.toLowerCase()),
    );
  }

  openShipmentModal(shipment: Shipment | null = null) {
    this.isEditing = !!shipment;
    this.selectedShipment = shipment ? { ...shipment } : ({} as Shipment);
    this.isModalOpen = true;
  }

  closeModal() {
    this.isModalOpen = false;
  }

  saveShipment() {
    if (this.isEditing) {
      this.shipmentService
        .updateShipment(this.selectedShipment.id!, this.selectedShipment)
        .subscribe({
          next: () => this.loadShipments(),
          error: (error) => (this.errorMessage = error.message),
        });
    } else {
      this.shipmentService.createShipment(this.selectedShipment).subscribe({
        next: () => this.loadShipments(),
        error: (error) => (this.errorMessage = error.message),
      });
    }
    this.closeModal();
  }

  async deleteShipment(shipmentId: number) {
    if (await this.confirm.confirm('Are you sure you want to delete this shipment?')) {
      this.shipmentService.deleteShipment(shipmentId).subscribe({
        next: () => this.loadShipments(),
        error: (error) => (this.errorMessage = error.message),
      });
    }
  }

  toggleDropdown(id: number) {
    this.dropdownOpen = this.dropdownOpen === id ? null : id;
  }

  prevPage() {
    if (this.currentPage > 0) {
      this.currentPage--;
      this.loadShipments();
    }
  }

  nextPage() {
    if (this.currentPage < this.totalPages - 1) {
      this.currentPage++;
      this.loadShipments();
    }
  }

  viewShipmentDetails(shipment: Shipment) {
    this.router.navigate([`/shipments/${shipment.id}`]);
  }
}
