/** 📄 Paginated API Result - matches Spring Boot Page interface */
export interface PagedResponse<T> {
  content: T[]; // List of results
  page?: number; // Current page index (0-based) - optional for flexibility
  number?: number; // Page number (Spring Boot format)
  size: number; // Page size
  totalElements: number; // Total elements in DB
  totalPages: number; // Total number of pages
  last?: boolean; // Is this the last page?
  first?: boolean; // Is this the first page?
  empty?: boolean; // Is the page empty?
  numberOfElements?: number; // Number of elements in current page
}

/**
 * Legacy PageResponse alias for backward compatibility
 * @deprecated Use PagedResponse instead
 */
export interface PageResponse<T> extends PagedResponse<T> {}
