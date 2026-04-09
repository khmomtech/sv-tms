export interface MaintenanceTask {
  id?: number;
  title: string;
  description?: string;
  dueDate: string; // ISO date string
  status: string;
  taskTypeId: number;
  vehicleId: number;
  completedAt?: string;
  createdDate?: string;
  updatedDate?: string;
}
