export interface DispatchItem {
  id?: number;
  itemName: string;
  quantity: number;
  unitOfMeasurement: string;
  palletType?: string;
  dimensions?: string;
  weight?: number;
  orderItemId: number;
}
