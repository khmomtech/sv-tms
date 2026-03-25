package com.svtrucking.logistics.enums;

/**
 * Indicates the origin/source of a TransportOrder. Helps support order-first flows and
 * idempotent imports (e.g., orders created from admin UI, booking conversion, external imports).
 */
public enum OrderOrigin {
  BOOKING,
  MANUAL_ORDER,
  IMPORT,
  API
}
