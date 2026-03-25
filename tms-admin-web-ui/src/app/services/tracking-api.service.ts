/**
 * Tracking API Service
 * Handles backend integration for shipment tracking
 */

import { HttpClient } from '@angular/common/http';
import { Injectable } from '@angular/core';
import type { Observable } from 'rxjs';
import { of, throwError } from 'rxjs';
import { catchError, map } from 'rxjs/operators';

import { environment } from '../../environments/environment';
import type {
  DispatchAssignment,
  DriverInfo,
  GeoLocation,
  OrderPoint,
  ProofOfDelivery,
  ShipmentItem,
  ShipmentStatus,
  StatusTimeline,
  TrackingError,
  TrackingResponse,
} from '../models/shipment-tracking.model';

@Injectable({
  providedIn: 'root',
})
export class TrackingApiService {
  private readonly apiUrl = `${environment.apiUrl}/public/tracking`;

  constructor(private http: HttpClient) {}

  /**
   * Track shipment by booking reference
   * @param reference - Booking reference (e.g., "BK-2026-00125")
   * @returns Observable of TrackingResponse
   */
  trackShipment(reference: string): Observable<TrackingResponse> {
    return this.http.get<Record<string, unknown>>(`${this.apiUrl}/${reference}`).pipe(
      map((response) => this.mapBackendResponse(response)),
      catchError((error) => {
        const trackingError: TrackingError = {
          code: error.status || 'UNKNOWN_ERROR',
          message: this.getErrorMessage(error),
          details: error.error?.message || error.statusText,
        };
        return throwError(() => trackingError);
      }),
    );
  }

  /**
   * Map backend API response to frontend TrackingResponse model
   * @param backendResponse - Raw API response
   * @returns Typed TrackingResponse
   */
  private mapBackendResponse(backendResponse: Record<string, unknown>): TrackingResponse {
    const data =
      (backendResponse?.['data'] as Record<string, unknown>) ||
      (backendResponse as Record<string, unknown>);

    // Extract pickup and delivery coordinates from dispatch data
    const pickupPoints = this.extractPickupPoints(data);
    const deliveryPoints = this.extractDeliveryPoints(data);
    const dispatches = this.extractDispatches(data);

    const dispatchData = data['dispatch'] as Record<string, unknown> | undefined;
    return {
      shipmentSummary: {
        bookingReference: (data['orderReference'] as string) || '',
        orderReference: (data['orderReference'] as string) || '',
        customerName: (data['customerName'] as string) || '',
        billTo: (data['billTo'] as string) || 'N/A',
        pickupLocation: (dispatchData?.['fromLocation'] as string) || 'N/A',
        deliveryLocation:
          (dispatchData?.['toLocation'] as string) || (data['billTo'] as string) || 'N/A',
        pickupPoint: pickupPoints[0], // Primary loading point
        deliveryPoint: deliveryPoints[0], // Primary unloading point
        serviceType: (data['shipmentType'] as 'LTL' | 'FTL' | 'EXPRESS' | 'STANDARD') || 'STANDARD',
        estimatedDelivery: this.formatDate(data['deliveryDate'] as number[] | string | undefined),
        actualDelivery:
          (data['orderStatus'] as string) === 'DELIVERED'
            ? this.formatDate(data['deliveryDate'] as number[] | string | undefined)
            : undefined,
        status: this.mapStatus(
          (data['orderStatus'] as string) || (dispatchData?.['status'] as string) || 'PENDING',
        ),
        transportationOrderStatus: ((dispatchData?.['status'] as string) ||
          (data['orderStatus'] as string) ||
          'PENDING') as string,
        cost: data['cost'] as number | undefined,
        items: this.extractItems(data),
      },
      timeline: this.buildTimeline(data),
      currentLocation: data['location']
        ? (() => {
            const locData = data['location'] as Record<string, unknown>;
            return {
              latitude: (locData['latitude'] as number) || 0,
              longitude: (locData['longitude'] as number) || 0,
              locationName: locData['locationName'] as string | undefined,
              lastSeen: locData['lastSeen'] as number | undefined,
              isOnline: locData['isOnline'] as boolean | undefined,
              accuracy: locData['accuracy'] as number | null | undefined,
              speed: locData['speed'] as number | null | undefined,
              heading: locData['heading'] as number | null | undefined,
              address: ((locData['locationName'] as string) ||
                (dispatchData?.['fromLocation'] as string) ||
                '') as string,
            } as GeoLocation;
          })()
        : undefined,
      driver: this.extractDriverInfo(data),
      proofOfDelivery: data['proofOfDelivery']
        ? (() => {
            const podData = data['proofOfDelivery'] as Record<string, unknown>;
            return {
              id: (podData['id'] as number) || 0,
              signature: podData['signature'] as string | undefined,
              photo: podData['photo'] as string | undefined,
              recipientName: (podData['recipientName'] as string) || '',
              deliveryTime: (podData['deliveryTime'] as string) || '',
              notes: podData['notes'] as string | undefined,
            } as ProofOfDelivery;
          })()
        : undefined,
      estimatedTimeOfArrival: this.formatDate(
        dispatchData?.['estimatedArrival'] as number[] | string | undefined,
      ),
      pickupPoints,
      deliveryPoints,
      items: this.extractItems(data),
      dispatches,
    };
  }

  /**
   * Format backend date array to ISO string
   * Backend returns: [year, month, day, hour?, minute?, second?, nano?]
   * @param dateArray - Backend date as array or string
   * @returns ISO string or empty string
   */
  private formatDate(dateArray: number[] | string | undefined): string {
    if (!dateArray) return '';
    if (typeof dateArray === 'string') return dateArray;

    if (Array.isArray(dateArray) && dateArray.length >= 3) {
      const [year, month, day, hour = 0, minute = 0, second = 0] = dateArray;
      try {
        const date = new Date(year, month - 1, day, hour, minute, second);
        return date.toISOString();
      } catch (error) {
        console.warn('Failed to format date:', dateArray, error);
        return '';
      }
    }
    return '';
  }

  /**
   * Map backend status to frontend ShipmentStatus
   * @param status - Backend status string
   * @returns Frontend ShipmentStatus
   */
  private mapStatus(status: string): ShipmentStatus {
    const statusMap: Record<string, ShipmentStatus> = {
      PENDING: 'ORDER_CONFIRMED',
      CONFIRMED: 'ORDER_CONFIRMED',
      ASSIGNED: 'DISPATCHED',
      IN_TRANSIT: 'IN_TRANSIT',
      DELIVERED: 'DELIVERED',
      CANCELLED: 'RETURNED',
    };
    return statusMap[status] || 'BOOKING_CREATED';
  }

  /**
   * Build timeline from backend data
   * @param data - Backend order data
   * @returns Array of StatusTimeline sorted by order
   */
  private buildTimeline(data: Record<string, unknown>): StatusTimeline[] {
    const timeline: StatusTimeline[] = [];

    timeline.push({
      status: 'BOOKING_CREATED',
      displayName: 'Booking Created',
      timestamp: this.formatDate(data['orderDate'] as number[] | string | undefined),
      completed: true,
      order: 0,
    });

    if ((data['orderStatus'] as string) !== 'PENDING') {
      timeline.push({
        status: 'ORDER_CONFIRMED',
        displayName: 'Order Confirmed',
        timestamp: this.formatDate(data['orderDate'] as number[] | string | undefined),
        completed: true,
        order: 1,
      });
    }

    const dispatchData = data['dispatch'] as Record<string, unknown> | undefined;
    if (dispatchData) {
      timeline.push({
        status: 'DISPATCHED',
        displayName: 'Dispatched',
        timestamp: this.formatDate(dispatchData['startTime'] as number[] | string | undefined),
        completed: true,
        order: 3,
      });

      if ((dispatchData['status'] as string) === 'IN_TRANSIT') {
        timeline.push({
          status: 'IN_TRANSIT',
          displayName: 'In Transit',
          timestamp: this.formatDate(dispatchData['updatedDate'] as number[] | string | undefined),
          completed: true,
          order: 4,
        });
      }
    }

    if ((data['orderStatus'] as string) === 'DELIVERED') {
      timeline.push({
        status: 'DELIVERED',
        displayName: 'Delivered',
        timestamp: this.formatDate(data['deliveryDate'] as number[] | string | undefined),
        completed: true,
        order: 6,
      });
    }

    return timeline.sort((a, b) => (a.order ?? 0) - (b.order ?? 0));
  }

  /**
   * Get current location for active shipment
   * Returns null if location not available instead of throwing error
   * @param reference - Booking reference
   * @returns Observable of current location or null if not available
   */
  getCurrentLocation(reference: string): Observable<GeoLocation | null> {
    return this.http.get<Record<string, unknown>>(`${this.apiUrl}/${reference}/location`).pipe(
      map((response: Record<string, unknown>) => {
        const responseData = response['data'] as Record<string, unknown> | undefined;
        // Check if location data exists in response
        if (responseData?.['hasLocation'] && responseData['location']) {
          const loc = responseData['location'] as Record<string, unknown>;
          // Map backend location to frontend GeoLocation model
          return {
            latitude: (loc['latitude'] as number) || 0,
            longitude: (loc['longitude'] as number) || 0,
            locationName: loc['locationName'] as string | undefined,
            lastSeen: loc['lastSeen'] as number | undefined,
            isOnline: loc['isOnline'] as boolean | undefined,
            accuracy: loc['accuracy'] as number | null | undefined,
            speed: loc['speed'] as number | null | undefined,
            heading: loc['heading'] as number | null | undefined,
            // Legacy fields for backward compatibility
            address: ((loc['locationName'] as string) || 'Unknown location') as string,
            city: '', // Not provided by backend
            lastUpdated: this.formatDate(loc['lastSeen'] as number[] | string | undefined),
          } as GeoLocation;
        }
        // Return null if no location available
        return null;
      }),
      catchError((error) => {
        console.error('Location fetch error:', error);
        // Return null instead of throwing to allow graceful handling
        return of(null);
      }),
    );
  }

  /**
   * Get proof of delivery
   * @param reference - Booking reference
   * @returns Observable of POD data
   */
  getProofOfDelivery(reference: string): Observable<ProofOfDelivery> {
    return this.http.get<ProofOfDelivery>(`${this.apiUrl}/${reference}/proof-of-delivery`).pipe(
      catchError((error) => {
        const trackingError: TrackingError = {
          code: error.status || 'POD_ERROR',
          message: 'Failed to fetch proof of delivery',
          details: error.error?.message || error.statusText,
        };
        return throwError(() => trackingError);
      }),
    );
  }

  /**
   * Get tracking history/timeline
   * @param reference - Booking reference
   * @returns Observable of timeline array
   */
  getTrackingHistory(reference: string): Observable<StatusTimeline[]> {
    return this.http.get<any[]>(`${this.apiUrl}/${reference}/history`).pipe(
      catchError((error) => {
        const trackingError: TrackingError = {
          code: error.status || 'HISTORY_ERROR',
          message: 'Failed to fetch tracking history',
          details: error.error?.message || error.statusText,
        };
        return throwError(() => trackingError);
      }),
    );
  }

  /**
   * Extract items from backend response
   * @param data - Backend order data
   * @returns Array of ShipmentItem
   */
  private extractItems(data: Record<string, unknown>): ShipmentItem[] {
    const items = data['items'] as unknown[];
    if (!items || !Array.isArray(items)) return [];

    return items
      .map((item: unknown) => {
        const itemData = item as Record<string, unknown>;
        return {
          description:
            (itemData['description'] as string) ||
            (itemData['productName'] as string) ||
            'Unknown Item',
          quantity: (itemData['quantity'] as number) || 1,
          uom: (itemData['uom'] as string) || (itemData['unitOfMeasure'] as string) || undefined,
          pallets: (itemData['pallets'] as number) || (itemData['pallet'] as number) || undefined,
          loadingPlace:
            (itemData['loadingPlace'] as string) ||
            (itemData['loading'] as string) ||
            (itemData['from'] as string) ||
            undefined,
          unloadingPlace:
            (itemData['unloadingPlace'] as string) ||
            (itemData['unloading'] as string) ||
            (itemData['to'] as string) ||
            undefined,
          warehouse: (itemData['warehouse'] as string) || undefined,
          weight: itemData['weight'] as number | undefined,
          dimension: itemData['dimension']
            ? {
                length:
                  ((itemData['dimension'] as Record<string, unknown>)['length'] as number) || 0,
                width: ((itemData['dimension'] as Record<string, unknown>)['width'] as number) || 0,
                height:
                  ((itemData['dimension'] as Record<string, unknown>)['height'] as number) || 0,
              }
            : undefined,
        };
      })
      .filter((item) => item.description && item.quantity > 0);
  }

  /**
   * Extract pickup points (loading locations) with coordinates
   * Points are sorted by sequence for display
   * Stops array format: { type: 'PICKUP', address: { name, address, latitude, longitude }, sequence, ... }
   * @param data - Backend order data
   * @returns Sorted array of OrderPoint
   */
  private extractPickupPoints(data: Record<string, unknown>): OrderPoint[] {
    const points: OrderPoint[] = [];

    // Use only order-level stops provided by backend
    const orderStops: any[] = Array.isArray((data as any)['stops'])
      ? ((data as any)['stops'] as any[])
      : [];

    if (orderStops.length > 0) {
      points.push(
        ...orderStops
          .filter((stop: any) => stop.type === 'PICKUP')
          .map((stop: any) => {
            const addr = stop.address as Record<string, unknown> | undefined;
            const actualArrival = stop.arrivalTime || stop.arrivedAt || stop.actualArrival;
            const actualDeparture = stop.departureTime || stop.departedAt || stop.actualDeparture;
            const status: 'PENDING' | 'ARRIVED' | 'DEPARTED' | 'COMPLETED' = actualDeparture
              ? 'DEPARTED'
              : actualArrival
                ? 'ARRIVED'
                : 'PENDING';

            return {
              name: addr?.['name'] || stop.name || 'Loading Point',
              address: addr?.['address'] || (typeof stop.address === 'string' ? stop.address : ''),
              type: 'PICKUP' as const,
              sequence: stop.sequence ?? stop.order ?? stop.stopOrder ?? stop.index ?? 0,
              eta: stop.eta || stop.estimatedArrival || stop.expectedTime,
              status,
              plannedArrival: stop.plannedArrival || stop.plannedTime || stop.eta,
              plannedDeparture: stop.plannedDeparture,
              actualArrival,
              actualDeparture,
              confirmedBy: stop.confirmedBy || stop.confirmed_by,
              contactPhone: stop.contactPhone || stop.contact_phone,
              contactName:
                stop.contactName ||
                stop.contact_name ||
                (addr?.['contactName'] as string) ||
                (addr?.['contact_name'] as string) ||
                undefined,
              remarks: stop.remarks,
              proofImageUrl: stop.proofImageUrl || stop.proof_image_url,
              coordinates: {
                latitude: (addr?.['latitude'] as number) || 0,
                longitude: (addr?.['longitude'] as number) || 0,
              },
            };
          }),
      );
    }

    return this.deduplicatePoints(points);
  }

  /**
   * Extract delivery points (unloading/drop locations) with coordinates
   * Points are sorted by sequence for display
   * Stops array format: { type: 'DROP', address: { name, address, latitude, longitude }, sequence, ... }
   * @param data - Backend order data
   * @returns Sorted array of OrderPoint
   */
  private extractDeliveryPoints(data: Record<string, unknown>): OrderPoint[] {
    const points: OrderPoint[] = [];

    // Use only order-level stops provided by backend
    const orderStops: any[] = Array.isArray((data as any)['stops'])
      ? ((data as any)['stops'] as any[])
      : [];

    if (orderStops.length > 0) {
      points.push(
        ...orderStops
          .filter((stop: any) => stop.type === 'DROP')
          .map((stop: any) => {
            const addr = stop.address as Record<string, unknown> | undefined;
            const actualArrival = stop.arrivalTime || stop.arrivedAt || stop.actualArrival;
            const actualDeparture = stop.departureTime || stop.departedAt || stop.actualDeparture;
            const status: 'PENDING' | 'ARRIVED' | 'DEPARTED' | 'COMPLETED' = actualDeparture
              ? 'DEPARTED'
              : actualArrival
                ? 'ARRIVED'
                : 'PENDING';

            return {
              name: addr?.['name'] || stop.name || 'Delivery Point',
              address: addr?.['address'] || (typeof stop.address === 'string' ? stop.address : ''),
              type: 'DROP' as const,
              sequence: stop.sequence ?? stop.order ?? stop.stopOrder ?? stop.index ?? 0,
              eta: stop.eta || stop.estimatedArrival || stop.expectedTime,
              status,
              plannedArrival: stop.plannedArrival || stop.plannedTime || stop.eta,
              plannedDeparture: stop.plannedDeparture,
              actualArrival,
              actualDeparture,
              confirmedBy: stop.confirmedBy || stop.confirmed_by,
              contactPhone: stop.contactPhone || stop.contact_phone,
              contactName:
                stop.contactName ||
                stop.contact_name ||
                (addr?.['contactName'] as string) ||
                (addr?.['contact_name'] as string) ||
                undefined,
              remarks: stop.remarks,
              proofImageUrl: stop.proofImageUrl || stop.proof_image_url,
              coordinates: {
                latitude: (addr?.['latitude'] as number) || 0,
                longitude: (addr?.['longitude'] as number) || 0,
              },
            };
          }),
      );
    }

    return this.deduplicatePoints(points);
  }

  /**
   * Deduplicate points occurring at the exact same location (same name/address/coordinates)
   * Aggregates a count and keeps the earliest sequence and non-empty metadata.
   */
  private deduplicatePoints(points: OrderPoint[]): OrderPoint[] {
    if (!points.length) return [];

    const keyOf = (p: OrderPoint) =>
      [
        (p.name || '').trim().toLowerCase(),
        (p.address || '').trim().toLowerCase(),
        p.coordinates?.latitude ?? 0,
        p.coordinates?.longitude ?? 0,
      ].join('|');

    const map = new Map<string, OrderPoint>();

    for (const p of points) {
      const key = keyOf(p);
      if (!map.has(key)) {
        map.set(key, { ...p, count: 1 });
        continue;
      }

      const existing = map.get(key)!;
      const sequence = Math.min(
        existing.sequence ?? Number.MAX_SAFE_INTEGER,
        p.sequence ?? Number.MAX_SAFE_INTEGER,
      );

      map.set(key, {
        name: existing.name || p.name,
        address: existing.address || p.address,
        coordinates: existing.coordinates || p.coordinates,
        type: existing.type || p.type,
        sequence: isFinite(sequence) ? sequence : undefined,
        count: (existing.count || 1) + 1,
        eta: existing.eta || p.eta,
        status: existing.status || p.status,
        plannedArrival: existing.plannedArrival || p.plannedArrival,
        plannedDeparture: existing.plannedDeparture || p.plannedDeparture,
        actualArrival: existing.actualArrival || p.actualArrival,
        actualDeparture: existing.actualDeparture || p.actualDeparture,
        confirmedBy: existing.confirmedBy || p.confirmedBy,
        contactPhone: existing.contactPhone || p.contactPhone,
        contactName: existing.contactName || p.contactName,
        remarks: existing.remarks || p.remarks,
        proofImageUrl: existing.proofImageUrl || p.proofImageUrl,
      });
    }

    // First pass: exact key (name+address+coords)
    const firstPass = Array.from(map.values());

    // Second pass: merge by normalized address + type to reduce near-duplicate stops
    const addrKeyOf = (p: OrderPoint) =>
      [(p.type || '').toString().trim().toLowerCase(), (p.address || '').trim().toLowerCase()].join(
        '|',
      );

    const addrMap = new Map<string, OrderPoint>();
    for (const p of firstPass) {
      const key = addrKeyOf(p);
      if (!addrMap.has(key)) {
        addrMap.set(key, { ...p });
        continue;
      }
      const existing = addrMap.get(key)!;
      const sequence = Math.min(
        existing.sequence ?? Number.MAX_SAFE_INTEGER,
        p.sequence ?? Number.MAX_SAFE_INTEGER,
      );

      // Prefer non-zero coordinates; otherwise keep existing
      const coords =
        existing.coordinates &&
        (existing.coordinates.latitude !== 0 || existing.coordinates.longitude !== 0)
          ? existing.coordinates
          : p.coordinates;

      addrMap.set(key, {
        name: existing.name || p.name,
        address: existing.address || p.address,
        coordinates: coords || existing.coordinates || p.coordinates,
        type: existing.type || p.type,
        sequence: isFinite(sequence) ? sequence : undefined,
        count: (existing.count || 1) + (p.count || 1),
        eta: existing.eta || p.eta,
        status: existing.status || p.status,
        plannedArrival: existing.plannedArrival || p.plannedArrival,
        plannedDeparture: existing.plannedDeparture || p.plannedDeparture,
        actualArrival: existing.actualArrival || p.actualArrival,
        actualDeparture: existing.actualDeparture || p.actualDeparture,
        confirmedBy: existing.confirmedBy || p.confirmedBy,
        contactPhone: existing.contactPhone || p.contactPhone,
        remarks: existing.remarks || p.remarks,
        proofImageUrl: existing.proofImageUrl || p.proofImageUrl,
      });
    }

    return Array.from(addrMap.values()).sort((a, b) => (a.sequence ?? 0) - (b.sequence ?? 0));
  }

  /**
   * Extract dispatch assignments from order data
   * @param data - Backend order data
   * @returns Array of DispatchAssignment
   */
  private extractDispatches(data: Record<string, unknown>): DispatchAssignment[] {
    const dispatchData = data['dispatch'] as Record<string, unknown> | undefined;
    if (!dispatchData) return [];
    return [
      {
        dispatchId: ((dispatchData['id'] as number)?.toString() || '') as string,
        tripNo: (dispatchData['tripNo'] as string) || '',
        route: (dispatchData['route'] as string) || '',
        driver: this.extractDriverInfo(data) as DriverInfo,
        vehicle: {
          vehicleNumber: (dispatchData['vehicleNumber'] as string) || '',
          model: dispatchData['vehicleModel'] as string | undefined,
          capacity: dispatchData['vehicleCapacity'] as number | undefined,
        },
        status:
          (dispatchData['status'] as 'IN_QUEUE' | 'ASSIGNED' | 'IN_TRANSIT' | 'COMPLETED') ||
          'ASSIGNED',
        createdAt: this.formatDate(dispatchData['startTime'] as number[] | string | undefined),
        completedAt:
          (dispatchData['status'] as string) === 'COMPLETED'
            ? this.formatDate(dispatchData['endTime'] as number[] | string | undefined)
            : undefined,
      },
    ];
  }

  /**
   * Extract driver info with dispatch details
   * @param data - Backend order data
   * @returns DriverInfo if available, undefined otherwise
   */
  private extractDriverInfo(data: Record<string, unknown>): DriverInfo | undefined {
    const dispatchData = data['dispatch'] as Record<string, unknown> | undefined;
    const driverData = dispatchData?.['driver'] as Record<string, unknown> | undefined;
    if (!driverData) return undefined;

    return {
      id: (driverData['id'] as number) || 0,
      name: (driverData['name'] as string) || '',
      phone: (driverData['phone'] as string) || '',
      photo: driverData['photo'] as string | undefined,
      rating: driverData['rating'] as number | undefined,
      vehicleNumber: driverData['vehicleNumber'] as string | undefined,
      dispatchId: ((dispatchData?.['id'] as number)?.toString() || '') as string | undefined,
      tripNo: (dispatchData?.['tripNo'] as string) || '',
      route: (dispatchData?.['route'] as string) || '',
      status:
        (dispatchData?.['status'] as 'IN_QUEUE' | 'ASSIGNED' | 'IN_TRANSIT' | 'COMPLETED') ||
        'ASSIGNED',
    } as DriverInfo;
  }

  /**
   * Map error status to user-friendly message
   */
  private getErrorMessage(error: any): string {
    switch (error.status) {
      case 404:
        return 'Shipment not found. Please check the booking reference.';
      case 400:
        return 'Invalid booking reference format.';
      case 401:
        return 'Session expired. Please login again.';
      case 403:
        return 'You do not have permission to track this shipment.';
      case 500:
        return 'Server error. Please try again later.';
      case 503:
        return 'Service temporarily unavailable. Please try again later.';
      default:
        return 'Failed to track shipment. Please try again.';
    }
  }
}
