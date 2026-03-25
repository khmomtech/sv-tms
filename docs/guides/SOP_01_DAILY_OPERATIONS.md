# SOP 01 - Daily Operations

## Purpose

Keep production healthy every day.

## Steps (Run In Order)

1. Check services:
```bash
systemctl is-active tms-auth-api tms-driver-app-api nginx
```

2. Check local health:
```bash
curl -fsS http://127.0.0.1:8083/actuator/health
curl -fsS http://127.0.0.1:8084/actuator/health
```

3. Check logs:
```bash
journalctl -u tms-auth-api -n 200 --no-pager
journalctl -u tms-driver-app-api -n 200 --no-pager
tail -n 200 /var/log/nginx/error.log
```

4. Check public endpoints quickly:
```bash
curl -I -s https://svtmsapi.svtrucking.biz/api/auth/health || true
curl -I -s https://svtmsapi.svtrucking.biz/api/driver-app/home-layout || true
```

## If Something Fails

- Open incident using SOP 03.
- Do not deploy new release until issue is stable.

