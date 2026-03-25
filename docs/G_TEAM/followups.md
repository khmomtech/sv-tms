# G Team — Safety & Loading Follow-ups

Purpose: concrete improvements to implement after the initial SOP and checklist.

Priority: High
- Integrate checklist submission into driver-app (mobile).
  - Owner: Mobile Lead (Driver App)
  - ETA: 3-4 sprints
  - Notes: offline caching, photo attachments, auto-retry, attach to case when `escalate=true`.

- Enforce required photo uploads and server-side validation.
  - Owner: Backend Lead
  - ETA: 2 sprints
  - Notes: store files under `uploads/` with structured path `uploads/safety/YYYY/MM/DD/vehicle_reg/` and create DB record linking checklist → case.

Priority: Medium
- Add Slack/email alerts for missing photos or overweight reports.
  - Owner: Ops Tooling
  - ETA: 2 sprints
  - Notes: webhook from backend when checklist saved with flags (missing_photos, overweight).

- Add a lightweight report in Ops UI for recent checklists and compliance rate.
  - Owner: Frontend Lead
  - ETA: 3 sprints

Priority: Low
- Quarterly automated compliance audit (safety manager) with exportable CSV.

Suggested PR scope
- Backend: add `Checklist` entity, controller endpoint `POST /api/checklists`, file upload handling, and audit link to `cases`.
- Frontend/Mobile: add checklist UI, photo capture, and upload flow; show spinner/loading states and confirm submission.

Next steps
- Create issues in backlog for each item above, estimate, and schedule first high-priority tasks.
