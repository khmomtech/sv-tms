import { Injectable } from '@angular/core';
import type { Observable } from 'rxjs';
import { filter, map } from 'rxjs/operators';

import type { DriverLocation } from './socket.service';
import { SocketService } from './socket.service';

/**
 * @deprecated Keep for backward compatibility only.
 * Use SocketService directly for all new realtime telematics flows.
 */
@Injectable({
  providedIn: 'root',
})
export class DriverLocationService {
  constructor(private readonly socketService: SocketService) {}

  connect(): void {
    // Legacy clients typically call connect() without context driver ids.
    // We keep global subscriptions alive through a default context.
    this.socketService.connect([], 'legacy-driver-location-service');
  }

  subscribeToDriver(driverId: number): Observable<DriverLocation> {
    this.socketService.connect([String(driverId)], `legacy-driver-${driverId}`);
    return this.socketService.driverLocation$.pipe(
      filter((v): v is DriverLocation => !!v && String(v.driverId) === String(driverId)),
    );
  }

  subscribeToAll(): Observable<DriverLocation> {
    this.connect();
    return this.socketService.globalLocation$.pipe(filter((v): v is DriverLocation => !!v));
  }

  subscribeToStatus(): Observable<string> {
    return this.socketService.status$.pipe(map((s) => String(s)));
  }

  disconnect(): void {
    this.socketService.disconnectContext('legacy-driver-location-service');
  }
}
