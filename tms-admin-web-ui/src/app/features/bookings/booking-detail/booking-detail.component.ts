import { CommonModule } from '@angular/common';
import { Component, OnInit } from '@angular/core';
import { ActivatedRoute, Router } from '@angular/router';
import { finalize } from 'rxjs/operators';

import { Booking } from '@models/booking.model';
import {
  BookingStatus,
  getBookingStatusColor,
  getBookingStatusLabel,
} from '@models/booking-status.enum';
import { BookingService } from '@services/booking.service';
import { ConfirmService } from '@services/confirm.service';
import { NotificationService } from '@services/notification.service';

@Component({
  selector: 'app-booking-detail',
  standalone: true,
  imports: [CommonModule],
  templateUrl: './booking-detail.component.html',
  styleUrls: ['./booking-detail.component.css'],
})
export class BookingDetailComponent implements OnInit {
  booking: Booking | null = null;
  loading = false;
  error: string | null = null;

  actionsMenuOpen = false;
  actionBusy = {
    confirm: false,
    convert: false,
    cancel: false,
  };

  isConfirmable = false;
  isConvertible = false;
  isCancelable = false;

  BookingStatus = BookingStatus;

  constructor(
    private readonly route: ActivatedRoute,
    private readonly router: Router,
    private readonly bookingService: BookingService,
    private readonly confirm: ConfirmService,
    private readonly notify: NotificationService,
  ) {}

  ngOnInit(): void {
    const idParam = this.route.snapshot.paramMap.get('id');

    if (!idParam) {
      this.error = 'Missing booking id.';
      return;
    }

    const id = Number(idParam);
    if (Number.isNaN(id)) {
      this.error = 'Invalid booking id.';
      return;
    }

    this.loadBooking(id);
  }

  toggleActionsMenu(): void {
    this.actionsMenuOpen = !this.actionsMenuOpen;
  }

  closeActionsMenu(): void {
    this.actionsMenuOpen = false;
  }

  goBack(): void {
    this.router.navigate(['/bookings']);
  }

  async confirmBooking(): Promise<void> {
    if (!this.booking?.id || !this.isConfirmable || this.actionBusy.confirm) return;

    if (!(await this.confirm.confirm(`Confirm booking ${this.booking.bookingReference}?`))) return;

    this.actionBusy.confirm = true;
    this.bookingService
      .confirmBooking(this.booking.id)
      .pipe(finalize(() => (this.actionBusy.confirm = false)))
      .subscribe({
        next: () => {
          this.notify.success('Booking confirmed successfully.');
          this.loadBooking(this.booking!.id!);
        },
        error: (err) => {
          this.notify.error('Failed to confirm booking.');
          console.error('Error:', err);
        },
      });
  }

  async convertToOrder(): Promise<void> {
    if (!this.booking?.id || !this.isConvertible || this.actionBusy.convert) return;

    if (
      !(await this.confirm.confirm(
        `Convert booking ${this.booking.bookingReference} to transport order?`,
      ))
    )
      return;

    this.actionBusy.convert = true;
    this.bookingService
      .convertToOrder(this.booking.id)
      .pipe(finalize(() => (this.actionBusy.convert = false)))
      .subscribe({
        next: (response) => {
          this.notify.success(`Successfully converted! Order ID: ${response.orderId}`);
          this.router.navigate(['/orders', response.orderId]);
        },
        error: (err) => {
          this.notify.error('Failed to convert booking to order.');
          console.error('Error:', err);
        },
      });
  }

  async cancelBooking(): Promise<void> {
    if (!this.booking?.id || !this.isCancelable || this.actionBusy.cancel) return;

    const confirmed = await this.confirm.confirm(
      `Cancel booking ${this.booking.bookingReference}?`,
    );
    if (!confirmed) return;

    this.actionBusy.cancel = true;
    this.bookingService
      .cancelBooking(this.booking.id, 'Cancelled via UI')
      .pipe(finalize(() => (this.actionBusy.cancel = false)))
      .subscribe({
        next: () => {
          this.notify.success('Booking cancelled successfully.');
          this.loadBooking(this.booking!.id!);
        },
        error: (err) => {
          this.notify.error('Failed to cancel booking.');
          console.error('Error:', err);
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
    return new Date(date).toLocaleDateString('en-US', {
      day: '2-digit',
      month: 'long',
      year: 'numeric',
    });
  }

  private loadBooking(id: number): void {
    this.loading = true;
    this.error = null;

    this.bookingService.getBookingById(id).subscribe({
      next: (response) => {
        this.booking = this.normalizeBooking(response.data);
        this.updateActionFlags();
        this.loading = false;
      },
      error: (err) => {
        this.error = 'Failed to load booking details.';
        this.loading = false;
        console.error('Error loading booking:', err);
      },
    });
  }

  private normalizeBooking(booking: Booking): Booking {
    if ((booking as any).status === 'NEW') {
      return { ...booking, status: BookingStatus.BOOKING_CREATED };
    }
    return booking;
  }

  private updateActionFlags(): void {
    if (!this.booking) {
      this.isConfirmable = false;
      this.isConvertible = false;
      this.isCancelable = false;
      return;
    }

    const status = this.booking.status;
    this.isConfirmable = status === BookingStatus.BOOKING_CREATED;
    this.isConvertible =
      status === BookingStatus.BOOKING_CREATED || status === BookingStatus.CONFIRMED;
    this.isCancelable =
      status !== BookingStatus.CANCELLED && status !== BookingStatus.CONVERTED_TO_ORDER;
  }
}
