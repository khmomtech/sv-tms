import { Injectable } from '@angular/core';
import { BehaviorSubject, Subject } from 'rxjs';

export interface MeasurementData {
  distance?: number; // meters
  area?: number; // square meters
  perimeter?: number; // meters
}

export interface DrawnShape {
  type: 'circle' | 'polygon' | 'rectangle';
  circle?: google.maps.Circle;
  polygon?: google.maps.Polygon;
  rectangle?: google.maps.Rectangle;
  data: {
    centerLat?: number;
    centerLng?: number;
    radiusMeters?: number;
    coordinates?: [number, number][];
    bounds?: google.maps.LatLngBounds;
  };
  measurements?: MeasurementData;
}

/**
 * Service to manage Google Maps Drawing Manager
 * Provides visual drawing tools for creating geofences interactively
 */
@Injectable({
  providedIn: 'root',
})
export class DrawingService {
  private drawingManager: google.maps.drawing.DrawingManager | null = null;
  private currentShapes: google.maps.MVCObject[] = [];
  private rectangleOptions: google.maps.RectangleOptions = {
    fillColor: '#f59e0b',
    fillOpacity: 0.3,
    strokeWeight: 2,
    strokeColor: '#f59e0b',
    clickable: true,
    editable: true,
    zIndex: 1,
  };
  private editingShape: google.maps.MVCObject | null = null;
  private measurementUpdateInterval: any;

  /** Observable for shape completion events */
  public shapeComplete$ = new Subject<DrawnShape>();

  /** Observable for real-time measurements during drawing */
  public measurement$ = new BehaviorSubject<MeasurementData | null>(null);

  /**
   * Initialize the drawing manager on the map
   */
  initializeDrawingManager(map: google.maps.Map): void {
    // Check if drawing library is loaded
    if (typeof google === 'undefined' || !google.maps || !google.maps.drawing) {
      console.error(
        'Google Maps Drawing library not loaded. Please ensure it is included in the script tag.',
      );
      return;
    }

    if (this.drawingManager) {
      this.drawingManager.setMap(null);
    }

    this.drawingManager = new google.maps.drawing.DrawingManager({
      drawingMode: null,
      drawingControl: true,
      drawingControlOptions: {
        position: google.maps.ControlPosition.TOP_CENTER,
        drawingModes: [
          google.maps.drawing.OverlayType.CIRCLE,
          google.maps.drawing.OverlayType.POLYGON,
          google.maps.drawing.OverlayType.RECTANGLE,
        ],
      },
      circleOptions: {
        fillColor: '#2563eb',
        fillOpacity: 0.3,
        strokeWeight: 2,
        strokeColor: '#2563eb',
        clickable: true,
        editable: true,
        zIndex: 1,
      },
      polygonOptions: {
        fillColor: '#059669',
        fillOpacity: 0.3,
        strokeWeight: 2,
        strokeColor: '#059669',
        clickable: true,
        editable: true,
        zIndex: 1,
      },
      rectangleOptions: this.rectangleOptions,
    });

    this.drawingManager.setMap(map);

    // Listen for shape completion
    google.maps.event.addListener(
      this.drawingManager,
      'circlecomplete',
      (circle: google.maps.Circle) => {
        this.handleCircleComplete(circle);
      },
    );

    google.maps.event.addListener(
      this.drawingManager,
      'polygoncomplete',
      (polygon: google.maps.Polygon) => {
        this.handlePolygonComplete(polygon);
      },
    );

    google.maps.event.addListener(
      this.drawingManager,
      'rectanglecomplete',
      (rectangle: google.maps.Rectangle) => {
        this.handleRectangleComplete(rectangle);
      },
    );
  }

  /**
   * Enable drawing mode
   */
  enableDrawing(mode: 'circle' | 'polygon' | 'rectangle'): void {
    if (!this.drawingManager) return;

    const drawingMode =
      mode === 'circle'
        ? google.maps.drawing.OverlayType.CIRCLE
        : mode === 'polygon'
          ? google.maps.drawing.OverlayType.POLYGON
          : google.maps.drawing.OverlayType.RECTANGLE;

    this.drawingManager.setDrawingMode(drawingMode);
  }

  /**
   * Disable drawing mode
   */
  disableDrawing(): void {
    if (!this.drawingManager) return;
    this.drawingManager.setDrawingMode(null);
  }

  /**
   * Clear all drawn shapes
   */
  clearShapes(): void {
    this.currentShapes.forEach((shape) => {
      if (shape instanceof google.maps.Circle || shape instanceof google.maps.Polygon) {
        shape.setMap(null);
      }
    });
    this.currentShapes = [];
  }

  /**
   * Remove a specific shape
   */
  removeShape(shape: google.maps.MVCObject): void {
    if (shape instanceof google.maps.Circle || shape instanceof google.maps.Polygon) {
      shape.setMap(null);
    }
    this.currentShapes = this.currentShapes.filter((s) => s !== shape);
  }

  /**
   * Destroy the drawing manager
   */
  destroy(): void {
    if (this.drawingManager) {
      this.drawingManager.setMap(null);
      this.drawingManager = null;
    }
    this.clearShapes();
  }

  private handleCircleComplete(circle: google.maps.Circle): void {
    this.currentShapes.push(circle);

    const center = circle.getCenter();
    const radius = circle.getRadius();

    if (center) {
      const drawnShape: DrawnShape = {
        type: 'circle',
        circle,
        data: {
          centerLat: center.lat(),
          centerLng: center.lng(),
          radiusMeters: Math.round(radius),
        },
        measurements: {
          distance: Math.round(radius),
          area: Math.round(Math.PI * radius * radius),
        },
      };

      this.shapeComplete$.next(drawnShape);
    }

    // Disable drawing mode after completion
    this.disableDrawing();
  }

  private handlePolygonComplete(polygon: google.maps.Polygon): void {
    this.currentShapes.push(polygon);

    const path = polygon.getPath();
    const coordinates: [number, number][] = [];

    for (let i = 0; i < path.getLength(); i++) {
      const point = path.getAt(i);
      coordinates.push([point.lat(), point.lng()]);
    }

    // Close the polygon by adding the first point at the end
    if (coordinates.length > 0) {
      coordinates.push(coordinates[0]);
    }

    const measurements = this.calculatePolygonMeasurements(path);

    const drawnShape: DrawnShape = {
      type: 'polygon',
      polygon,
      data: {
        coordinates,
      },
      measurements,
    };

    this.shapeComplete$.next(drawnShape);

    // Disable drawing mode after completion
    this.disableDrawing();
  }

  private handleRectangleComplete(rectangle: google.maps.Rectangle): void {
    this.currentShapes.push(rectangle);

    const bounds = rectangle.getBounds();
    if (!bounds) return;

    const ne = bounds.getNorthEast();
    const sw = bounds.getSouthWest();

    const coordinates: [number, number][] = [
      [sw.lat(), sw.lng()],
      [ne.lat(), sw.lng()],
      [ne.lat(), ne.lng()],
      [sw.lat(), ne.lng()],
      [sw.lat(), sw.lng()],
    ];

    const measurements = {
      area: Math.round(this.calculateRectangleArea(bounds)),
      perimeter: Math.round(
        2 *
          (this.getDistance(sw.lat(), sw.lng(), ne.lat(), sw.lng()) +
            this.getDistance(sw.lat(), sw.lng(), sw.lat(), ne.lng())),
      ),
    };

    const drawnShape: DrawnShape = {
      type: 'rectangle',
      rectangle,
      data: {
        coordinates,
        bounds,
      },
      measurements,
    };

    this.shapeComplete$.next(drawnShape);

    // Disable drawing mode after completion
    this.disableDrawing();
  }

  /**
   * Start editing an existing geofence
   */
  startEditingShape(shape: google.maps.Circle | google.maps.Polygon | google.maps.Rectangle): void {
    this.editingShape = shape;
    (shape as any).setEditable(true);

    // Set up measurement updates
    const listener = google.maps.event.addListener(shape, 'bounds_changed', () => {
      this.updateMeasurements();
    });

    const listener2 = google.maps.event.addListener(shape, 'center_changed', () => {
      this.updateMeasurements();
    });

    // Store listeners for cleanup
    (shape as any)._measureListeners = [listener, listener2];
  }

  /**
   * Stop editing a shape
   */
  stopEditingShape(): void {
    if (this.editingShape) {
      (this.editingShape as any).setEditable(false);
      const listeners = (this.editingShape as any)._measureListeners;
      if (listeners) {
        listeners.forEach((l: any) => google.maps.event.removeListener(l));
      }
    }
    this.editingShape = null;
    this.measurement$.next(null);
  }

  /**
   * Update measurements for current shape
   */
  private updateMeasurements(): void {
    if (!this.editingShape) return;

    if (this.editingShape instanceof google.maps.Circle) {
      const circle = this.editingShape;
      const radius = circle.getRadius();
      this.measurement$.next({
        distance: Math.round(radius),
        area: Math.round(Math.PI * radius * radius),
      });
    } else if (this.editingShape instanceof google.maps.Polygon) {
      const polygon = this.editingShape;
      const measurements = this.calculatePolygonMeasurements(polygon.getPath());
      this.measurement$.next(measurements);
    } else if (this.editingShape instanceof google.maps.Rectangle) {
      const rectangle = this.editingShape;
      const bounds = rectangle.getBounds();
      if (bounds) {
        const measurements = {
          area: Math.round(this.calculateRectangleArea(bounds)),
          perimeter: Math.round(this.calculateRectanglePerimeter(bounds)),
        };
        this.measurement$.next(measurements);
      }
    }
  }

  /**
   * Calculate measurements for a polygon path
   */
  private calculatePolygonMeasurements(
    path: google.maps.MVCArray<google.maps.LatLng>,
  ): MeasurementData {
    const coordinates: [number, number][] = [];
    for (let i = 0; i < path.getLength(); i++) {
      const point = path.getAt(i);
      coordinates.push([point.lat(), point.lng()]);
    }

    let perimeter = 0;
    for (let i = 0; i < coordinates.length - 1; i++) {
      perimeter += this.getDistance(
        coordinates[i][0],
        coordinates[i][1],
        coordinates[i + 1][0],
        coordinates[i + 1][1],
      );
    }

    // Use Shoelace formula for polygon area
    let area = 0;
    for (let i = 0; i < coordinates.length - 1; i++) {
      area +=
        (coordinates[i][1] + coordinates[i + 1][1]) * (coordinates[i + 1][0] - coordinates[i][0]);
    }
    area = Math.abs(area / 2) * 1111950000; // Rough conversion for degrees to m²

    return {
      area: Math.round(area),
      perimeter: Math.round(perimeter),
    };
  }

  /**
   * Calculate rectangle area (in square meters)
   */
  private calculateRectangleArea(bounds: google.maps.LatLngBounds): number {
    const ne = bounds.getNorthEast();
    const sw = bounds.getSouthWest();

    const latDiff = Math.abs(ne.lat() - sw.lat());
    const lngDiff = Math.abs(ne.lng() - sw.lng());

    // Rough approximation: 1 degree lat ≈ 111 km, 1 degree lng varies by latitude
    const latMeters = latDiff * 111000;
    const lngMeters = lngDiff * 111000 * Math.cos((ne.lat() * Math.PI) / 180);

    return latMeters * lngMeters;
  }

  /**
   * Calculate rectangle perimeter
   */
  private calculateRectanglePerimeter(bounds: google.maps.LatLngBounds): number {
    const ne = bounds.getNorthEast();
    const sw = bounds.getSouthWest();

    const latDist = this.getDistance(sw.lat(), sw.lng(), ne.lat(), sw.lng());
    const lngDist = this.getDistance(sw.lat(), sw.lng(), sw.lat(), ne.lng());

    return 2 * (latDist + lngDist);
  }

  /**
   * Calculate distance between two coordinates (Haversine formula)
   */
  private getDistance(lat1: number, lng1: number, lat2: number, lng2: number): number {
    const R = 6371000; // Earth's radius in meters
    const dLat = ((lat2 - lat1) * Math.PI) / 180;
    const dLng = ((lng2 - lng1) * Math.PI) / 180;

    const a =
      Math.sin(dLat / 2) * Math.sin(dLat / 2) +
      Math.cos((lat1 * Math.PI) / 180) *
        Math.cos((lat2 * Math.PI) / 180) *
        Math.sin(dLng / 2) *
        Math.sin(dLng / 2);

    const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
    return R * c;
  }
}
