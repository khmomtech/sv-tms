import { CommonModule } from '@angular/common';
import type { OnInit, AfterViewInit, ElementRef } from '@angular/core';
import { Component, ViewChild, CUSTOM_ELEMENTS_SCHEMA } from '@angular/core';
import { FormsModule } from '@angular/forms';

declare const google: any;
declare const bootstrap: any;

@Component({
  selector: 'app-transport-order-maps',
  standalone: true,
  templateUrl: './transport-order-maps.component.html',
  styleUrls: ['./transport-order-maps.component.css'],
  imports: [CommonModule, FormsModule],
  schemas: [CUSTOM_ELEMENTS_SCHEMA],
})
export class TransportOrderMapsComponent implements OnInit, AfterViewInit {
  origin = '';
  destination = '';
  truckNo = '';
  driver = '';
  eta = '';

  drops: string[] = [];
  shipmentItems: any[] = [];
  selectedItem: any = {};
  modalRef!: HTMLElement;

  routeSummary = 'Route info will appear here.';
  routeDetails = '';

  showForm = true;
  showMap = true;

  directionsService: any;
  directionsRenderer: any;
  map: any;
  numberedMarkers: any[] = [];

  @ViewChild('mapRef') mapRef!: ElementRef;
  @ViewChild('itemModal') itemModal!: ElementRef;

  constructor() {}

  ngOnInit(): void {}

  ngAfterViewInit(): void {
    this.initMap();
    this.initPlacesAutocomplete();
  }

  initMap(): void {
    if (!this.mapRef) return;

    this.map = new google.maps.Map(this.mapRef.nativeElement, {
      center: { lat: 12.5657, lng: 104.991 },
      zoom: 7,
    });

    this.directionsService = new google.maps.DirectionsService();
    this.directionsRenderer = new google.maps.DirectionsRenderer({ suppressMarkers: true });
    this.directionsRenderer.setMap(this.map);
  }

  initPlacesAutocomplete(): void {
    const originEl = document.getElementById('origin') as any;
    const destinationEl = document.getElementById('destination') as any;

    if (originEl) {
      originEl.addEventListener('gmp-placechange', () => {
        const place = originEl.value;
        if (place) {
          this.origin = place;
          this.calculateRoute();
        }
      });
    }

    if (destinationEl) {
      destinationEl.addEventListener('gmp-placechange', () => {
        const place = destinationEl.value;
        if (place) {
          this.destination = place;
          this.calculateRoute();
        }
      });
    }
  }

  calculateRoute(): void {
    if (!this.origin || !this.destination) return;

    const waypoints = this.drops
      .filter((loc) => loc.trim())
      .map((loc) => ({ location: loc, stopover: true }));

    this.directionsService.route(
      {
        origin: this.origin,
        destination: this.destination,
        waypoints,
        optimizeWaypoints: false,
        travelMode: google.maps.TravelMode.DRIVING,
      },
      (result: any, status: any) => {
        if (status === 'OK') {
          this.directionsRenderer.setDirections(result);
          const route = result.routes[0];

          let totalDistance = 0;
          let totalDuration = 0;
          this.clearMarkers();

          const segments: string[] = [];

          route.legs.forEach((leg: any, i: number) => {
            totalDistance += leg.distance.value;
            totalDuration += leg.duration.value;
            segments.push(
              `<li><strong>From:</strong> ${leg.start_address}<br><strong>To:</strong> ${leg.end_address}<br><strong>Distance:</strong> ${leg.distance.text}, <strong>Duration:</strong> ${leg.duration.text}</li>`,
            );

            const marker = new google.maps.Marker({
              map: this.map,
              position: leg.start_location,
              label: `${i + 1}`,
            });

            this.numberedMarkers.push(marker);
          });

          const end = route.legs[route.legs.length - 1].end_location;
          this.numberedMarkers.push(
            new google.maps.Marker({
              map: this.map,
              position: end,
              label: `${route.legs.length + 1}`,
            }),
          );

          this.routeSummary = `Total Distance: ${(totalDistance / 1000).toFixed(2)} km`;
          this.routeDetails = `<ul>${segments.join('')}</ul>`;
        } else {
          this.routeSummary = 'Route error: ' + status;
          this.routeDetails = '';
        }
      },
    );
  }

  clearMarkers(): void {
    this.numberedMarkers.forEach((marker) => marker.setMap(null));
    this.numberedMarkers = [];
  }

  addDrop(): void {
    this.drops.push('');
  }

  removeDrop(i: number): void {
    this.drops.splice(i, 1);
    this.calculateRoute();
  }

  addRow(): void {
    this.shipmentItems.push({ description: '', qty: 1, type: '', weight: 0, drop: '' });
  }

  removeRow(i: number): void {
    this.shipmentItems.splice(i, 1);
  }

  openItemModal(index: number): void {
    this.selectedItem = { ...this.shipmentItems[index], _index: index };
    this.modalRef = this.itemModal.nativeElement;
    const modal = new bootstrap.Modal(this.modalRef);
    modal.show();
  }

  saveModal(): void {
    const i = this.selectedItem._index;
    this.shipmentItems[i] = { ...this.selectedItem };
    delete this.shipmentItems[i]._index;
    const modal = bootstrap.Modal.getInstance(this.modalRef);
    modal?.hide();
  }
}
