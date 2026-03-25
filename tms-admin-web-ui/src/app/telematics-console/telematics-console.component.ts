/* eslint-disable @typescript-eslint/consistent-type-imports */
import { CommonModule } from '@angular/common';
import type { OnInit, OnDestroy } from '@angular/core';
import { Component } from '@angular/core';
import { FormsModule } from '@angular/forms';
import { GoogleMapsModule } from '@angular/google-maps';
import { TranslateModule } from '@ngx-translate/core';
import type { Subscription } from 'rxjs';

import type { DriverLocation } from '../services/socket.service';
import { SocketService } from '../services/socket.service';

@Component({
  selector: 'app-telematics-console',
  standalone: true,
  imports: [CommonModule, GoogleMapsModule, FormsModule, TranslateModule],
  templateUrl: './telematics-console.component.html',
  styleUrls: ['./telematics-console.component.css'],
})
export class TelematicsConsoleComponent implements OnInit, OnDestroy {
  searchTerm = '';
  filteredLogs: DriverLocation[] = [];
  selectedLocation: DriverLocation | null = null;
  connectionStatus: 'connected' | 'disconnected' = 'disconnected';

  private readonly subscriptions: Subscription[] = [];

  constructor(public socketService: SocketService) {}

  ngOnInit(): void {
    this.applySearch();

    this.subscriptions.push(
      this.socketService.driverLocation$.subscribe(() => {
        console.log('[Debug Console] Driver location updated');
        this.applySearch();
      }),
      this.socketService.globalLocation$.subscribe(() => {
        console.log('[Debug Console] Global location updated');
        this.applySearch();
      }),
      this.socketService.status$.subscribe((status) => {
        this.connectionStatus = status === 'connected' ? 'connected' : 'disconnected';
      }),
    );
  }

  applySearch(): void {
    // const term = this.searchTerm.toLowerCase();
    // this.filteredLogs = this.socketService.globalLocation$
    //   .filter((log: DriverLocation) =>
    //     log.driverId.toLowerCase().includes(term) ||
    //     (log.label ?? '').toLowerCase().includes(term)
    //   )
    //   .reverse();

    console.log('[Debug Console] Filtered logs count:', this.filteredLogs.length);
  }

  viewOnMap(log: DriverLocation): void {
    this.selectedLocation = log;
    console.log('[Debug Console] Viewing on map:', log);
  }

  ngOnDestroy(): void {
    this.subscriptions.forEach((sub) => sub.unsubscribe());
  }
}
