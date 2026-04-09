export interface LoadingPalletItem {
  id?: number;
  itemDescription: string;
  palletTag?: string | null;
  quantity: number;
  unit?: string | null;
  conditionNote?: string | null;
  verifiedOk: boolean;
}
