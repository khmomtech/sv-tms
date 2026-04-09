import { Injectable } from '@angular/core';

import type { Geofence, GeofenceCreateRequest, GeofenceType } from '../models/geofence.model';

@Injectable({
  providedIn: 'root',
})
export class GeofenceImportExportService {
  /**
   * Export geofences to CSV format
   */
  exportToCSV(geofences: Geofence[], filename = 'geofences.csv'): void {
    if (geofences.length === 0) {
      return;
    }

    // CSV headers
    const headers = [
      'ID',
      'Name',
      'Description',
      'Type',
      'Center Lat',
      'Center Lng',
      'Radius (m)',
      'Alert Type',
      'Speed Limit (km/h)',
      'Active',
      'Created At',
      'Tags',
    ];

    // Convert geofences to CSV rows
    const rows = geofences.map((g) => [
      g.id.toString(),
      this.escapeCSV(g.name),
      this.escapeCSV(g.description || ''),
      g.type,
      (g.centerLatitude || '').toString(),
      (g.centerLongitude || '').toString(),
      (g.radiusMeters || '').toString(),
      g.alertType,
      (g.speedLimitKmh || '').toString(),
      g.active ? 'Yes' : 'No',
      g.createdAt,
      this.escapeCSV(g.tags?.join(';') || ''),
    ]);

    // Combine headers and rows
    const csvContent = [
      headers.map((h) => this.escapeCSV(h)).join(','),
      ...rows.map((row) => row.join(',')),
    ].join('\n');

    // Download CSV file
    this.downloadFile(csvContent, filename, 'text/csv');
  }

  /**
   * Export geofences to GeoJSON format
   */
  exportToGeoJSON(geofences: Geofence[], filename = 'geofences.geojson'): void {
    const features = geofences.map((g) => {
      const feature: any = {
        type: 'Feature',
        properties: {
          id: g.id,
          name: g.name,
          description: g.description,
          type: g.type,
          alertType: g.alertType,
          speedLimitKmh: g.speedLimitKmh,
          active: g.active,
          createdAt: g.createdAt,
          tags: g.tags || [],
        },
      };

      if (g.type === 'CIRCLE' && g.centerLatitude && g.centerLongitude) {
        feature.geometry = {
          type: 'Point',
          coordinates: [g.centerLongitude, g.centerLatitude],
        };
        feature.properties.radiusMeters = g.radiusMeters;
      } else if (g.type === 'POLYGON' && g.geoJsonCoordinates) {
        try {
          const coords = JSON.parse(g.geoJsonCoordinates);
          feature.geometry = {
            type: 'Polygon',
            coordinates: [coords],
          };
        } catch {
          feature.geometry = null;
        }
      }

      return feature;
    });

    const geoJSON = {
      type: 'FeatureCollection',
      features,
    };

    const jsonContent = JSON.stringify(geoJSON, null, 2);
    this.downloadFile(jsonContent, filename, 'application/geo+json');
  }

  /**
   * Import geofences from CSV file
   */
  importFromCSV(file: File): Promise<GeofenceCreateRequest[]> {
    return new Promise((resolve, reject) => {
      const reader = new FileReader();

      reader.onload = (event) => {
        try {
          const csv = event.target?.result as string;
          const lines = csv.split('\n').filter((line) => line.trim());

          if (lines.length < 2) {
            reject(new Error('CSV file is empty or has no data'));
            return;
          }

          // Parse header
          const headers = lines[0].split(',').map((h) => h.trim());
          const requiredHeaders = ['Name', 'Type', 'Alert Type'];
          const missingHeaders = requiredHeaders.filter((h) => !headers.includes(h));

          if (missingHeaders.length > 0) {
            reject(new Error(`Missing required columns: ${missingHeaders.join(', ')}`));
            return;
          }

          // Parse data rows
          const geofences: GeofenceCreateRequest[] = [];
          for (let i = 1; i < lines.length; i++) {
            const row = this.parseCSVRow(lines[i]);
            const geofence = this.rowToGeofence(row, headers);

            if (geofence) {
              geofences.push(geofence);
            }
          }

          resolve(geofences);
        } catch (error) {
          reject(error);
        }
      };

      reader.onerror = () => {
        reject(new Error('Failed to read file'));
      };

      reader.readAsText(file);
    });
  }

  /**
   * Import geofences from GeoJSON file
   */
  importFromGeoJSON(file: File, companyId: number): Promise<GeofenceCreateRequest[]> {
    return new Promise((resolve, reject) => {
      const reader = new FileReader();

      reader.onload = (event) => {
        try {
          const json = JSON.parse(event.target?.result as string);
          const geofences: GeofenceCreateRequest[] = [];

          if (!json.features || !Array.isArray(json.features)) {
            reject(new Error('Invalid GeoJSON format'));
            return;
          }

          json.features.forEach((feature: any) => {
            const geofence = this.featureToGeofence(feature, companyId);
            if (geofence) {
              geofences.push(geofence);
            }
          });

          resolve(geofences);
        } catch (error) {
          reject(
            new Error(
              `Failed to parse GeoJSON: ${error instanceof Error ? error.message : 'Unknown error'}`,
            ),
          );
        }
      };

      reader.onerror = () => {
        reject(new Error('Failed to read file'));
      };

      reader.readAsText(file);
    });
  }

  private escapeCSV(value: string): string {
    if (value.includes(',') || value.includes('"') || value.includes('\n')) {
      return `"${value.replace(/"/g, '""')}"`;
    }
    return value;
  }

  private parseCSVRow(row: string): string[] {
    const result: string[] = [];
    let current = '';
    let insideQuotes = false;

    for (let i = 0; i < row.length; i++) {
      const char = row[i];
      const nextChar = row[i + 1];

      if (char === '"') {
        if (insideQuotes && nextChar === '"') {
          current += '"';
          i++; // Skip next quote
        } else {
          insideQuotes = !insideQuotes;
        }
      } else if (char === ',' && !insideQuotes) {
        result.push(current.trim());
        current = '';
      } else {
        current += char;
      }
    }

    result.push(current.trim());
    return result;
  }

  private rowToGeofence(row: string[], headers: string[]): GeofenceCreateRequest | null {
    const getValue = (header: string): string => row[headers.indexOf(header)] || '';

    const name = getValue('Name');
    if (!name) {
      return null;
    }

    const type = getValue('Type');
    if (!['CIRCLE', 'POLYGON'].includes(type)) {
      return null;
    }

    const alertType = getValue('Alert Type');
    if (!['ENTER', 'EXIT', 'BOTH', 'NONE'].includes(alertType)) {
      return null;
    }

    const geofence: GeofenceCreateRequest = {
      partnerCompanyId: 1,
      name,
      description: getValue('Description') || undefined,
      type: type as GeofenceType,
      alertType: alertType as any,
      active: getValue('Active')?.toLowerCase() === 'yes',
    };

    if (type === 'CIRCLE') {
      const centerLat = parseFloat(getValue('Center Lat'));
      const centerLng = parseFloat(getValue('Center Lng'));
      const radius = parseInt(getValue('Radius (m)'), 10);

      if (!isNaN(centerLat) && !isNaN(centerLng) && !isNaN(radius)) {
        geofence.centerLatitude = centerLat;
        geofence.centerLongitude = centerLng;
        geofence.radiusMeters = radius;
      }
    }

    const speedLimit = parseInt(getValue('Speed Limit (km/h)'), 10);
    if (!isNaN(speedLimit)) {
      geofence.speedLimitKmh = speedLimit;
    }

    return geofence;
  }

  private featureToGeofence(feature: any, companyId: number): GeofenceCreateRequest | null {
    const props = feature.properties || {};
    const geom = feature.geometry;

    if (!props.name) {
      return null;
    }

    if (!['CIRCLE', 'POLYGON'].includes(props.type)) {
      return null;
    }

    const geofence: GeofenceCreateRequest = {
      partnerCompanyId: companyId,
      name: props.name,
      description: props.description,
      type: props.type,
      alertType: props.alertType || 'NONE',
      speedLimitKmh: props.speedLimitKmh,
      active: props.active !== false,
    };

    if (props.type === 'CIRCLE' && geom?.type === 'Point') {
      const [lng, lat] = geom.coordinates;
      geofence.centerLatitude = lat;
      geofence.centerLongitude = lng;
      geofence.radiusMeters = props.radiusMeters || 1000;
    } else if (props.type === 'POLYGON' && geom?.type === 'Polygon') {
      const coordinates = geom.coordinates[0];
      geofence.geoJsonCoordinates = JSON.stringify(
        coordinates.map((coord: [number, number]) => [coord[1], coord[0]]),
      );
    }

    return geofence;
  }

  private downloadFile(content: string, filename: string, mimeType: string): void {
    const blob = new Blob([content], { type: mimeType });
    const url = URL.createObjectURL(blob);
    const link = document.createElement('a');

    link.href = url;
    link.download = filename;
    document.body.appendChild(link);
    link.click();
    document.body.removeChild(link);
    URL.revokeObjectURL(url);
  }
}
