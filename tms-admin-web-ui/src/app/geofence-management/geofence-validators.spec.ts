import { FormControl } from '@angular/forms';

import {
  geoJsonValidator,
  latitudeValidator,
  longitudeValidator,
  radiusValidator,
  speedLimitValidator,
} from './geofence-validators';

// Helper to run a validator against a plain value
const run = (validator: ReturnType<typeof latitudeValidator>, value: unknown) =>
  validator(new FormControl(value));

describe('Geofence Validators', () => {
  // ─── latitudeValidator ────────────────────────────────────────────────────

  describe('latitudeValidator', () => {
    const v = latitudeValidator();

    it('returns null for valid latitude 0', () => {
      expect(run(v, 0)).toBeNull();
    });

    it('returns null for boundary value 90', () => {
      expect(run(v, 90)).toBeNull();
    });

    it('returns null for boundary value -90', () => {
      expect(run(v, -90)).toBeNull();
    });

    it('returns null for empty string (optional field)', () => {
      expect(run(v, '')).toBeNull();
    });

    it('returns null for null (optional field)', () => {
      expect(run(v, null)).toBeNull();
    });

    it('returns latitudeRange error when > 90', () => {
      const errors = run(v, 91);
      expect(errors).not.toBeNull();
      expect(errors!['latitudeRange']).toBeDefined();
    });

    it('returns latitudeRange error when < -90', () => {
      const errors = run(v, -91);
      expect(errors!['latitudeRange']).toBeDefined();
    });

    it('returns invalidNumber error for non-numeric string', () => {
      const errors = run(v, 'abc');
      expect(errors!['invalidNumber']).toBeTrue();
    });
  });

  // ─── longitudeValidator ───────────────────────────────────────────────────

  describe('longitudeValidator', () => {
    const v = longitudeValidator();

    it('returns null for valid longitude 0', () => {
      expect(run(v, 0)).toBeNull();
    });

    it('returns null for boundary value 180', () => {
      expect(run(v, 180)).toBeNull();
    });

    it('returns null for boundary value -180', () => {
      expect(run(v, -180)).toBeNull();
    });

    it('returns null for null (optional)', () => {
      expect(run(v, null)).toBeNull();
    });

    it('returns longitudeRange error when > 180', () => {
      expect(run(v, 181)!['longitudeRange']).toBeDefined();
    });

    it('returns longitudeRange error when < -180', () => {
      expect(run(v, -181)!['longitudeRange']).toBeDefined();
    });

    it('returns invalidNumber for non-numeric input', () => {
      expect(run(v, 'xyz')!['invalidNumber']).toBeTrue();
    });
  });

  // ─── radiusValidator ──────────────────────────────────────────────────────

  describe('radiusValidator', () => {
    const v = radiusValidator();

    it('returns null for valid radius 500', () => {
      expect(run(v, 500)).toBeNull();
    });

    it('returns null for minimum boundary 50', () => {
      expect(run(v, 50)).toBeNull();
    });

    it('returns null for maximum boundary 50000', () => {
      expect(run(v, 50000)).toBeNull();
    });

    it('returns null for null (optional field)', () => {
      expect(run(v, null)).toBeNull();
    });

    it('returns radiusRange error when < 50', () => {
      expect(run(v, 49)!['radiusRange']).toBeDefined();
    });

    it('returns radiusRange error when > 50000', () => {
      expect(run(v, 50001)!['radiusRange']).toBeDefined();
    });

    it('returns invalidNumber for non-numeric input', () => {
      expect(run(v, 'big')!['invalidNumber']).toBeTrue();
    });
  });

  // ─── speedLimitValidator ──────────────────────────────────────────────────

  describe('speedLimitValidator', () => {
    const v = speedLimitValidator();

    it('returns null for valid speed 80', () => {
      expect(run(v, 80)).toBeNull();
    });

    it('returns null for boundary value 0', () => {
      expect(run(v, 0)).toBeNull();
    });

    it('returns null for boundary value 200', () => {
      expect(run(v, 200)).toBeNull();
    });

    it('returns null for null (optional field)', () => {
      expect(run(v, null)).toBeNull();
    });

    it('returns speedLimitRange error when < 0', () => {
      expect(run(v, -1)!['speedLimitRange']).toBeDefined();
    });

    it('returns speedLimitRange error when > 200', () => {
      expect(run(v, 201)!['speedLimitRange']).toBeDefined();
    });

    it('returns invalidNumber for non-numeric string', () => {
      expect(run(v, 'fast')!['invalidNumber']).toBeTrue();
    });
  });

  // ─── geoJsonValidator ─────────────────────────────────────────────────────

  describe('geoJsonValidator', () => {
    const v = geoJsonValidator();

    // Validator uses [lat, lng] order: first element = latitude (-90..90),
    // second = longitude (-180..180).
    const validPolygon = JSON.stringify([
      [11.5, 104.9],
      [11.5, 104.95],
      [11.55, 104.95],
    ]);

    it('returns null for valid polygon with 3+ points', () => {
      expect(run(v, validPolygon)).toBeNull();
    });

    it('returns null for empty string (optional field)', () => {
      expect(run(v, '')).toBeNull();
    });

    it('returns null for null (optional field)', () => {
      expect(run(v, null)).toBeNull();
    });

    it('returns invalidGeoJson when input is not an array', () => {
      const errors = run(v, JSON.stringify({ type: 'Point' }));
      expect(errors!['invalidGeoJson'].message).toContain('array');
    });

    it('returns invalidGeoJson when fewer than 3 points', () => {
      const twoPoints = JSON.stringify([
        [11.5, 104.9],
        [11.5, 104.95],
      ]);
      expect(run(v, twoPoints)!['invalidGeoJson'].message).toContain('3 points');
    });

    it('returns invalidGeoJson when a point is not a 2-element array', () => {
      // First point valid [lat, lng]; second point missing lng
      const bad = JSON.stringify([[11.5, 104.9], [11.5], [11.55, 104.95]]);
      expect(run(v, bad)!['invalidGeoJson'].message).toContain('[latitude, longitude]');
    });

    it('returns invalidGeoJson when coordinates are strings, not numbers', () => {
      const bad = JSON.stringify([
        ['11.5', '104.9'],
        [11.5, 104.95],
        [11.55, 104.95],
      ]);
      expect(run(v, bad)!['invalidGeoJson'].message).toContain('numbers');
    });

    it('returns invalidGeoJson when latitude out of range', () => {
      // lat = 91 > 90
      const bad = JSON.stringify([
        [91, 104.9],
        [11.5, 104.95],
        [11.55, 104.95],
      ]);
      expect(run(v, bad)!['invalidGeoJson'].message).toContain('latitude out of range');
    });

    it('returns invalidGeoJson when longitude out of range', () => {
      // lat = 11.5 (valid), lng = 181 > 180
      const bad = JSON.stringify([
        [11.5, 181],
        [11.5, 104.95],
        [11.55, 104.95],
      ]);
      expect(run(v, bad)!['invalidGeoJson'].message).toContain('longitude out of range');
    });

    it('returns invalidGeoJson for malformed JSON string', () => {
      expect(run(v, 'not-json')!['invalidGeoJson'].message).toContain('JSON');
    });
  });
});
