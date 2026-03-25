import type { AbstractControl, ValidationErrors, ValidatorFn } from '@angular/forms';

/**
 * Custom validators for geofence forms
 */

/**
 * Validator for latitude (-90 to 90)
 */
export function latitudeValidator(): ValidatorFn {
  return (control: AbstractControl): ValidationErrors | null => {
    if (control.value === null || control.value === undefined || control.value === '') {
      return null;
    }

    const value = Number(control.value);
    if (isNaN(value)) {
      return { invalidNumber: true };
    }

    if (value < -90 || value > 90) {
      return { latitudeRange: { min: -90, max: 90, actual: value } };
    }

    return null;
  };
}

/**
 * Validator for longitude (-180 to 180)
 */
export function longitudeValidator(): ValidatorFn {
  return (control: AbstractControl): ValidationErrors | null => {
    if (control.value === null || control.value === undefined || control.value === '') {
      return null;
    }

    const value = Number(control.value);
    if (isNaN(value)) {
      return { invalidNumber: true };
    }

    if (value < -180 || value > 180) {
      return { longitudeRange: { min: -180, max: 180, actual: value } };
    }

    return null;
  };
}

/**
 * Validator for radius (50m to 50km)
 */
export function radiusValidator(): ValidatorFn {
  return (control: AbstractControl): ValidationErrors | null => {
    if (control.value === null || control.value === undefined || control.value === '') {
      return null;
    }

    const value = Number(control.value);
    if (isNaN(value)) {
      return { invalidNumber: true };
    }

    const minRadius = 50;
    const maxRadius = 50000;

    if (value < minRadius || value > maxRadius) {
      return { radiusRange: { min: minRadius, max: maxRadius, actual: value } };
    }

    return null;
  };
}

/**
 * Validator for GeoJSON coordinates
 * Expects array of [lat, lng] tuples with minimum 3 points
 */
export function geoJsonValidator(): ValidatorFn {
  return (control: AbstractControl): ValidationErrors | null => {
    if (!control.value || control.value === '') {
      return null;
    }

    try {
      const parsed = JSON.parse(control.value);

      if (!Array.isArray(parsed)) {
        return { invalidGeoJson: { message: 'Must be an array of coordinates' } };
      }

      if (parsed.length < 3) {
        return { invalidGeoJson: { message: 'Polygon must have at least 3 points' } };
      }

      // Validate each coordinate
      for (let i = 0; i < parsed.length; i++) {
        const coord = parsed[i];

        if (!Array.isArray(coord) || coord.length !== 2) {
          return {
            invalidGeoJson: { message: `Point ${i + 1} must be [latitude, longitude]` },
          };
        }

        const [lat, lng] = coord;

        if (typeof lat !== 'number' || typeof lng !== 'number') {
          return { invalidGeoJson: { message: `Point ${i + 1} coordinates must be numbers` } };
        }

        if (lat < -90 || lat > 90) {
          return { invalidGeoJson: { message: `Point ${i + 1} latitude out of range` } };
        }

        if (lng < -180 || lng > 180) {
          return { invalidGeoJson: { message: `Point ${i + 1} longitude out of range` } };
        }
      }

      return null;
    } catch (error) {
      return { invalidGeoJson: { message: 'Invalid JSON format' } };
    }
  };
}

/**
 * Validator for speed limit (0 to 200 km/h)
 */
export function speedLimitValidator(): ValidatorFn {
  return (control: AbstractControl): ValidationErrors | null => {
    if (control.value === null || control.value === undefined || control.value === '') {
      return null;
    }

    const value = Number(control.value);
    if (isNaN(value)) {
      return { invalidNumber: true };
    }

    if (value < 0 || value > 200) {
      return { speedLimitRange: { min: 0, max: 200, actual: value } };
    }

    return null;
  };
}
