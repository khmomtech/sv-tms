# សៀវភៅ SOP (Khmer) - ប្រព័ន្ធ Split Microservices

គម្រោង: `sv-tms`  
កំណែប្រតិបត្តិការ: split (`tms-auth-api` + `tms-driver-app-api`)

## 1) ពិនិត្យប្រចាំថ្ងៃ (Daily)

1. ពិនិត្យសេវា:
```bash
systemctl is-active tms-auth-api tms-driver-app-api nginx
```

2. ពិនិត្យ health:
```bash
curl -fsS http://127.0.0.1:8083/actuator/health
curl -fsS http://127.0.0.1:8084/actuator/health
```

3. ពិនិត្យ log:
```bash
journalctl -u tms-auth-api -n 200 --no-pager
journalctl -u tms-driver-app-api -n 200 --no-pager
tail -n 200 /var/log/nginx/error.log
```

## 2) SOP Deploy (ត្រូវធ្វើតាមលំដាប់)

1. ពិនិត្យ service health  
2. រត់ routing smoke  
3. រត់ OpenAPI smoke
4. រត់ dynamic driver-policy smoke

```bash
./deploy/post_deploy_microservices_routing_smoke_vps.sh ...
./deploy/post_deploy_openapi_split_smoke_vps.sh ...
./deploy/post_deploy_dynamic_driver_policy_smoke_vps.sh ...
```

ត្រូវមាន marker ទាំងអស់:
- `MICROSERVICE_ROUTING_SMOKE_OK`
- `OPENAPI_SPLIT_SMOKE_OK`
- `DYNAMIC_DRIVER_POLICY_SMOKE_OK`

បើខ្វះ marker មួយណា = មិនអនុញ្ញាត release។

## 3) Route Ownership (ចាំបាច់)

### Auth API
- `/api/auth/**`
- `/api/driver/device/**`

### Driver App API
- `/api/driver/**`
- `/api/driver-app/**`
- `/api/public/app-version/**`
- `/ws`
- `/ws-sockjs/**`

## 4) SOP Incident (បញ្ហាផលិតកម្ម)

1. កំណត់ symptom និង scope  
2. កំណត់ owner (auth / driver-app / nginx)  
3. ពិនិត្យ:
```bash
systemctl status tms-auth-api tms-driver-app-api nginx
curl -s http://127.0.0.1:8083/actuator/health
curl -s http://127.0.0.1:8084/actuator/health
nginx -t
```
4. បើ fix មិនមានសុវត្ថិភាព -> rollback

## 5) SOP Rollback

```bash
sudo /opt/sv-tms/deploy/prod_rollback_vps.sh
sudo systemctl restart tms-auth-api
sudo systemctl restart tms-driver-app-api
sudo systemctl reload nginx
```

បន្ទាប់មក rerun smoke scripts ហើយ verify mobile flows សំខាន់ៗ។

## 6) Handover សម្រាប់ក្រុម

ត្រូវរាយការណ៍:
- ស្ថានភាពសេវា 3 (`auth`, `driver-app`, `nginx`)
- លទ្ធផល smoke 3
- mobile smoke (login, bootstrap, assignment, tracking)
- បញ្ហាដែលនៅសល់ + owner + deadline

## 7) Source Of Truth

- `/Users/sotheakh/Documents/develop/sv-tms/docs/README.md`
- `/Users/sotheakh/Documents/develop/sv-tms/docs/guides/SOP_INDEX.md`
- `/Users/sotheakh/Documents/develop/sv-tms/docs/deployment/VPS_MAINTENANCE_AND_MONITORING_RUNBOOK.md`
