# Emergency Dispatch Unblock

Use this only when driver dispatch actions, POL, or POD are blocked in production and operations must move immediately.

## 1. Enable backend emergency bypass

On the server running the dispatch backend:

```bash
sudo sh -c "grep -q '^APP_FEATURES_DISPATCH_WORKFLOW_EMERGENCY_BYPASS=' /etc/default/tms-backend \
  && sed -i.bak 's/^APP_FEATURES_DISPATCH_WORKFLOW_EMERGENCY_BYPASS=.*/APP_FEATURES_DISPATCH_WORKFLOW_EMERGENCY_BYPASS=true/' /etc/default/tms-backend \
  || echo 'APP_FEATURES_DISPATCH_WORKFLOW_EMERGENCY_BYPASS=true' >> /etc/default/tms-backend"

sudo systemctl restart tms-backend
```

If your dispatch endpoints are served by `tms-driver-app-api`, apply the same env var there too:

```bash
sudo sh -c "grep -q '^APP_FEATURES_DISPATCH_WORKFLOW_EMERGENCY_BYPASS=' /etc/default/tms-driver-app-api \
  && sed -i.bak 's/^APP_FEATURES_DISPATCH_WORKFLOW_EMERGENCY_BYPASS=.*/APP_FEATURES_DISPATCH_WORKFLOW_EMERGENCY_BYPASS=true/' /etc/default/tms-driver-app-api \
  || echo 'APP_FEATURES_DISPATCH_WORKFLOW_EMERGENCY_BYPASS=true' >> /etc/default/tms-driver-app-api"

sudo systemctl restart tms-driver-app-api
```

## 2. Unblock the database workflow rules

Run:

```bash
mysql -u USER -p DB_NAME < deploy/emergency_dispatch_workflow_unblock.sql
```

This does all of the following:

- sets blank/invalid dispatch template links to `GENERAL`
- activates `GENERAL` and `KHBL`
- enables all rules in those templates
- removes POL/POD DB proof gating
- grants `DRIVER` execution rights on every rule

## 3. Smoke check

Run:

```bash
./deploy/post_deploy_dispatch_workflow_smoke_vps.sh \
  --public-url https://svtms.svtrucking.biz \
  --admin-username superadmin \
  --admin-password 'REPLACE' \
  --driver-username driver1 \
  --driver-password 'REPLACE' \
  --general-dispatch-id 123
```

## 4. Driver app refresh

- force close and reopen the app, or
- reopen the dispatch after 30 seconds so cached actions expire

## 5. Recovery after incident

When operations are stable again:

- disable `APP_FEATURES_DISPATCH_WORKFLOW_EMERGENCY_BYPASS`
- restore intended DB policy from your proper workflow templates
- rerun normal workflow smoke
