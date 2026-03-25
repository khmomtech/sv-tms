import { CommonModule } from '@angular/common';
import type { AfterViewInit } from '@angular/core';
import { Component, ViewChild, inject } from '@angular/core';
import { GoogleMap, GoogleMapsModule } from '@angular/google-maps';
import { NotificationService } from '../../services/notification.service';

@Component({
  selector: 'app-live-location',
  standalone: true,
  imports: [CommonModule, GoogleMapsModule],
  templateUrl: './live-location.component.html',
  styleUrls: ['./live-location.component.css'],
})
export class LiveLocationComponent implements AfterViewInit {
  private notification = inject(NotificationService);
  @ViewChild(GoogleMap) map!: GoogleMap;

  zoom = 12;
  center: google.maps.LatLngLiteral = { lat: 11.5564, lng: 104.9282 }; // Phnom Penh
  userMarker: google.maps.Marker | null = null;
  locationWatcherId: number | null = null;
  directionsService = new google.maps.DirectionsService();
  directionsRenderer = new google.maps.DirectionsRenderer();

  markers: google.maps.Marker[] = [];
  selectedStartMarker: google.maps.LatLngLiteral | null = null;
  selectedEndMarker: google.maps.LatLngLiteral | null = null;

  constructor() {}

  ngAfterViewInit() {
    this.trackLiveLocation();
    this.directionsRenderer.setMap(this.map.googleMap!);
  }

  //  Live Location Tracking
  trackLiveLocation() {
    if (navigator.geolocation) {
      this.locationWatcherId = navigator.geolocation.watchPosition(
        (position) => {
          this.center = {
            lat: position.coords.latitude,
            lng: position.coords.longitude,
          };

          if (this.userMarker) {
            this.userMarker.setMap(null);
          }

          this.userMarker = new google.maps.Marker({
            position: this.center,
            title: 'Your Location',
            icon: 'http://maps.google.com/mapfiles/ms/icons/blue-dot.png',
            map: this.map.googleMap!,
          });
        },
        (error) => {
          console.error('Error getting location: ', error);
        },
        {
          enableHighAccuracy: true,
          timeout: 5000,
          maximumAge: 0,
        },
      );
    } else {
      console.error('Geolocation is not supported by this browser.');
    }
  }

  //  Add Marker on Click
  addMarker(event: google.maps.MapMouseEvent) {
    if (!event.latLng) return;

    const newMarker = new google.maps.Marker({
      position: event.latLng,
      map: this.map.googleMap!,
      draggable: true,
    });

    //  Allow marker to be dragged
    newMarker.addListener('dragend', () => {
      console.log('Marker moved to:', newMarker.getPosition()?.toJSON());
    });

    this.markers.push(newMarker);
  }

  //  Select Start or End Point for Route
  selectMarkerForRoute(index: number) {
    if (!this.markers[index].getPosition()) return;

    const position = this.markers[index].getPosition()!.toJSON();

    if (!this.selectedStartMarker) {
      this.selectedStartMarker = position;
      console.log('Start location selected:', position);
    } else {
      this.selectedEndMarker = position;
      console.log('End location selected:', position);
      this.createRoute();
    }
  }

  //  Create Route Between Selected Points
  createRoute() {
    if (!this.selectedStartMarker || !this.selectedEndMarker) {
      this.notification.simulateNotification(
        'Notice',
        'Please select both start and end locations.',
      );
      return;
    }

    this.directionsService.route(
      {
        origin: this.selectedStartMarker,
        destination: this.selectedEndMarker,
        travelMode: google.maps.TravelMode.DRIVING,
      },
      (result, status) => {
        if (status === google.maps.DirectionsStatus.OK) {
          this.directionsRenderer.setDirections(result);
        } else {
          console.error('Error fetching directions:', status);
        }
      },
    );

    this.selectedStartMarker = null;
    this.selectedEndMarker = null;
  }

  //  Clear All Markers
  clearMarkers() {
    this.markers.forEach((marker) => marker.setMap(null));
    this.markers = [];
  }
}
