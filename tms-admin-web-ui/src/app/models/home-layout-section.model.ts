/** Home Layout Section Model */
export interface HomeLayoutSection {
  id?: number;
  sectionKey: string;
  sectionName: string;
  sectionNameKh?: string;
  description?: string;
  descriptionKh?: string;
  displayOrder: number;
  visible: boolean;
  isMandatory: boolean;
  icon?: string;
  category?: string;
  configJson?: string;
  createdBy?: string;
  createdAt?: string;
  updatedBy?: string;
  updatedAt?: string;
}

/** Request model for creating/updating sections */
export interface HomeLayoutSectionRequest {
  sectionKey: string;
  sectionName: string;
  sectionNameKh?: string;
  description?: string;
  descriptionKh?: string;
  displayOrder: number;
  visible: boolean;
  isMandatory?: boolean;
  icon?: string;
  category?: string;
  configJson?: string;
}

/** Section categories for filtering */
export const SECTION_CATEGORIES = [
  { value: 'all', label: 'All Categories' },
  { value: 'system', label: 'System' },
  { value: 'status', label: 'Status' },
  { value: 'safety', label: 'Safety' },
  { value: 'content', label: 'Content' },
  { value: 'trips', label: 'Trips' },
  { value: 'navigation', label: 'Navigation' },
  { value: 'general', label: 'General' },
] as const;

/** Common Material icons for sections */
export const SECTION_ICONS = [
  'person',
  'warning',
  'access_time',
  'verified_user',
  'campaign',
  'local_shipping',
  'grid_view',
  'home',
  'notifications',
  'settings',
  'help',
  'info',
  'dashboard',
] as const;
