export type MenuPermission = string | string[];
export type LocalizedLabel = { en: string; kh: string };

export interface SidebarMenuItem {
  label: string | LocalizedLabel;
  icon?: string;
  iconClass?: string;
  route?: string;
  children?: SidebarMenuItem[];
  // Single required permission or an array of acceptable permissions (any-of)
  permission?: MenuPermission;
  id?: string;
  // Optional metadata for grouping/filtering behavior.
  group?: string;
  isAdvanced?: boolean;
  tags?: string[];
}
