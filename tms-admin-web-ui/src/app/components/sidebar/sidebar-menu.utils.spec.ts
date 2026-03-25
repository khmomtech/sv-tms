import type { SidebarMenuItem } from './sidebar-menu.types';
import { containsRoute, filterMenuTree, hasMenuPermission } from './sidebar-menu.utils';

describe('sidebar-menu.utils', () => {
  const baseTree: SidebarMenuItem[] = [
    {
      id: 'parent-a',
      label: 'Parent A',
      permission: 'a:read',
      children: [
        {
          id: 'child-a1',
          label: 'Alpha Child',
          route: '/alpha',
          permission: 'alpha:read',
        },
        {
          id: 'child-a2',
          label: 'Beta Child',
          route: '/beta',
          permission: 'beta:read',
        },
      ],
    },
    {
      id: 'parent-b',
      label: 'Parent B',
      route: '/parent-b',
      permission: ['b:read', 'b:manage'],
    },
  ];

  const grant = (permissions: string[]) => {
    const set = new Set(permissions);
    return (permission: string) => set.has(permission);
  };

  describe('hasMenuPermission', () => {
    it('returns true when item has no permission', () => {
      expect(hasMenuPermission({ label: 'No Permission' }, () => false)).toBeTrue();
    });

    it('checks single permission correctly', () => {
      expect(
        hasMenuPermission({ label: 'Single', permission: 'x:read' }, grant(['x:read'])),
      ).toBeTrue();
      expect(hasMenuPermission({ label: 'Single', permission: 'x:read' }, grant([]))).toBeFalse();
    });

    it('checks any-of permissions correctly', () => {
      const item: SidebarMenuItem = { label: 'AnyOf', permission: ['x:read', 'x:manage'] };
      expect(hasMenuPermission(item, grant(['x:manage']))).toBeTrue();
      expect(hasMenuPermission(item, grant([]))).toBeFalse();
    });
  });

  describe('filterMenuTree', () => {
    it('returns permission-pruned tree when query is blank', () => {
      const filtered = filterMenuTree(baseTree, '', grant(['a:read', 'alpha:read']));

      expect(filtered.length).toBe(1);
      expect(filtered[0].id).toBe('parent-a');
      expect(filtered[0].children?.length).toBe(1);
      expect(filtered[0].children?.[0].id).toBe('child-a1');
    });

    it('returns parent when child label matches query', () => {
      const filtered = filterMenuTree(baseTree, 'beta', grant(['a:read', 'beta:read']));

      expect(filtered.length).toBe(1);
      expect(filtered[0].id).toBe('parent-a');
      expect(filtered[0].children?.length).toBe(1);
      expect(filtered[0].children?.[0].id).toBe('child-a2');
    });

    it('returns matching top-level item when label matches query', () => {
      const filtered = filterMenuTree(baseTree, 'parent b', grant(['b:read']));

      expect(filtered.length).toBe(1);
      expect(filtered[0].id).toBe('parent-b');
    });

    it('matches query case-insensitively and with surrounding whitespace', () => {
      const filtered = filterMenuTree(baseTree, '  ALPHA CHILD  ', grant(['a:read', 'alpha:read']));

      expect(filtered.length).toBe(1);
      expect(filtered[0].id).toBe('parent-a');
      expect(filtered[0].children?.length).toBe(1);
      expect(filtered[0].children?.[0].id).toBe('child-a1');
    });

    it('does not mutate source tree', () => {
      const before = JSON.stringify(baseTree);
      filterMenuTree(baseTree, 'alpha', grant(['a:read', 'alpha:read']));
      expect(JSON.stringify(baseTree)).toBe(before);
    });

    it('returns cloned nodes instead of reusing original object references', () => {
      const filtered = filterMenuTree(baseTree, '', grant(['a:read', 'alpha:read']));

      expect(filtered[0]).not.toBe(baseTree[0]);
      expect(filtered[0].children?.[0]).not.toBe(baseTree[0].children?.[0]);
    });

    it('removes non-actionable parent when label matches but children are unauthorized', () => {
      const filtered = filterMenuTree(baseTree, 'parent a', grant(['a:read']));

      expect(filtered.length).toBe(0);
    });

    it('returns empty result when query matches child but parent permission is missing', () => {
      const filtered = filterMenuTree(baseTree, 'alpha child', grant(['alpha:read']));

      expect(filtered.length).toBe(0);
    });
  });

  describe('containsRoute', () => {
    it('returns true for nested matching route prefix', () => {
      expect(containsRoute(baseTree, '/alpha/details')).toBeTrue();
    });

    it('returns true for top-level matching route prefix', () => {
      expect(containsRoute(baseTree, '/parent-b/sub')).toBeTrue();
    });

    it('returns false when route not found', () => {
      expect(containsRoute(baseTree, '/missing')).toBeFalse();
    });
  });
});
