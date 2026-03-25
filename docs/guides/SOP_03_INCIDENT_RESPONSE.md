# SOP 03 - Incident Response

## Purpose

Handle production problems quickly and safely.

## Severity

- SEV1: login or core driver flow down
- SEV2: partial feature degraded
- SEV3: minor issue, workaround exists

## First 10 Minutes

1. Confirm symptom and scope.
2. Identify likely owner:
   - auth routes -> `tms-auth-api`
   - driver routes/websocket -> `tms-driver-app-api` or nginx
3. Run checks:
```bash
systemctl status tms-auth-api tms-driver-app-api nginx
curl -s http://127.0.0.1:8083/actuator/health
curl -s http://127.0.0.1:8084/actuator/health
nginx -t
```
4. Start live logs:
```bash
journalctl -u tms-auth-api -f
journalctl -u tms-driver-app-api -f
tail -f /var/log/nginx/error.log
```

## Decision

- If safe fix exists: apply fix and validate.
- If not safe: rollback using SOP 04.

## Fast Triage Patterns

### Pattern 1: Login fails with "Invalid username or password" for known admin

1. Check auth logs for SQL/schema errors:
```bash
journalctl -u tms-auth-api -n 200 --no-pager | grep -i "Unknown column\\|SQL Error\\|Login failed"
```
2. If missing `customers.device_token`, apply:
```bash
mysql -uroot -prootpass -D svlogistics_tms_db \
  -e 'ALTER TABLE customers ADD COLUMN device_token VARCHAR(512) NULL;'
```
3. Re-test login endpoint and verify logs no longer show SQL errors.

### Pattern 2: WebSocket/SockJS fails on `svtms.svtrucking.biz`

1. Confirm nginx ws routes point to driver-app (`8084`):
```bash
grep -n 'location /ws/\|location /ws-sockjs/\|proxy_pass http://127.0.0.1:8084' /etc/nginx/sites-available/svtms
```
2. Confirm SockJS info:
```bash
curl -i 'https://svtms.svtrucking.biz/ws-sockjs/info?token=TEST'
```
3. If route is wrong or info is not 200 JSON, fix nginx and reload:
```bash
nginx -t && systemctl reload nginx
```

## Close Criteria

- Service healthy.
- Route ownership smoke passes.
- Impact confirmed resolved on mobile smoke flow.
