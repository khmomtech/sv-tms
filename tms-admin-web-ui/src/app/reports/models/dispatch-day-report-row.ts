export interface DispatchDayReportRow {
  dispatchId: number;
  planDate: string; // ISO date (yyyy-MM-dd)
  truckNo: string | null;
  truckTrip: any | null;
  depot: string | null;
  numberOfPallets: number | null;
  truckType: string | null;
  factoryDeparture: string | null; // ISO instant
  depotArrival: string | null; // ISO instant
  plannedDepotArrival: string | null; // ISO instant
  unloadingComplete: string | null; // ISO instant
  finalDestinationText: string | null;
}
