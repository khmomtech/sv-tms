# Phase 2 Staging Update

Use this after the Phase 2 workflow versioning changes are deployed to staging.

## 1. Backend Migration Check

Run after the staging backend starts:

```bash
mysql -u USER -p DB_NAME < deploy/inspect_dispatch_workflow_templates.sql
```

Confirm:

- `dispatch_flow_template_version` has published rows for `GENERAL` and `KHBL`
- `dispatches.workflow_version_id` is populated
- `dispatches.pod_required`, `pod_submitted`, `pod_submitted_at` exist and backfilled
- `dispatch_proof_event` exists

## 2. Split Release Gate

```bash
./deploy/prod_morning_release_split_vps.sh \
  --vps root@STAGING_HOST \
  --ssh-key ~/.ssh/id_ed25519 \
  --public-url https://STAGING_PUBLIC_URL \
  --admin-username superadmin \
  --admin-password 'REPLACE' \
  --driver-username driver1 \
  --driver-password 'REPLACE' \
  --workflow-general-dispatch-id 123 \
  --workflow-khbl-dispatch-id 456 \
  --workflow-fallback-dispatch-id 789 \
  --workflow-fallback-linked-template LEGACY_KHBL \
  --manual-smoke-status pending \
  --deploy-cmd "sudo /opt/sv-tms/deploy/prod_release_split_vps.sh"
```

## 3. Workflow Smoke Only

```bash
./deploy/post_deploy_dispatch_workflow_smoke_vps.sh \
  --public-url https://STAGING_PUBLIC_URL \
  --admin-username superadmin \
  --admin-password 'REPLACE' \
  --driver-username driver1 \
  --driver-password 'REPLACE' \
  --general-dispatch-id 123 \
  --khbl-dispatch-id 456 \
  --fallback-dispatch-id 789 \
  --fallback-linked-template LEGACY_KHBL
```

Expected result:

- bootstrap and `/api/user-settings` return `200`
- `GENERAL` and `KHBL` resolve from admin diagnostics
- no legacy `APPROVED` action path
- POL/POD metadata present on proof-gated transitions
- fallback dispatch resolves to `GENERAL`

## 4. Runtime Info

Verify both public services before device testing:

```bash
curl -fsS https://STAGING_PUBLIC_URL/api/public/runtime-info | jq
```

Check:

- expected service name
- expected git SHA/build time
- workflow migration/version details

## 5. Device Validation

Install the latest APK:

`tms_driver_app/build/app/outputs/flutter-apk/app-prod-release.apk`

Run:

- `GENERAL` happy path
- POL upload with idempotent retry behavior on poor network
- POD upload with idempotent retry behavior on poor network
- `KHBL` dispatch where driver cannot take loading-team-owned actions

