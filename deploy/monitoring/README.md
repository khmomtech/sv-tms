# Monitoring & Backup — Quick deploy

This folder contains a minimal monitoring stack and a backup helper.

Files:
- `docker-compose.monitoring.yml` — Prometheus, Alertmanager, Grafana, Loki, Promtail, Blackbox.
- `prometheus.yml` — Prometheus scrape config (edit targets and HOST_EXPORTER placeholder).
- `alert_rules.yml` — basic alert rules (instance down, high CPU, disk low).
- `alertmanager.yml` — simple Alertmanager config (replace webhook).
- `promtail-config.yaml` — promtail config to forward `/var/log/*.log` to Loki.
- `grafana/provisioning/*` — Grafana provisioning (datasource + dashboards).
- `backup_to_s3.sh` — DB dump + upload script (set `--s3-bucket`).

How to run (single host prototype):

1. Install Docker and Docker Compose on a monitoring host (can be the VPS or separate host).

2. Edit `prometheus.yml`:
   - replace `HOST_EXPORTER` with your node exporter host (or run node_exporter as container and target it).
   - add your Spring Boot actuator metrics endpoint if different.

3. Start stack:
```
cd deploy/monitoring
docker compose -f docker-compose.monitoring.yml up -d
```

4. Configure exporters on the app host(s):
   - Install `node_exporter` (systemd) and `mysqld_exporter` (set `DATA_SOURCE_NAME`) and ensure they are accessible by Prometheus.
   - Expose Spring metrics via `/actuator/prometheus` (Micrometer). Ensure `management.endpoints.web.exposure.include=prometheus,health,info`.

5. Grafana is available on port `3000` (default admin password `ChangeMe`).

6. Backups: set AWS credentials (or other storage) and run:
```
chmod +x backup_to_s3.sh
./backup_to_s3.sh --db svlogistics_tms_db --s3-bucket your-bucket
```

Security & next steps:
- Replace placeholder passwords and webhook URLs with real secrets via a secrets manager.
- Add lifecycle rules on S3 to automatically expire backups.
- Configure Alertmanager integration with Slack, PagerDuty or email.
