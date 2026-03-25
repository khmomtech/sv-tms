# SV-TMS Safety Portal

Admin web app to digitize monthly driver daily safety inspection book (Khmer-first).

Prerequisites:

- Node 18+, npm
- Angular CLI 17

Quick dev:

1. Install: `npm ci`
2. Start mock backend: `npm run start:mock`
3. Run app: `npm run dev` (uses Angular CLI; ensure `API_BASE_URL` in `src/environments/environment.ts` points to mock)

Build production:

1. `npm run build`
2. `docker build -t sv-tms-safety-portal:latest .`

See docs/ for API contract, Khmer user guide, runbook.
