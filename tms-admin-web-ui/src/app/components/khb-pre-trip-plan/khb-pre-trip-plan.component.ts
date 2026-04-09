import { CommonModule } from '@angular/common';
// eslint-disable-next-line @typescript-eslint/consistent-type-imports
import { HttpClient, HttpClientModule, HttpHeaders } from '@angular/common/http';
import type { OnInit } from '@angular/core';
import { Component, inject } from '@angular/core';
import { FormsModule } from '@angular/forms';

import { environment } from '../../environments/environment';
// eslint-disable-next-line @typescript-eslint/consistent-type-imports
import { AuthService } from '../../services/auth.service';
import { NotificationService } from '../../services/notification.service';

interface TripData {
  [key: string]: number;
}

interface TripRow {
  distributor: string;
  shipTo: string;
  truck8: number;
  truck10: number;
  truck11: number;
  truck22: number;
  posm: string;
  zone?: string;
  totalPallet: number;
  plannedPallet?: number;
  remainPallet?: number;
  trips: TripData;
}

interface TripPrePlanResponse {
  distributorCode: string;
  shipToParty: string;
  zone: string;
  totalPallet: number;
  plannedPallet: number;
  remainPallet: number;
  truck8: number;
  truck10: number;
  truck11: number;
  truck22: number;
  posm: string;
  trips: { [tripNo: string]: number };
}

@Component({
  selector: 'app-trip-pre-plan',
  standalone: true,
  imports: [CommonModule, FormsModule, HttpClientModule],
  templateUrl: './khb-pre-trip-plan.component.html',
  styleUrls: ['./khb-pre-trip-plan.component.css'],
})
export class TripPrePlanComponent implements OnInit {
  private notification = inject(NotificationService);
  private readonly BASE_URL = `${environment.baseUrl}/api/khb-so-upload`;

  trips = Array.from({ length: 20 }, (_, i) => i + 1);
  data: TripRow[] = [];
  zones: string[] = ['PHNOM_PENH', 'PROVINCE'];
  selectedZone = 'PHNOM_PENH';
  distributorSearch = '';
  uploadDate = '';
  editMode = false;

  constructor(
    private http: HttpClient,
    private authService: AuthService,
  ) {}

  ngOnInit(): void {
    const today = new Date();
    this.uploadDate = today.toISOString().slice(0, 10);
    this.loadData();
  }

  toggleEditMode(): void {
    this.editMode = !this.editMode;
  }

  getAuthHeaders(): HttpHeaders {
    const token = this.authService.getToken();
    return new HttpHeaders({
      Authorization: token ? `Bearer ${token}` : '',
    });
  }

  loadData(): void {
    const params: any = {
      uploadDate: this.uploadDate,
      zone: this.selectedZone,
    };

    this.http
      .get<TripPrePlanResponse[]>(`${this.BASE_URL}/pre-plan/summary`, {
        params,
        headers: this.getAuthHeaders(),
      })
      .subscribe((response) => {
        const zoneSet = new Set<string>(this.zones);

        this.data = (response || []).map((u) => {
          zoneSet.add(u.zone || 'PHNOM_PENH');
          const row: TripRow = {
            distributor: u.distributorCode,
            shipTo: u.shipToParty,
            truck8: u.truck8 || 0,
            truck10: u.truck10 || 0,
            truck11: u.truck11 || 0,
            truck22: u.truck22 || 0,
            posm: u.posm || '',
            zone: u.zone || 'PHNOM_PENH',
            totalPallet: u.totalPallet || 0,
            plannedPallet: u.plannedPallet || 0,
            remainPallet: u.remainPallet || 0,
            trips: u.trips || {},
          };
          return row;
        });

        this.zones = Array.from(zoneSet).filter((z) => !!z);
      });
  }

  calculateTotalPallet(row: TripRow): number {
    let planned = 0,
      t8 = 0,
      t10 = 0,
      t11 = 0,
      t22 = 0;

    Object.values(row.trips || {}).forEach((value) => {
      const pallets = Number(value) || 0;
      planned += pallets;

      if (pallets > 0) {
        if (pallets <= 8) t8++;
        else if (pallets <= 10) t10++;
        else if (pallets <= 11) t11++;
        else if (pallets <= 22) t22++;
      }
    });

    row.plannedPallet = planned;
    row.remainPallet = row.totalPallet - planned;
    row.truck8 = t8;
    row.truck10 = t10;
    row.truck11 = t11;
    row.truck22 = t22;

    return planned;
  }

  save(): void {
    const payload = {
      uploadDate: this.uploadDate,
      zone: this.selectedZone || 'PHNOM_PENH',
      data: this.data,
    };

    this.http
      .post(`${this.BASE_URL}/pre-plan/summary`, payload, {
        headers: this.getAuthHeaders(),
      })
      .subscribe({
        next: () =>
          this.notification.simulateNotification('Success', 'Pre-plan saved successfully.'),
        error: (err) =>
          this.notification.simulateNotification('Error', `Failed to save: ${err.message}`),
      });
  }
}
