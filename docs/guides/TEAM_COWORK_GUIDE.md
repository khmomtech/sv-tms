# SV-TMS Team Cowork Guide — Claude Code

How to use Claude Code effectively on this project, by role.

---

## Setup (all roles)

1. Install Claude Code: `npm install -g @anthropic-ai/claude-code`
2. In your terminal, `cd` to the `sv-tms/` repo root.
3. Run `claude` — the project's `CLAUDE.md` and `.claude/` rules load automatically.
4. Slash commands are available immediately: type `/` to see the list.

Your developer-local settings live in `.claude/settings.local.json` (gitignored — safe to customize).

---

## By Role

### Product Manager (PM)

Your goal: write clear specs before engineers start coding.

**Start here:**
```
/new-feature Driver suspension after GPS spoofing threshold
```
Claude drafts: user stories, API contract, DB impact, acceptance criteria.

**After a sprint:**
```
/release-notes v1.3.0
```
Claude reads git commits and outputs categorized release notes.

**Key rules loaded automatically:** `pm.md`, `api-boundaries.md`

---

### UI / UX Designer + Frontend Engineer

Your goal: build Angular components that match the design system.

**Start here:**
```
/new-component Driver suspension history table with filters
```
Claude scaffolds: Angular component, service, template with Material + Tailwind, routing.

**Key rules loaded automatically:** `frontend.md`, `api-boundaries.md`, `testing.md`

**Dev server:**
```bash
cd tms-admin-web-ui && npm ci --legacy-peer-deps && npm start
# Opens at http://localhost:4200 — API proxied to port 8086
```

---

### Backend Engineer

Your goal: build and test Spring Boot services correctly.

**Add a DB change:**
```
/new-migration Add suspended_at column to drivers table
```

**Check API boundaries after adding an endpoint:**
```
/check-boundaries
```

**Key rules loaded automatically:** `build.md`, `database.md`, `api-boundaries.md`, `testing.md`

**Build:**
```bash
# Multi-module (from repo root)
./mvnw -pl tms-core-api -am clean package -DskipTests

# After any Lombok/MapStruct change — must regenerate
./mvnw clean package
```

---

### QA / Tester

Your goal: write tests that catch regressions before they reach production.

**Generate tests for a feature:**
```
/write-test DriverSuspensionService.suspendDriver()
```
Claude reads the source, writes unit + integration tests, runs them, reports results.

**Before every PR — run:**
```bash
./mvnw test                 # Backend unit tests
npm run test:ci             # Angular tests with coverage
flutter test                # Flutter widget/unit tests
/check-boundaries           # No API violations
```

**Key rules loaded automatically:** `qa.md`, `testing.md`

---

### DevOps / Deploy

Your goal: keep the VPS healthy and deploy safely.

**Check production health:**
```
/deploy-status
```

**Full deploy:**
```bash
bash DEPLOY_TO_VPS.sh
# Builds all services on VPS sequentially (~20 min first time)
```

**Roll back a broken service:**
```
/rollback core-api
```

**Watch live logs:**
```bash
ssh -i infra/deploy_key root@207.180.245.156 \
  "docker compose -f /opt/sv-tms/repo/infra/docker-compose.prod.yml \
                  -f /opt/sv-tms/repo/infra/docker-compose.build-override.yml logs -f"
```

**Key rules loaded automatically:** `devops.md`, `database.md`

---

## What Lives Where

| File | Who it's for | Checked into git? |
|---|---|---|
| `CLAUDE.md` | All roles — Claude reads this in every session | Yes |
| `.claude/settings.json` | All roles — team permission rules | Yes |
| `.claude/rules/*.md` | All roles — loaded by topic | Yes |
| `.claude/commands/*.md` | All roles — slash commands | Yes |
| `.claude/settings.local.json` | Individual developer — personal overrides | No (gitignored) |
| `~/.claude/CLAUDE.md` | Individual developer — personal preferences | No (local) |
| `.github/copilot-instructions.md` | GitHub Copilot users | Yes |
| `.agent.md` | Claude Agent SDK / automation | Yes |

---

## Tips for Effective Prompts

**Be specific:**
> "Fix the 401 error in `DriverSuspensionService.java:88` — token refresh fails when two requests fire simultaneously."

Not:
> "Fix the auth bug"

**Give Claude a way to verify:**
> "Write a failing test first, then fix the issue, then confirm the test passes."

**Scope your request:**
> "Only change `tms-core-api/`. Do not touch the Angular UI."

**Use Plan Mode for risky changes** (`claude --mode plan`):
Claude reads and plans but makes no changes until you approve.
