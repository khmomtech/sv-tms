/**
 * Transport Order Status Enumeration
 * Defines all possible states for a transport order
 */
export enum OrderStatus {
  // Initial states
  PENDING = 'PENDING',
  ASSIGNED = 'ASSIGNED',
  DRIVER_CONFIRMED = 'DRIVER_CONFIRMED',

  // Approval states
  APPROVED = 'APPROVED',
  REJECTED = 'REJECTED',

  // Execution states
  SCHEDULED = 'SCHEDULED',
  ARRIVED_LOADING = 'ARRIVED_LOADING',
  LOADING = 'LOADING',
  LOADED = 'LOADED',
  IN_TRANSIT = 'IN_TRANSIT',
  ARRIVED_UNLOADING = 'ARRIVED_UNLOADING',
  UNLOADING = 'UNLOADING',
  UNLOADED = 'UNLOADED',

  // Final states
  DELIVERED = 'DELIVERED',
  COMPLETED = 'COMPLETED',
  CANCELLED = 'CANCELLED',
}

/**
 * Status badge class mapping for UI styling
 */
export const STATUS_BADGE_MAPPING: Record<OrderStatus, string> = {
  [OrderStatus.PENDING]: 'badge-pending',
  [OrderStatus.ASSIGNED]: 'badge-confirmed',
  [OrderStatus.DRIVER_CONFIRMED]: 'badge-confirmed',
  [OrderStatus.APPROVED]: 'badge-confirmed',
  [OrderStatus.REJECTED]: 'badge-rejected',
  [OrderStatus.SCHEDULED]: 'badge-scheduled',
  [OrderStatus.ARRIVED_LOADING]: 'badge-dispatched',
  [OrderStatus.LOADING]: 'badge-loading',
  [OrderStatus.LOADED]: 'badge-loading',
  [OrderStatus.IN_TRANSIT]: 'badge-dispatched',
  [OrderStatus.ARRIVED_UNLOADING]: 'badge-dispatched',
  [OrderStatus.UNLOADING]: 'badge-loading',
  [OrderStatus.UNLOADED]: 'badge-loading',
  [OrderStatus.DELIVERED]: 'badge-completed',
  [OrderStatus.COMPLETED]: 'badge-completed',
  [OrderStatus.CANCELLED]: 'badge-rejected',
};

/**
 * Status category helpers for filtering
 */
export const OrderStatusCategories = {
  pending: [OrderStatus.PENDING, OrderStatus.ASSIGNED, OrderStatus.DRIVER_CONFIRMED],
  approval: [OrderStatus.APPROVED, OrderStatus.REJECTED],
  inProgress: [
    OrderStatus.SCHEDULED,
    OrderStatus.ARRIVED_LOADING,
    OrderStatus.LOADING,
    OrderStatus.LOADED,
    OrderStatus.IN_TRANSIT,
    OrderStatus.ARRIVED_UNLOADING,
    OrderStatus.UNLOADING,
    OrderStatus.UNLOADED,
  ],
  completed: [OrderStatus.DELIVERED, OrderStatus.COMPLETED],
  cancelled: [OrderStatus.CANCELLED],
};
