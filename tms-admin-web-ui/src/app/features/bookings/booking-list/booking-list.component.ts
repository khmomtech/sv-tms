import { Component, HostListener, OnInit } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { Router, RouterModule } from '@angular/router';
import { BookingService, BookingListResponse } from '@services/booking.service';
import { ConfirmService } from '@services/confirm.service';
import { NotificationService } from '@services/notification.service';
import { Booking, BookingFilter } from '@models/booking.model';
import {
  BookingStatus,
  BookingServiceType,
  getBookingStatusLabel,
  getBookingStatusColor,
} from '@models/booking-status.enum';

@Component({
  selector: 'app-booking-list',
  standalone: true,
  imports: [CommonModule, FormsModule, RouterModule],
  templateUrl: './booking-list.component.html',
  styleUrls: ['./booking-list.component.css'],
})
export class BookingListComponent implements OnInit {
  bookings: Booking[] = [];
  totalElements = 0;
  totalPages = 0;
  currentPage = 0;
  pageSize = 10;
  loading = false;
  error: string | null = null;

  // Filter properties
  searchQuery = '';
  selectedStatus: BookingStatus | '' = '';
  selectedService: BookingServiceType | '' = '';
  selectedDate = '';

  // Actions menu
  openMenuId: number | null = null;

  // Enums for template
  BookingStatus = BookingStatus;
  BookingServiceType = BookingServiceType;

  constructor(
    private bookingService: BookingService,
    private router: Router,
    private readonly confirm: ConfirmService,
    private readonly notify: NotificationService,
  ) {}

  ngOnInit(): void {
    this.loadBookings();
  }

  loadBookings(): void {
    this.loading = true;
    this.error = null;

    const filter: BookingFilter = {
      searchQuery: this.searchQuery || undefined,
      status: this.selectedStatus || undefined,
      serviceType: this.selectedService || undefined,
      fromDate: this.selectedDate || undefined,
    };

    this.bookingService.getBookings(this.currentPage, this.pageSize, filter).subscribe({
      next: (response: BookingListResponse) => {
        this.bookings = response.data.content;
        this.totalElements = response.data.totalElements;
        this.totalPages = response.data.totalPages;
        this.currentPage = response.data.number;
        this.loading = false;
      },
      error: (err) => {
        this.error = 'Failed to load bookings. Please try again.';
        this.loading = false;
        console.error('Error loading bookings:', err);
      },
    });
  }

  applyFilters(): void {
    this.currentPage = 0;
    this.loadBookings();
  }

  clearFilters(): void {
    this.searchQuery = '';
    this.selectedStatus = '';
    this.selectedService = '';
    this.selectedDate = '';
    this.currentPage = 0;
    this.loadBookings();
  }

  goToPage(page: number): void {
    this.currentPage = page;
    this.loadBookings();
  }

  nextPage(): void {
    if (this.currentPage < this.totalPages - 1) {
      this.currentPage++;
      this.loadBookings();
    }
  }

  previousPage(): void {
    if (this.currentPage > 0) {
      this.currentPage--;
      this.loadBookings();
    }
  }

  viewBooking(id: number): void {
    this.router.navigate(['/bookings', id]);
  }

  editBooking(id: number): void {
    this.router.navigate(['/bookings', id, 'edit']);
  }

  createBooking(): void {
    this.router.navigate(['/bookings', 'create']);
  }

  async convertToOrder(booking: Booking): Promise<void> {
    if (!booking.id) return;

    this.closeMenu();

    if (
      !(await this.confirm.confirm(
        `Convert booking ${booking.bookingReference} to transport order?`,
      ))
    ) {
      return;
    }

    this.bookingService.convertToOrder(booking.id).subscribe({
      next: (response) => {
        this.notify.success(`Successfully converted to order! Order ID: ${response.orderId}`);
        this.loadBookings();
      },
      error: (err) => {
        this.notify.error('Failed to convert booking to order.');
        console.error('Error converting booking:', err);
      },
    });
  }

  async cancelBooking(booking: Booking): Promise<void> {
    if (!booking.id) return;

    const confirmed = await this.confirm.confirm(`Cancel booking ${booking.bookingReference}?`);
    if (!confirmed) return;

    this.closeMenu();

    const reason = 'Cancelled via UI';

    this.bookingService.cancelBooking(booking.id, reason).subscribe({
      next: () => {
        this.notify.success('Booking cancelled successfully.');
        this.loadBookings();
      },
      error: (err) => {
        this.notify.error('Failed to cancel booking.');
        console.error('Error cancelling booking:', err);
      },
    });
  }

  async confirmBooking(booking: Booking): Promise<void> {
    if (!booking.id) return;

    if (!(await this.confirm.confirm(`Confirm booking ${booking.bookingReference}?`))) {
      return;
    }

    this.closeMenu();

    this.bookingService.confirmBooking(booking.id).subscribe({
      next: () => {
        this.notify.success('Booking confirmed successfully.');
        this.loadBookings();
      },
      error: (err) => {
        this.notify.error('Failed to confirm booking.');
        console.error('Error confirming booking:', err);
      },
    });
  }

  getStatusLabel(status: BookingStatus): string {
    return getBookingStatusLabel(status);
  }

  getStatusColor(status: BookingStatus): { bg: string; text: string } {
    return getBookingStatusColor(status);
  }

  formatDate(date: Date | string | undefined): string {
    if (!date) return 'N/A';
    return new Date(date).toLocaleDateString('en-GB', {
      day: '2-digit',
      month: 'short',
      year: '2-digit',
    });
  }

  get pageNumbers(): number[] {
    const pages: number[] = [];
    const start = Math.max(0, this.currentPage - 2);
    const end = Math.min(this.totalPages, this.currentPage + 3);

    for (let i = start; i < end; i++) {
      pages.push(i);
    }
    return pages;
  }

  get pageStart(): number {
    if (!this.totalElements) return 0;
    return this.currentPage * this.pageSize + 1;
  }

  get pageEnd(): number {
    if (!this.totalElements) return 0;
    return Math.min((this.currentPage + 1) * this.pageSize, this.totalElements);
  }

  toggleMenu(id: number): void {
    this.openMenuId = this.openMenuId === id ? null : id;
  }

  closeMenu(): void {
    this.openMenuId = null;
  }

  isMenuOpen(id: number): boolean {
    return this.openMenuId === id;
  }

  @HostListener('document:click', ['$event'])
  handleDocumentClick(event: MouseEvent): void {
    const target = event.target as HTMLElement | null;
    if (!target?.closest('.booking-actions-menu')) {
      this.closeMenu();
    }
  }
}
