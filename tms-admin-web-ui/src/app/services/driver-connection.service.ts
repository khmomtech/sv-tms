// driver-connection.service.ts
// eslint-disable-next-line @typescript-eslint/consistent-type-imports
import { HttpClient } from '@angular/common/http';
import { Injectable } from '@angular/core';
import { catchError, delay, retryWhen, throwError } from 'rxjs';

import { environment } from '../environments/environment';

// eslint-disable-next-line @typescript-eslint/consistent-type-imports
import { SocketService } from './socket.service';

@Injectable({ providedIn: 'root' })
export class DriverConnectionService {
  private readonly driverUrl = `${environment.apiBaseUrl}/admin/drivers/all`;

  constructor(
    private http: HttpClient,
    private socketService: SocketService,
  ) {}

  connectToDriverUpdates(): void {
    this.http
      .get<any[]>(this.driverUrl)
      .pipe(
        retryWhen((errors) =>
          errors.pipe(
            delay(5000),
            // log and rethrow
            catchError((err) => {
              console.error(' Retry failed:', err);
              return throwError(() => err);
            }),
          ),
        ),
      )
      .subscribe({
        next: (drivers) => {
          const activeDriverIds = drivers
            .filter((d) => d.status === 'ACTIVE')
            .map((d) => d.id?.toString());

          console.log('🔗 Connecting to drivers:', activeDriverIds);
          this.socketService.connect(activeDriverIds, 'driver-connection');
        },
        error: (err) => {
          console.error(' Failed to fetch drivers:', err);
        },
      });
  }
}
