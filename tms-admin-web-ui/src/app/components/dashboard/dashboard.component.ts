// Imports

import { CommonModule } from '@angular/common';
// eslint-disable-next-line @typescript-eslint/consistent-type-imports
import { HttpClient, HttpHeaders } from '@angular/common/http';
import { Component, ViewChild, ChangeDetectionStrategy } from '@angular/core';
import type { OnInit } from '@angular/core';
import { FormsModule } from '@angular/forms';
import { MapInfoWindow, MapMarker, GoogleMapsModule } from '@angular/google-maps';
// eslint-disable-next-line @typescript-eslint/consistent-type-imports
import { Router } from '@angular/router';

import { environment } from '../../environments/environment';
import { ApiResponse } from '../../models/api-response.model';
import type { User } from '../../models/user.model';
// eslint-disable-next-line @typescript-eslint/consistent-type-imports
import { AuthService } from '../../services/auth.service';

@Component({
  selector: 'app-dashboard',
  standalone: true,
  imports: [CommonModule, FormsModule, GoogleMapsModule],
  templateUrl: './dashboard.component.html',
  styleUrls: ['./dashboard.component.css'],
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class DashboardComponent implements OnInit {
  @ViewChild(MapInfoWindow) infoWindow!: MapInfoWindow;

  loadingSummary: any[] = [];
  loadingSummaryTotals: any = {
    totalTrip: 0,
    completedLoading: 0,
    pending: 0,
    truckArrived: 0,
    truckNotArrived: 0,
    achievedPercentage: 0,
  };

  summary: any = {};
  summaryStats: any[] = [];
  topDrivers: any[] = [];
  liveDrivers: any[] = [];

  users: User[] = [];
  selectedUser!: User;
  isModalOpen = false;
  isEditing = false;

  filters = {
    fromDate: '',
    toDate: '',
    truckType: '',
    customerName: '',
  };

  availableRoles = ['ADMIN', 'USER', 'MANAGER'];
  selectedDriver: any = null;

  isLoading: boolean = false;

  mapCenter: google.maps.LatLngLiteral = { lat: 11.5564, lng: 104.9282 };
  mapZoom = 12;
  mapOptions: google.maps.MapOptions = {
    mapTypeControl: false,
    streetViewControl: false,
    fullscreenControl: false,
  };

  constructor(
    private http: HttpClient,
    private authService: AuthService,
    private router: Router,
  ) {}

  ngOnInit(): void {
    this.loadSummaryStats();
  }

  private getHeaders(): HttpHeaders {
    return new HttpHeaders({
      'Content-Type': 'application/json',
      Authorization: `Bearer ${this.authService.getToken()}`,
    });
  }

  // 📈 Load Additional Summary Stats (Optional)
  loadSummaryStats(): void {
    const params: any = {};
    if (this.filters.fromDate) params.fromDate = this.filters.fromDate;
    if (this.filters.toDate) params.toDate = this.filters.toDate;
    if (this.filters.truckType) params.truckType = this.filters.truckType;
    if (this.filters.customerName) params.customerName = this.filters.customerName;

    this.http
      .get<any>(`${environment.baseUrl}/api/admin/dashboard/summary-stats`, {
        headers: this.getHeaders(),
        params,
      })
      .subscribe({
        next: (res) => {
          const summaryData = res?.data || [];
          this.summaryStats = summaryData;
          this.loadingSummary = summaryData;
          this.calculateTotals();
        },
        error: (err) => {
          console.error('Error loading summary stats:', err);
        },
      });
  }

  private calculateTotals(): void {
    const totals = {
      totalTrip: 0,
      completedLoading: 0,
      pending: 0,
      truckArrived: 0,
      truckNotArrived: 0,
      achievedPercentage: 0,
    };
    for (const row of this.loadingSummary) {
      // Use default values for missing fields
      const totalTrip = Number(row.totalTrip) || 0;
      const completedLoading = Number(row.completedLoading) || 0;
      const pending = Number(row.pending) || 0;
      const truckArrived = Number(row.truckArrived) || 0;
      const truckNotArrived = Number(row.truckNotArrived) || 0;
      row.achievedPercentage = totalTrip > 0 ? (completedLoading / totalTrip) * 100 : 0;

      totals.totalTrip += totalTrip;
      totals.completedLoading += completedLoading;
      totals.pending += pending;
      totals.truckArrived += truckArrived;
      totals.truckNotArrived += truckNotArrived;
    }
    totals.achievedPercentage =
      totals.totalTrip > 0 ? (totals.completedLoading / totals.totalTrip) * 100 : 0;
    this.loadingSummaryTotals = totals;
  }

  applyDateFilter(): void {
    this.loadSummaryStats();
  }
}
