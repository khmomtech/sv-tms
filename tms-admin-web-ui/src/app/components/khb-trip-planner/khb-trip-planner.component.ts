import { CommonModule } from '@angular/common';
// eslint-disable-next-line @typescript-eslint/consistent-type-imports
import { HttpClient, HttpClientModule, HttpHeaders } from '@angular/common/http';
import { Component, inject } from '@angular/core';
import { FormsModule } from '@angular/forms';
import { firstValueFrom } from 'rxjs';

import { environment } from '../../environments/environment';
// eslint-disable-next-line @typescript-eslint/consistent-type-imports
import { AuthService } from '../../services/auth.service';
import { NotificationService } from '../../services/notification.service';

type TruckKey =
  | 'smallVanOwn11'
  | 'smallVanOwn8'
  | 'smallVanSub11'
  | 'smallVanSub8'
  | 'bigTruckOwn'
  | 'bigTruckSub';

@Component({
  selector: 'app-khb-trip-planner',
  standalone: true,
  imports: [CommonModule, FormsModule, HttpClientModule],
  templateUrl: './khb-trip-planner.component.html',
  styleUrls: ['./khb-trip-planner.component.css'],
})
export class KhbTripPlannerComponent {
  private notification = inject(NotificationService);
  uploadDate: string = '';
  zone: string = '';
  distributorCode: string = '';

  trips: any[] = [];
  finalSummary: any[] = [];
  dynamicProductColumns: string[] = [];

  groupedTrips: { [tripKey: string]: any[] } = {};
  tripTotals: { [tripKey: string]: number } = {};
  tripZoneCounts: { [zone: string]: number } = {};

  summary = {
    totalTrips: 0,
    totalQuantity: 0,
    totalPallets: 0,
    totalDropOffs: 0,
    totalDistributors: 0,
    totalTrucksUsed: 0,
    smallVanCount: 0,
    bigTruckCount: 0,
  };

  truckInput: Record<TruckKey, { pallets: number; trucks: number }> = {
    smallVanOwn11: { pallets: 0, trucks: 7 },
    smallVanOwn8: { pallets: 0, trucks: 16 },
    smallVanSub11: { pallets: 0, trucks: 11 },
    smallVanSub8: { pallets: 0, trucks: 13 },
    bigTruckOwn: { pallets: 0, trucks: 0 },
    bigTruckSub: { pallets: 0, trucks: 0 },
  };

  truckInputKeys: TruckKey[] = Object.keys(this.truckInput) as TruckKey[];
  keyLabels: Record<TruckKey, string> = {
    smallVanOwn11: 'SMALL VAN OWN (11)',
    smallVanOwn8: 'SMALL VAN OWN (8)',
    smallVanSub11: 'SMALL VAN SUB (11)',
    smallVanSub8: 'SMALL VAN SUB (8)',
    bigTruckOwn: 'BIG TRUCK OWN',
    bigTruckSub: 'BIG TRUCK SUB',
  };

  totalPages = 0;
  currentPage = 0;
  pageSize = 1000;
  loading = false;
  errorMsg: string = '';

  private readonly BASE_URL = `${environment.baseUrl}/api/khb-so-upload`;
  private readonly VEHICLE_SEARCH_URL = `${environment.baseUrl}/api/admin/vehicles/search`;
  private readonly VEHICLE_PAGE_SIZE = 500;
  private readonly plateToDriverName = new Map<string, string>();
  private readonly plateToVehicleId = new Map<string, number>();
  private vehicleLookupLoaded = false;

  private colorMap: { [truck: string]: string } = {};
  private colorClasses: string[] = [
    'table-primary',
    'table-secondary',
    'table-success',
    'table-danger',
    'table-warning',
    'table-info',
    'table-light',
    'table-dark',
  ];

  constructor(
    private http: HttpClient,
    private authService: AuthService,
  ) {}

  getAuthHeaders(): HttpHeaders {
    const token = this.authService.getToken();
    return new HttpHeaders({
      Authorization: token ? `Bearer ${token}` : '',
    });
  }

  getVehicleColorClass(trip: any): string {
    const truck = trip.assignedVehicleNumber || trip.truckNo || 'Unassigned';
    if (!this.colorMap[truck]) {
      const index = Object.keys(this.colorMap).length % this.colorClasses.length;
      this.colorMap[truck] = this.colorClasses[index];
    }
    return this.colorMap[truck];
  }

  tripZoneKeys(): string[] {
    return Object.keys(this.tripZoneCounts);
  }

  searchTrips(page: number = 0): void {
    if (!this.uploadDate) {
      this.errorMsg = 'Please select upload date.';
      return;
    }

    this.loading = true;
    const params: any = {
      uploadDate: this.uploadDate,
      page,
      size: this.pageSize,
    };
    if (this.zone) params.zone = this.zone;
    if (this.distributorCode) params.distributorCode = this.distributorCode;

    this.http
      .get<any>(`${this.BASE_URL}/plan-trip`, {
        headers: this.getAuthHeaders(),
        params,
      })
      .subscribe({
        next: (res) => {
          this.trips = res.content;
          this.totalPages = res.totalPages;
          this.currentPage = res.number;
          void this.processTripData();
        },
        error: (err) => {
          console.error(' Trip Plan Load Error:', err);
          this.resetState('Failed to load trips.');
        },
      });
  }

  loadPreviewFromTemp(): void {
    if (!this.uploadDate) {
      this.notification.simulateNotification('Notice', '⚠️ Please select upload date.');
      return;
    }

    this.loading = true;
    const params: any = { uploadDate: this.uploadDate };
    if (this.zone) params.zone = this.zone;

    this.http
      .get<any[]>(`${this.BASE_URL}/plan-trip/temp`, {
        headers: this.getAuthHeaders(),
        params: params,
      })
      .subscribe({
        next: (res) => {
          this.trips = res;
          this.totalPages = 1;
          this.currentPage = 0;
          void this.processTripData();
        },
        error: (err) => {
          console.error(' Load Preview Error:', err);
          this.resetState('Failed to load preview.');
        },
      });
  }

  saveToTempPreview(): void {
    if (!this.trips.length) {
      this.notification.simulateNotification('Notice', '⚠️ No trips to save.');
      return;
    }

    const payload = this.trips.map((trip) => ({
      uploadDate: this.uploadDate,
      tripNo: trip.tripNo,
      truckNo: trip.assignedVehicleNumber || trip.truckNo || '',
      soNumber: trip.soNumber || '',
      docNo: trip.docNo || '',
      dropOff: trip.dropOffLocation || trip.dropOff || '',
      product: trip.productName || trip.product || '',
      qty: trip.quantity || trip.qty || 0,
      qtyPerPallet: trip.qtyPerPallet || 0,
      palletEstimate: trip.palletEstimate || 0,
      truckPalletCapacity: trip.vehicleMaxPalletCapacity || trip.truckPalletCapacity || 0,
      zone: trip.zone || '',
      distributorCode: trip.distributorCode || '',
      distributorName: trip.dropOffLocation || trip.distributorName || '',
      estimatedPallet: trip.estimatedPallet || trip.palletEstimate || 0,
      truckCapacity: trip.truckCapacity || 0,
      plant: trip.plant || '',
      shipToParty: trip.shipToParty || '',
      shipToPartyName: trip.shipToPartyName || '',
      driverName: trip.displayDriverName || this.resolveDriverNameForTrip(trip),
    }));

    this.http
      .post(`${this.BASE_URL}/plan-trip/preview`, payload, {
        headers: this.getAuthHeaders(),
      })
      .subscribe({
        next: () =>
          this.notification.simulateNotification('Success', 'Trips saved to temp preview table.'),
        error: (err) => {
          console.error(' Temp Save Error:', err);
          this.notification.simulateNotification('Error', 'Failed to save preview.');
        },
      });
  }

  private async processTripData(): Promise<void> {
    await this.ensureVehicleLookupLoaded();
    this.errorMsg = '';
    this.colorMap = {};
    this.groupedTrips = {};
    this.tripTotals = {};
    this.tripZoneCounts = {};

    for (let trip of this.trips) {
      trip.displayDriverName = this.resolveDriverNameForTrip(trip);
      const key = `${trip.tripNo || 'Unassigned'}|${trip.plant || 'Unknown'}`;
      if (!this.groupedTrips[key]) {
        this.groupedTrips[key] = [];
        this.tripTotals[key] = 0;
      }
      this.groupedTrips[key].push(trip);
      this.tripTotals[key] += trip.palletEstimate;

      const zone = trip.zone || 'Unknown';
      this.tripZoneCounts[zone] = (this.tripZoneCounts[zone] || 0) + 1;
    }

    const uniqueTrips = new Set(this.trips.map((t) => `${t.tripNo}|${t.plant}`));
    const uniqueTrucks = new Set(this.trips.map((t) => t.assignedVehicleNumber || t.truckNo));
    const uniqueDropOffs = new Set(this.trips.map((t) => t.dropOffLocation || t.distributorName));
    const uniqueDistributors = new Set(this.trips.map((t) => t.distributorCode));

    this.summary = {
      totalTrips: uniqueTrips.size,
      totalQuantity: this.trips.reduce((sum, t) => sum + (t.quantity || t.qty || 0), 0),
      totalPallets: this.trips.reduce((sum, t) => sum + (t.palletEstimate || 0), 0),
      totalDropOffs: uniqueDropOffs.size,
      totalDistributors: uniqueDistributors.size,
      totalTrucksUsed: uniqueTrucks.size,
      smallVanCount: this.trips.filter(
        (t) => (t.vehicleMaxPalletCapacity || t.truckPalletCapacity) === 10,
      ).length,
      bigTruckCount: this.trips.filter(
        (t) => (t.vehicleMaxPalletCapacity || t.truckPalletCapacity) === 22,
      ).length,
    };
    this.loading = false;
  }

  loadFinalSummary(): void {
    if (!this.uploadDate) {
      this.notification.simulateNotification('Notice', '⚠️ Please select upload date.');
      return;
    }

    this.http
      .get<any[]>(`${this.BASE_URL}/report/final-summary`, {
        headers: this.getAuthHeaders(),
        params: { uploadDate: this.uploadDate, zone: this.zone },
      })
      .subscribe({
        next: (res) => {
          this.finalSummary = res;
          this.extractDynamicProductColumns();
        },
        error: (err) => {
          console.error(' Final Summary Load Error:', err);
          this.notification.simulateNotification('Error', 'Failed to load final summary.');
        },
      });
  }

  extractDynamicProductColumns(): void {
    const productSet = new Set<string>();
    for (const row of this.finalSummary) {
      const keys = Object.keys(row.productQuantities || {});
      keys.forEach((k) => productSet.add(k));
    }
    this.dynamicProductColumns = Array.from(productSet).sort();
  }

  exportTripPlan(): void {
    if (!this.uploadDate) {
      this.notification.simulateNotification(
        'Notice',
        '⚠️ Please select an upload date to export.',
      );
      return;
    }

    const params: any = { uploadDate: this.uploadDate };
    if (this.zone) params.zone = this.zone;
    if (this.distributorCode) params.distributorCode = this.distributorCode;

    this.http
      .get(`${this.BASE_URL}/plan-trip/export`, {
        headers: this.getAuthHeaders(),
        params,
        responseType: 'blob',
      })
      .subscribe({
        next: (blob) => {
          const url = window.URL.createObjectURL(blob);
          const a = document.createElement('a');
          a.href = url;
          a.download = `trip-plan-${this.uploadDate}${this.zone ? '-' + this.zone : ''}.xlsx`;
          a.click();
          window.URL.revokeObjectURL(url);
        },
        error: (err) => {
          console.error(' Export Error:', err);
          this.notification.simulateNotification('Error', 'Failed to export trip plan.');
        },
      });
  }

  exportFinalSummary(): void {
    if (!this.uploadDate) {
      this.notification.simulateNotification('Notice', '⚠️ Please select an upload date.');
      return;
    }

    this.http
      .get(`${this.BASE_URL}/khb/final-summary/excel`, {
        headers: this.getAuthHeaders(),
        params: { date: this.uploadDate, zone: this.zone },
        responseType: 'blob',
      })
      .subscribe({
        next: (blob) => {
          const url = window.URL.createObjectURL(blob);
          const a = document.createElement('a');
          a.href = url;
          a.download = `Final_Summary_${this.uploadDate}.xlsx`;
          a.click();
          window.URL.revokeObjectURL(url);
        },
        error: (err) => {
          console.error(' Export Final Summary Error:', err);
          this.notification.simulateNotification('Error', 'Failed to export final summary.');
        },
      });
  }

  nextPage(): void {
    if (this.currentPage + 1 < this.totalPages) {
      this.searchTrips(this.currentPage + 1);
    }
  }

  prevPage(): void {
    if (this.currentPage > 0) {
      this.searchTrips(this.currentPage - 1);
    }
  }

  private resetState(message: string): void {
    this.errorMsg = message;
    this.trips = [];
    this.groupedTrips = {};
    this.tripTotals = {};
    this.tripZoneCounts = {};
    this.loading = false;
  }

  private normalizePlate(rawPlate: string | null | undefined): string {
    return String(rawPlate || '')
      .trim()
      .toUpperCase()
      .replace(/\s+/g, '')
      .replace(/-/g, '');
  }

  private normalizeDriverName(rawTrip: any): string {
    return (
      rawTrip?.driverName ||
      rawTrip?.driverFullName ||
      rawTrip?.assignedDriver ||
      rawTrip?.assignedDriverName ||
      'Unassigned'
    );
  }

  private resolveDriverNameForTrip(trip: any): string {
    const plate = this.normalizePlate(trip?.assignedVehicleNumber || trip?.truckNo);
    if (plate && this.plateToDriverName.has(plate)) {
      return this.plateToDriverName.get(plate) || 'Unassigned';
    }
    return this.normalizeDriverName(trip);
  }

  private extractVehiclePage(payload: any): {
    content: any[];
    pageNumber: number;
    totalPages: number;
  } {
    const data = payload?.data ?? payload;
    const content = Array.isArray(data?.content) ? data.content : [];
    const totalPages = Number(data?.totalPages ?? payload?.totalPages ?? 1) || 1;
    const pageNumber = Number(data?.number ?? payload?.number ?? 0) || 0;
    return { content, pageNumber, totalPages };
  }

  private async ensureVehicleLookupLoaded(): Promise<void> {
    if (this.vehicleLookupLoaded) return;

    this.plateToDriverName.clear();
    this.plateToVehicleId.clear();

    let page = 0;
    let totalPages = 1;
    while (page < totalPages) {
      const response = await firstValueFrom(
        this.http.get<any>(this.VEHICLE_SEARCH_URL, {
          headers: this.getAuthHeaders(),
          params: {
            page,
            size: this.VEHICLE_PAGE_SIZE,
          },
        }),
      );
      const parsed = this.extractVehiclePage(response);
      for (const vehicle of parsed.content) {
        const plate = this.normalizePlate(vehicle?.licensePlate || vehicle?.plateNumber);
        if (!plate) continue;
        if (vehicle?.id != null) {
          this.plateToVehicleId.set(plate, Number(vehicle.id));
        }
        const driverName =
          vehicle?.assignedDriver?.fullName ||
          vehicle?.assignedDriver?.name ||
          vehicle?.driverName ||
          vehicle?.driverFullName ||
          vehicle?.assignedDriverName;
        if (driverName) {
          this.plateToDriverName.set(plate, String(driverName));
        }
      }
      page = parsed.pageNumber + 1;
      totalPages = parsed.totalPages;
    }

    this.vehicleLookupLoaded = true;
  }
}
