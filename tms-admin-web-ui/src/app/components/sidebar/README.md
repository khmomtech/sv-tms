# Sidebar Menu Architecture

This sidebar is intentionally split into three parts to keep behavior stable while making the menu easy to maintain.

## Files

- `sidebar-menu.types.ts`: Shared menu interfaces and permission type aliases.
- `sidebar-menu.config.ts`: The full, typed menu definition (labels, routes, icons, permissions).
- `sidebar-menu.utils.ts`: Pure helper functions for visibility, filtering, and route containment.
- `sidebar.component.ts`: UI state and interaction logic (dropdown state, search input, keyboard behavior).

## Design rules

1. Keep `sidebar-menu.config.ts` as the source of truth for menu structure.
2. Keep permission logic in `sidebar-menu.utils.ts` only.
3. Keep template/CSS behavior unchanged unless a product/UI change is explicitly requested.
4. Prefer adding tests before changing menu semantics.

## Test coverage

- `sidebar.component.spec.ts`: Component behavior (permissions, filtering, dropdowns, route expansion).
- `sidebar-menu.utils.spec.ts`: Pure function behavior and edge cases.
- `sidebar-menu.config.spec.ts`: Config integrity/regression checks (critical routes, labels, IDs).
