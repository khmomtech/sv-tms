# Runbook

- Dev: `npm ci && npm run start:mock && npm run dev`
- Prod build: `npm run build` then `docker build -t sv-tms-safety-portal .` and deploy image behind nginx
- Troubleshooting: check console for missing translations, network calls to `API_BASE_URL`
