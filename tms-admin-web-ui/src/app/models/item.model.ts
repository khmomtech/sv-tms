// src/app/models/item.model.ts

export interface Item {
  id?: number;
  itemCode?: string;
  itemName: string;
  itemNameKh?: string;
  itemType?: string; // e.g., 'BEVERAGE', 'EQUIPMENT'
  size?: string;
  weight?: string;
  unit?: string;
  quantity: number;
  pallets?: string;
  palletType?: string;
  status?: number; // 1 = active, 0 = inactive
  sortOrder?: number;
}
