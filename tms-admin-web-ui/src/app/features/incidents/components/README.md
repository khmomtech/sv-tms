# Incidents Components Structure

## Directory Organization

```
components/
├── case-components/           # Case management components
│   ├── case-detail.component.*   # View case details
│   ├── case-form.component.*     # Create/edit cases
│   ├── case-list.component.*     # List all cases
│   └── index.ts                  # Barrel export
├── incident-components/       # Incident management components
│   ├── incident-detail.component.*  # View incident details
│   ├── incident-form.component.*    # Create/edit incidents
│   ├── incident-list.component.*    # List all incidents
│   └── index.ts                     # Barrel export
├── archive/                   # Backup files and scripts (not imported)
│   ├── *.backup                  # Component backups
│   ├── *.bak                     # Legacy backups
│   ├── *.sh                      # Build scripts
│   └── *.txt                     # Restore files
└── index.ts                   # Main barrel export

```

## Component Structure

Each component follows Angular best practices:
- `*.component.ts` - TypeScript component logic
- `*.component.html` - External template
- `*.component.css` - External styles
- `*.component.spec.ts` - Unit tests (where applicable)

## Usage

### Direct Import (Lazy Loading)
```typescript
// In routes
loadComponent: () => import('./components/case-components/case-list.component')
  .then(m => m.CaseListComponent)
```

### Barrel Import (Eager Loading)
```typescript
// From barrel exports
import { CaseListComponent } from './components/case-components';
import { IncidentListComponent } from './components/incident-components';
```

## Benefits of This Structure

1. **Clear Separation**: Case and incident components are logically separated
2. **Scalability**: Easy to add more components within each category
3. **Maintainability**: Related components grouped together
4. **Clean Workspace**: Backup files moved to archive folder
5. **Lazy Loading Ready**: Each component can be lazy-loaded individually
6. **Barrel Exports**: Simplified imports when needed

## Archive Folder

The `archive/` folder contains:
- Component backup files (`.backup`, `.bak`)
- Migration scripts (`.sh`)
- Restore files (`.txt`)

**Note**: Files in archive are not imported and can be safely deleted after verification.

## Migration Notes

### Path Changes
- Old: `./components/case-detail.component`
- New: `./components/case-components/case-detail.component`

### Updated Files
- `incidents.routes.ts` - All route imports updated
- Component organization complete
- Barrel exports created for clean imports

## Component Count

- **Case Components**: 3 (detail, form, list)
- **Incident Components**: 3 (detail, form, list)
- **Total Active Components**: 6
- **Archived Files**: 8 (backups and scripts)
