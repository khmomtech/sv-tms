---
name: release-notes
description: PM — generate release notes from git commits since last tag or date
---

Generate release notes for: $ARGUMENTS (e.g. "v1.2.0" or "since 2026-03-01")

Steps:
1. Get the commit log since the last release tag or the specified date:
   ```bash
   git log --oneline --no-merges --since="{date}"
   # or
   git log {previous-tag}..HEAD --oneline --no-merges
   ```
2. Categorize each commit into:
   - **New Features** — new capabilities added
   - **Bug Fixes** — defects corrected
   - **Improvements** — performance, UX, or code quality improvements
   - **Infrastructure / DevOps** — deploy, config, monitoring changes
   - **Security** — security-related fixes
3. Write release notes in this format:

---
## Release {version} — {date}

### New Features
- ...

### Bug Fixes
- ...

### Improvements
- ...

### Infrastructure
- ...

### Security
- ...

### Upgrade Notes
Any manual steps required (DB migrations to run, env vars to add, services to restart in a specific order).

---

4. List any Flyway migrations included in this release (check `tms-core-api/src/main/resources/db/migration/` for new files since the last release).
5. Flag any breaking API changes that affect mobile apps or integrations.
