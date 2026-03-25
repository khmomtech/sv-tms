# Dispatch Workflow Rollout Checklist

Use this checklist for staging, pilot, and production rollout after the workflow-alignment changes.

## 1. Pre-Stage Preparation

- [ ] Confirm the target environment uses split routing (`tms-auth-api` + `tms-driver-app-api`).
- [ ] Identify one `GENERAL` dispatch id for validation: `________________`
- [ ] Identify one `KHBL` dispatch id for validation: `________________`
- [ ] Identify one fallback dispatch id linked to an invalid/inactive template: `________________`
- [ ] Record the fallback linked template code: `________________`
- [ ] Confirm admin credentials or token are available.
- [ ] Confirm driver credentials or token are available.

## 2. Stage Migration

- [ ] Apply the workflow-alignment migration in staging.
- [ ] Confirm application health after migration:

```bash
curl -fsS http://127.0.0.1:8083/actuator/health
curl -fsS http://127.0.0.1:8084/actuator/health
```

## 3. DB Inspection

- [ ] Run the workflow DB inspection helper:

```bash
mysql -u USER -p DB_NAME < deploy/inspect_dispatch_workflow_templates.sql
```

- [ ] Confirm blank or null `loading_type_code` dispatches resolve to `GENERAL`.
- [ ] Confirm no active `GENERAL` or `KHBL` rule still uses `APPROVED`.
- [ ] Confirm `LOADING -> LOADED` requires `POL`.
- [ ] Confirm `UNLOADING -> UNLOADED` requires `POD`.
- [ ] Confirm KHBL actor permissions block driver-owned loading-control steps.
- [ ] Confirm no active custom template still depends on removed `APPROVED` paths.

## 4. Workflow Smoke

- [ ] Run the dispatch workflow smoke:

```bash
./deploy/post_deploy_dispatch_workflow_smoke_vps.sh \
  --public-url https://svtms.svtrucking.biz \
  --admin-username superadmin --admin-password 'REPLACE' \
  --driver-username driver1 --driver-password 'REPLACE' \
  --general-dispatch-id 123 \
  --khbl-dispatch-id 456 \
  --fallback-dispatch-id 789 \
  --fallback-linked-template LEGACY_KHBL
```

- [ ] Save the output log or terminal transcript.
- [ ] Confirm the result contains `DISPATCH_WORKFLOW_SMOKE_OK`.

## 5. Manual Driver-App Validation

### GENERAL dispatch

- [ ] Open the `GENERAL` dispatch in the driver app.
- [ ] Confirm available actions match backend `available-actions`.
- [ ] Walk through:
  - [ ] `ASSIGNED -> DRIVER_CONFIRMED`
  - [ ] `DRIVER_CONFIRMED -> ARRIVED_LOADING`
  - [ ] `ARRIVED_LOADING -> SAFETY_PASSED`
  - [ ] `SAFETY_PASSED -> IN_QUEUE`
  - [ ] `IN_QUEUE -> LOADING`
- [ ] Confirm `LOADING -> LOADED` is blocked until POL proof upload.
- [ ] Upload POL and confirm status advances to `LOADED`.
- [ ] Continue unload path and confirm `UNLOADING -> UNLOADED` is blocked until POD proof upload.
- [ ] Upload POD and confirm status advances to `UNLOADED`.

### KHBL dispatch

- [ ] Open the `KHBL` dispatch in the driver app.
- [ ] Confirm driver does not directly receive executable actions for:
  - [ ] `IN_QUEUE`
  - [ ] `LOADING`
  - [ ] `LOADED`
- [ ] Confirm loading-team-controlled handoff behaves as expected.

### Split API checks

- [ ] `/api/driver-app/bootstrap` responds from public host.
- [ ] `/api/user-settings` responds from public host.
- [ ] `/api/driver/dispatches/{id}/available-actions` matches workflow policy.
- [ ] `/api/admin/dispatch-flow/resolve/{id}` shows correct linked and resolved template.

## 6. Production Release Gate

- [ ] Run the full release gate with workflow ids included:

```bash
./deploy/prod_morning_release_split_vps.sh \
  --vps root@YOUR_VPS \
  --ssh-key ~/.ssh/id_ed25519 \
  --public-url https://svtms.svtrucking.biz \
  --admin-username superadmin --admin-password 'REPLACE' \
  --driver-username driver1 --driver-password 'REPLACE' \
  --workflow-general-dispatch-id 123 \
  --workflow-khbl-dispatch-id 456 \
  --workflow-fallback-dispatch-id 789 \
  --workflow-fallback-linked-template LEGACY_KHBL \
  --manual-smoke-status pass \
  --deploy-cmd "sudo /opt/sv-tms/deploy/prod_release_split_vps.sh"
```

- [ ] Confirm all gates pass:
  - [ ] `MICROSERVICE_ROUTING_SMOKE_OK`
  - [ ] `OPENAPI_SPLIT_SMOKE_OK`
  - [ ] `DYNAMIC_DRIVER_POLICY_SMOKE_OK`
  - [ ] `DISPATCH_WORKFLOW_SMOKE_OK`
  - [ ] manual mobile smoke = `pass`
- [ ] Save the generated handover report path: `________________`

## 7. Post-Release Monitoring

- [ ] Monitor blocked transition errors.
- [ ] Monitor proof upload failures.
- [ ] Monitor template fallback occurrences.
- [ ] Monitor driver complaints about missing or unexpected actions.
- [ ] Capture the first 60-minute stabilization watch report.

## Outcome Record

- Environment: `staging / pilot / production`
- Date: `________________`
- Owner: `________________`
- Result: `GO / NO_GO`
- Notes:
  - `____________________________________________________________`
  - `____________________________________________________________`
