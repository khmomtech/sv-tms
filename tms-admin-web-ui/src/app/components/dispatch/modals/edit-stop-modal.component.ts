import { CommonModule } from '@angular/common';
import type { ElementRef, AfterViewInit, OnChanges, SimpleChanges } from '@angular/core';
// eslint-disable-next-line @typescript-eslint/consistent-type-imports
import { ChangeDetectorRef } from '@angular/core';
import { Component, Input, Output, EventEmitter, ViewChild } from '@angular/core';
import type { FormGroup } from '@angular/forms';
import { ReactiveFormsModule } from '@angular/forms';
import { GoogleMapsModule } from '@angular/google-maps';

@Component({
  selector: 'app-edit-stop-modal',
  templateUrl: './edit-stop-modal.component.html',
  styleUrls: ['./edit-stop-modal.component.css'],
  standalone: true,
  imports: [CommonModule, ReactiveFormsModule, GoogleMapsModule],
})
export class EditStopModalComponent implements AfterViewInit, OnChanges {
  @Input() visible = false;
  @Input() form!: FormGroup;

  @Output() save = new EventEmitter<void>();
  @Output() close = new EventEmitter<void>();

  @ViewChild('searchInput') searchInput?: ElementRef<HTMLInputElement>;

  mapCenter: google.maps.LatLngLiteral = { lat: 11.5564, lng: 104.9282 }; // Default: Phnom Penh

  constructor(private cdRef: ChangeDetectorRef) {}

  ngAfterViewInit(): void {
    this.tryInitAutocomplete();
  }

  ngOnChanges(changes: SimpleChanges): void {
    if (changes['visible'] && changes['visible'].currentValue === true) {
      setTimeout(() => {
        this.cdRef.detectChanges();
        this.tryInitAutocomplete();
      }, 250);
    }
  }

  private tryInitAutocomplete(): void {
    if (this.searchInput?.nativeElement) {
      console.debug('[EditStopModal] Initializing Autocomplete');
      this.initAutocomplete(this.searchInput.nativeElement);
    } else {
      console.warn('[EditStopModal] Search input not available yet.');
    }
  }

  private initAutocomplete(input: HTMLInputElement): void {
    if (!google?.maps?.places) {
      console.error('Google Maps Places library not available.');
      return;
    }

    const autocomplete = new google.maps.places.Autocomplete(input, {
      fields: ['geometry', 'formatted_address', 'name'],
      componentRestrictions: { country: 'KH' },
      types: ['establishment'],
    });

    autocomplete.addListener('place_changed', () => {
      const place = autocomplete.getPlace();
      if (!place.geometry || !place.geometry.location) return;

      const lat = place.geometry.location.lat();
      const lng = place.geometry.location.lng();
      const coord = `${lat},${lng}`;
      const address = place.formatted_address || place.name || coord;

      // Update form
      this.form.patchValue({
        latitude: lat,
        longitude: lng,
        coordinates: coord,
        location: address,
        note: `Selected: ${address}`,
      });

      // Update map center
      this.mapCenter = { lat, lng };
    });
  }

  onSave(): void {
    if (this.form.valid) {
      this.save.emit();
    } else {
      this.form.markAllAsTouched();
    }
  }

  onClose(): void {
    this.close.emit();
  }
}
