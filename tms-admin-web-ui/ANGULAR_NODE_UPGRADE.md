# Angular Node Upgrade & Headless Testing

This project now targets **Node >= 20.19.0** (see `package.json` engines and `.nvmrc`).

## Why the upgrade?
Angular 20 and modern tooling (ESBuild, Vite polyfills, Puppeteer) rely on Node 20+ for:
- Stable native test runner & improved V8 performance.
- Proper ESM resolution without legacy interop warnings.
- Headless Chrome (Puppeteer) compatibility and future-proof TLS/security defaults.

## Getting the right Node locally
```bash
# If you use nvm
nvm install 20.19.0
nvm use 20.19.0

# Optional: set default
nvm alias default 20.19.0
```

Check:
```bash
node -v   # should print v20.19.0 or higher
npm -v    # should be >=10
```

## Install dependencies
```bash
npm ci --no-audit --no-fund
```

## Running tests headless (CI style)
```bash
npm run test:ci
```
Uses Puppeteer-provided Chromium with custom launcher `ChromeHeadlessNoSandbox` defined in `karma.conf.js`.

## Debug tests locally
```bash
npm run test:debug
```
Watch mode with headless Chrome; remove `--browsers` flag or change to `Chrome` for visible UI if you have a local Chrome installed.

## Linting (added ESLint baseline)
ESLint dependencies added; you can scaffold a config:
```bash
npm init @eslint/config
```
Recommended parser: `@typescript-eslint/parser` and plugin `@typescript-eslint/eslint-plugin`.

## CI considerations
- Ensure workflow sets up Node 20.19.0 (actions/setup-node@v4).
- Use `npm ci` not `npm install` for reproducibility.
- Run `npm run test:ci` to produce coverage in `coverage/`.

## Common Issues
| Symptom | Fix |
|---------|-----|
| Puppeteer download slow | Set `PUPPETEER_SKIP_DOWNLOAD=1` if using system Chrome; otherwise keep default. |
| ENOMEM / dev-shm errors in container | `--disable-dev-shm-usage` flag already set in custom launcher. |
| Sandbox permission denied | `--no-sandbox` flag included for container environments. |

## Next Steps
1. Add ESLint config and a script `lint`.
2. Add first service spec tests (document service preview logic).
3. Wire coverage threshold enforcement in karma config.
4. Consider Playwright migration for future E2E tests.

---
Updated: 2025-11-18
