export interface ApiResponse<T> {
  success: boolean;
  message?: string;
  data: T;
  timestamp?: string;
  code?: string;
  errors?: any;
  requestId?: string;
  totalPages?: number;
}
