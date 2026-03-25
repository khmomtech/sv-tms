export interface PageResult<T> {
  content: T[];
  totalPages: number;
  totalElements: number;
  number: number; // current page
  size: number;
  first: boolean;
  last: boolean;
  empty: boolean;
  numberOfElements: number;
}
