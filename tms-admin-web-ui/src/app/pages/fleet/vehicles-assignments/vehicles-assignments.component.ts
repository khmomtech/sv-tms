import { Component, OnInit } from '@angular/core';
import { CommonModule } from '@angular/common';
import { HttpClient } from '@angular/common/http';
import { firstValueFrom } from 'rxjs';

interface VehicleAssignmentRow {
  vehicleId: number;
  vehicleCode: string;
  permanentDriver?: { id: number; name: string };
  temporaryDriver?: { id: number; name: string; expiresAt?: string; remainingMinutes?: number };
  effectiveDriver?: { id: number; name: string };
}

@Component({
  selector: 'app-vehicles-assignments',
  standalone: true,
  imports: [CommonModule],
  templateUrl: './vehicles-assignments.component.html',
  styleUrls: ['./vehicles-assignments.component.css'],
})
export class VehiclesAssignmentsComponent implements OnInit {
  rows: VehicleAssignmentRow[] = [];
  loading = false;
  error?: string;

  constructor(private http: HttpClient) {}

  async ngOnInit(): Promise<void> {
    this.loading = true;
    try {
      // Admin endpoint provided by backend; proxied via Angular dev proxy
      const data: any[] = await firstValueFrom(
        this.http.get<any>('/api/admin/driver-assignments/vehicles'),
      );
      this.rows = (data || []).map((d: any) => ({
        vehicleId: d.vehicle?.id,
        vehicleCode: d.vehicle?.code || d.vehicle?.plateNumber,
        permanentDriver: d.permanentDriver
          ? { id: d.permanentDriver.id, name: d.permanentDriver.name }
          : undefined,
        temporaryDriver: d.temporaryDriver
          ? {
              id: d.temporaryDriver.id,
              name: d.temporaryDriver.name,
              expiresAt: d.tempAssignmentExpiry,
              remainingMinutes: (() => {
                if (d.remainingMinutes != null) return d.remainingMinutes;
                if (d.tempAssignmentExpiry) {
                  const ms = new Date(d.tempAssignmentExpiry).getTime() - Date.now();
                  const minutes = Math.max(0, Math.floor(ms / 60000));
                  return Number.isFinite(minutes) ? minutes : undefined;
                }
                return undefined;
              })(),
            }
          : undefined,
        effectiveDriver: d.effectiveDriver
          ? { id: d.effectiveDriver.id, name: d.effectiveDriver.name }
          : undefined,
      }));
    } catch (e: any) {
      this.error = e?.message || 'Failed to load assignments';
    } finally {
      this.loading = false;
    }
  }
}
