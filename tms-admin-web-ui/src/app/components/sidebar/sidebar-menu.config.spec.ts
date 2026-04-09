import type { SidebarMenuItem } from './sidebar-menu.types';
import { SIDEBAR_MENU_CONFIG } from './sidebar-menu.config';

function flattenMenu(items: SidebarMenuItem[]): SidebarMenuItem[] {
  return items.flatMap((item) => [item, ...(item.children ? flattenMenu(item.children) : [])]);
}

function labelToText(label: SidebarMenuItem['label']): string {
  return typeof label === 'string' ? label : `${label.en} ${label.kh}`;
}

describe('sidebar-menu.config', () => {
  it('should contain expected top-level sections', () => {
    const topLevelIds = new Set(
      SIDEBAR_MENU_CONFIG.map((item) => item.id).filter((id): id is string => !!id),
    );

    expect(topLevelIds.has('overview')).toBeTrue();
    expect(topLevelIds.has('orders-bookings')).toBeTrue();
    expect(topLevelIds.has('dispatch-safety')).toBeTrue();
    expect(topLevelIds.has('fleet-drivers')).toBeTrue();
    expect(topLevelIds.has('partners-operations')).toBeTrue();
    expect(topLevelIds.has('admin-settings')).toBeTrue();
  });

  it('should have unique IDs across all menu nodes', () => {
    const allItems = flattenMenu(SIDEBAR_MENU_CONFIG);
    const ids = allItems.map((item) => item.id).filter((id): id is string => !!id);

    const unique = new Set(ids);
    expect(unique.size).toBe(ids.length);
  });

  it('should preserve critical routes used by existing navigation', () => {
    const allRoutes = new Set(
      flattenMenu(SIDEBAR_MENU_CONFIG)
        .map((item) => item.route)
        .filter((route): route is string => !!route),
    );

    expect(allRoutes.has('/dashboard')).toBeTrue();
    expect(allRoutes.has('/dispatches')).toBeTrue();
    expect(allRoutes.has('/fleet/drivers')).toBeTrue();
    expect(allRoutes.has('/admin/roles')).toBeTrue();
    expect(allRoutes.has('/settings/audit')).toBeTrue();
    expect(allRoutes.has('/admin/pre-entry-master/categories')).toBeTrue();
    expect(allRoutes.has('/admin/pre-entry-master/items')).toBeTrue();
  });

  it('should keep each node structurally valid', () => {
    const allItems = flattenMenu(SIDEBAR_MENU_CONFIG);

    allItems.forEach((item) => {
      expect(item.label).toBeTruthy();
      expect(item.route || item.children?.length).toBeTruthy();
    });
  });

  it('should preserve Khmer safety section labels', () => {
    const labels = new Set(flattenMenu(SIDEBAR_MENU_CONFIG).map((item) => labelToText(item.label)));

    expect(labels.has('ប្រភេទសុវត្ថិភាព')).toBeTrue();
    expect(labels.has('ប្រភេទសុវត្ថិភាព')).toBeTrue();
    expect(labels.has('ធាតុត្រួតពិនិត្យសុវត្ថិភាព')).toBeTrue();
  });

  it('should preserve key admin permission strings', () => {
    const admin = SIDEBAR_MENU_CONFIG.find((item) => item.id === 'admin-settings');
    expect(admin).toBeDefined();

    const permissionMgmt = admin?.children?.find(
      (item) => labelToText(item.label) === 'Permissions',
    );
    const bannerMgmt = admin?.children?.find(
      (item) => labelToText(item.label) === 'Banner Management',
    );

    expect(permissionMgmt?.permission).toBe('admin:permission:read');
    expect(bannerMgmt?.permission).toBe('banner:read');
  });

  it('should include pre-entry master links under master data group', () => {
    const masterData = SIDEBAR_MENU_CONFIG.find((item) => item.id === 'master-data');
    expect(masterData).toBeDefined();

    const preEntryCategory = masterData?.children?.find(
      (item) => labelToText(item.label) === 'Pre-entry Category',
    );
    const preEntryItem = masterData?.children?.find(
      (item) => labelToText(item.label) === 'Pre-entry Item',
    );

    expect(preEntryCategory?.route).toBe('/admin/pre-entry-master/categories');
    expect(preEntryItem?.route).toBe('/admin/pre-entry-master/items');
  });

  it('should keep menu routes within known app route roots', () => {
    const knownRoots = new Set([
      'dashboard',
      'tracking',
      'orders',
      'bookings',
      'dispatch',
      'dispatches',
      'fleet',
      'live',
      'safety',
      'compliance',
      'training',
      'customers',
      'vendors',
      'subcontractors',
      'admin',
      'reports',
      'drivers',
      'settings',
      'items',
      'banners',
      'issues',
      'incidents',
      'cases',
      'tasks',
      'shipments',
      'geofences',
    ]);

    const allRoutes = flattenMenu(SIDEBAR_MENU_CONFIG)
      .map((item) => item.route)
      .filter((route): route is string => !!route);

    allRoutes.forEach((route) => {
      expect(route.startsWith('/')).withContext(`Route must be absolute: ${route}`).toBeTrue();
      const root = route.replace(/^\//, '').split('/')[0];
      expect(knownRoots.has(root))
        .withContext(`Unknown route root "${root}" for menu route "${route}"`)
        .toBeTrue();
    });
  });

  it('should keep legacy entries explicitly marked as advanced', () => {
    const legacyItems = flattenMenu(SIDEBAR_MENU_CONFIG).filter((item) =>
      labelToText(item.label).toLowerCase().includes('legacy'),
    );

    legacyItems.forEach((item) => {
      expect(item.isAdvanced).withContext(`Legacy item must be advanced: ${item.label}`).toBeTrue();
    });
  });
});
