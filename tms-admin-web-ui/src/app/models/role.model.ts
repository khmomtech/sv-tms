import type { Permission } from './permission.model';

export interface Role {
  id: number;
  name: string;
  description: string;
  permissions: string;
  rolePermissions?: Permission[];
}
