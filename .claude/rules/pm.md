---
description: Product Manager conventions — feature specs, API contracts, release notes
---

# Product Manager Conventions

## Feature Lifecycle

1. **Spec first** — use `/new-feature` to draft a feature spec before any code is written.
2. **API contract review** — use `/review-api-contract` when backend API changes affect the mobile or admin UI.
3. **Release notes** — use `/release-notes` to generate a changelog from recent commits.

## Naming Conventions

- Feature branches: `feature/{ticket-id}-short-description` (e.g. `feature/TMS-42-driver-suspension`)
- Ticket IDs follow the format `TMS-{number}`.
- PRs must reference the ticket: `[TMS-42] Add driver suspension workflow`.

## API Boundary Rule (PM perspective)

When requesting a new endpoint, specify which client will call it:
- Admin web → must be under `/api/admin/`
- Driver app → must be under `/api/driver/`
- Customer app → must be under `/api/customer/{customerId}/`

Never request a single endpoint shared across admin and mobile — create separate endpoints.

## Database Change Rule

Any feature that changes the data model requires a Flyway migration.
Never request a schema change "just for now" — all schema changes are permanent and versioned.
