SV-TMS Monitoring Guide

Overview
- Prometheus scrapes application and host metrics.
- Alertmanager receives Prometheus alerts.
- Grafana provides dashboards.
- node-exporter provides host metrics.
- cAdvisor provides container metrics.

Files
- [prometheus.yml](/Users/sotheakh/Documents/develop/sv-tms/infra/monitoring/prometheus.yml)
- [alert_rules.yml](/Users/sotheakh/Documents/develop/sv-tms/infra/monitoring/alert_rules.yml)
- [alertmanager.yml](/Users/sotheakh/Documents/develop/sv-tms/infra/monitoring/alertmanager.yml)
- [platform-overview.json](/Users/sotheakh/Documents/develop/sv-tms/infra/monitoring/grafana/dashboards/platform-overview.json)

What is scraped
- `core-api`
- `auth-api`
- `driver-app-api`
- `telematics-api`
- `safety-api`
- `message-api`
- `api-gateway`
- `node-exporter`
- `cadvisor`

Default local access
- Prometheus: `http://127.0.0.1:9090`
- Alertmanager: `http://127.0.0.1:9093`
- Grafana: `http://127.0.0.1:3000`

Why localhost-bound
- Monitoring UI and TSDB are not exposed publicly by default.
- Reach them via SSH tunnel or a private admin network.

Current alerts
- service down
- low host disk space
- telematics spool growth
- gateway 429 spike

Alert delivery
- Prometheus now forwards alerts to Alertmanager.
- The default Alertmanager config uses a localhost webhook placeholder: `http://127.0.0.1:19093/alerts`.
- Replace that receiver or route it through your own bridge service for Slack, email, PagerDuty, or a webhook processor.

Common production pattern
- Keep Alertmanager localhost-bound.
- Run a small internal alert bridge on the same host or private network.
- Let that bridge translate Alertmanager webhooks to Slack/email/PagerDuty with your secrets.

Dashboard notes
- The provisioned dashboard is a compact platform overview.
- It shows healthy service target count, telematics spool size, request rate, and host disk usage.

Operational guidance
- Change `GRAFANA_ADMIN_PASSWORD` in `infra/.env` before first production boot.
- Keep Prometheus data under `${DATA_ROOT}/monitoring/prometheus`.
- Keep Grafana state under `${DATA_ROOT}/monitoring/grafana`.
- Back those directories up with the rest of your host storage if you want dashboard and TSDB retention.
