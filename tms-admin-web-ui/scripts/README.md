# Import Path Migration Guide

This directory contains scripts to help migrate the codebase to use path aliases instead of deep relative imports.

## Prerequisites

```bash
npm install --save-dev ts-morph
```

## Usage

### 1. Fix Import Paths

```bash
node scripts/fix-imports.js
```

This will automatically convert:
- `../../../models/driver.model` → `@models/driver.model`
- `../../../services/driver.service` → `@services/driver.service`
- `../../../environments/environment` → `@env/environment`
- `../../../core/something` → `@core/something`
- `../../../shared/something` → `@shared/something`

### 2. Fix Linting Issues

```bash
npm run lint -- --fix
```

### 3. Verify Build

```bash
npm run build
```

### 4. Run Tests

```bash
npm test
```

## Barrel Exports Created

The following barrel export files have been created:

- `src/app/models/index.ts` - All model exports
- `src/app/services/index.ts` - All service exports
- `src/app/guards/index.ts` - All guard exports
- `src/app/resolvers/index.ts` - All resolver exports
- `src/app/shared/index.ts` - Shared module exports
- `src/app/core/index.ts` - Core module exports

## Path Aliases Available

Configured in `tsconfig.json`:

- `@core/*` → `src/app/core/*`
- `@shared/*` → `src/app/shared/*`
- `@features/*` → `src/app/features/*`
- `@services/*` → `src/app/services/*`
- `@models/*` → `src/app/models/*`
- `@env/*` → `src/app/environments/*`

## Examples

### Before
```typescript
import { Driver } from '../../../models/driver.model';
import { Vehicle } from '../../../models/vehicle.model';
import { DriverService } from '../../../services/driver.service';
import { environment } from '../../../environments/environment';
```

### After
```typescript
import { Driver, Vehicle } from '@models';
import { DriverService } from '@services';
import { environment } from '@env/environment';
```

## Rollback

If you need to rollback changes:

```bash
git checkout -- src/
```

## Support

For issues or questions, refer to:
- TMS_FRONTEND_STRUCTURE_ANALYSIS.md
- PROJECT_STRUCTURE_REVIEW_AND_IMPROVEMENTS.md
