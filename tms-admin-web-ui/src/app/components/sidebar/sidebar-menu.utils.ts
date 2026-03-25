import type { SidebarMenuItem } from './sidebar-menu.types';

export function hasMenuPermission(
  item: SidebarMenuItem,
  hasPermissionFn: (permission: string) => boolean,
): boolean {
  if (!item.permission) {
    return true;
  }

  if (typeof item.permission === 'string') {
    return hasPermissionFn(item.permission);
  }

  return item.permission.some((permission) => hasPermissionFn(permission));
}

export function filterMenuTree(
  items: SidebarMenuItem[],
  query: string,
  hasPermissionFn: (permission: string) => boolean,
): SidebarMenuItem[] {
  const normalizedQuery = query.toLowerCase().trim();

  return items.reduce<SidebarMenuItem[]>((acc, item) => {
    if (!hasMenuPermission(item, hasPermissionFn)) {
      return acc;
    }

    const filteredChildren = item.children
      ? filterMenuTree(item.children, query, hasPermissionFn)
      : [];
    const hasMatchingChildren = filteredChildren.length > 0;
    const selfMatches =
      normalizedQuery.length === 0 || labelToSearchText(item.label).includes(normalizedQuery);
    const include =
      normalizedQuery.length > 0
        ? hasMatchingChildren || (selfMatches && !!item.route)
        : !!item.route || hasMatchingChildren;

    if (include) {
      acc.push({
        ...item,
        children: hasMatchingChildren ? filteredChildren : undefined,
      });
    }

    return acc;
  }, []);
}

function labelToSearchText(label: SidebarMenuItem['label']): string {
  if (typeof label === 'string') {
    return label.toLowerCase();
  }
  return `${label.en} ${label.kh}`.toLowerCase();
}

export function containsRoute(items: SidebarMenuItem[], currentUrl: string): boolean {
  return items.some((item) => {
    if (item.route && currentUrl.startsWith(item.route)) {
      return true;
    }

    if (item.children?.length) {
      return containsRoute(item.children, currentUrl);
    }

    return false;
  });
}
