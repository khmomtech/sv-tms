import { inject } from '@angular/core';
import { MatSnackBar } from '@angular/material/snack-bar';
import type { ResolveFn } from '@angular/router';
import { Router } from '@angular/router';
import type { Observable } from 'rxjs';
import { of, EMPTY } from 'rxjs';
import { catchError, map, tap } from 'rxjs/operators';

import { DriverService } from '../services/driver.service';

export interface DriverDocumentsResolverData {
  drivers: any[];
  totalDrivers: number;
  error?: string;
}

export const DriverDocumentsResolver: ResolveFn<DriverDocumentsResolverData> = (
  route,
  state,
): Observable<DriverDocumentsResolverData> => {
  const driverService = inject(DriverService);
  const router = inject(Router);
  const snackBar = inject(MatSnackBar);

  console.log('🔄 Resolving driver documents data...');

  return driverService.getDrivers(0, 1000).pipe(
    tap((response: any) => {
      console.log('Driver documents resolver: Data loaded successfully');

      // Validate response structure
      let driversData: any[] = [];
      if (response?.data?.content && Array.isArray(response.data.content)) {
        driversData = response.data.content;
      } else if (response?.data && Array.isArray(response.data)) {
        driversData = response.data;
      } else if (Array.isArray(response)) {
        driversData = response;
      }

      if (driversData.length === 0) {
        console.warn('⚠️ No drivers found in the system');
        snackBar.open(
          'No drivers found. Please add drivers first before accessing documents.',
          'Close',
          { duration: 6000, panelClass: ['warning-snackbar'] },
        );
      }
    }),
    map((response: any) => {
      // Extract and validate drivers data
      let driversData: any[] = [];
      if (response?.data?.content && Array.isArray(response.data.content)) {
        driversData = response.data.content;
      } else if (response?.data && Array.isArray(response.data)) {
        driversData = response.data;
      } else if (Array.isArray(response)) {
        driversData = response;
      }

      return {
        drivers: driversData,
        totalDrivers: driversData.length,
      };
    }),
    catchError((error: any) => {
      console.error('❌ Driver documents resolver error:', error);

      let errorMessage = 'Failed to load driver data. ';
      let shouldNavigate = false;

      if (error.status === 401) {
        errorMessage = 'Authentication required. Please login again.';
        shouldNavigate = true;
      } else if (error.status === 403) {
        errorMessage = 'Access denied. You need DRIVER_VIEW_ALL or DRIVER_MANAGE permission.';
        shouldNavigate = true;
      } else if (error.status === 0) {
        errorMessage = 'Backend server is not responding. Please ensure the backend is running.';
      } else {
        errorMessage += `Error ${error.status}: ${error.statusText || 'Unknown error'}`;
      }

      snackBar.open(errorMessage, 'Close', {
        duration: 8000,
        panelClass: ['error-snackbar'],
      });

      if (shouldNavigate) {
        router.navigate(['/unauthorized']);
        return EMPTY;
      }

      // Return empty data to allow component to load with error state
      return of({
        drivers: [],
        totalDrivers: 0,
        error: errorMessage,
      });
    }),
  );
};
