export interface SafetyCategory {
  id?: number;
  code?: string;
  nameKm?: string;
  sortOrder?: number;
  isActive?: boolean;
  createdAt?: string;
  updatedAt?: string;
}

export interface SafetyMasterItem {
  id?: number;
  categoryId?: number;
  categoryCode?: string;
  categoryNameKm?: string;
  itemKey?: string;
  itemLabelKm?: string;
  checkTime?: string;
  sortOrder?: number;
  isActive?: boolean;
  createdAt?: string;
  updatedAt?: string;
}

export interface ApiResponse<T> {
  success: boolean;
  message?: string;
  data: T;
}
