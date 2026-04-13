---
name: new-feature
description: PM — draft a feature spec with API contract, DB impact, and acceptance criteria
---

Draft a complete feature specification for: $ARGUMENTS

Output the following sections:

## Feature: {name}

**Ticket:** TMS-{number} (assign a placeholder if unknown)
**Requested by:** PM
**Target sprint:** current

### Overview
One-paragraph description of what the feature does and why it is needed.

### User Stories
- As a [admin / driver / customer], I want to [action] so that [outcome].
(Write 2-4 user stories)

### API Contract
For each new or changed endpoint:
- Method + path (must follow API boundary rules: admin→`/api/admin/`, driver→`/api/driver/`, customer→`/api/customer/{id}/`)
- Request body (JSON fields + types)
- Response body (JSON fields + types)
- HTTP status codes and error cases

### Database Impact
- New tables or columns required (reference Flyway migration naming: `V{YYYYMMDD}__{description}.sql`)
- Existing tables modified
- "None" if no schema change

### Affected Services
List which services from: tms-core-api, tms-auth-api, tms-driver-app-api, tms-telematics-api, tms-safety-api, tms-message-api, api-gateway, tms-admin-web-ui, tms_driver_app, tms_customer_app

### Acceptance Criteria
- [ ] (Specific, testable conditions — write at least 5)

### Out of Scope
What this feature explicitly does NOT include.
