# G Team — Safety & Loading Management (recap)

TL;DR
- Safety and load management ensure every load is within vehicle limits, secured, documented (photos + upload), and that any safety incident is escalated to Safety leads with an audit trail.

Key Points
- Roles: Drivers (pre-shift/load checks), Loaders (secure cargo), Dispatcher/G Lead (verify & sign-off), Safety Team (investigate incidents).
- Required checks: vehicle condition, max gross and axle weights, cargo distribution, restraining equipment (straps/chocks), and PPE for handlers.
- Documentation: photos before/after loading, checklist submission, case record for any incident with uploads to `uploads/` and an audit entry.
- Metrics & thresholds: follow vehicle plate/gross vehicle weight rating (GVWR) and axle limits; enforce posted speed/route restrictions for heavy loads.
- Escalation flow: loader/driver → Dispatcher/G Lead → Safety Team → Investigation/HR (if injury) with timestamps and audit trail.
- Training: annual safe lifting and load securement training; refresh after any incident.
- Tooling/processes: use the repo `uploads/` area for photos, create checklist entries in operations system, and attach case records for incidents.

Immediate actions (for G Team)
- A1 (high): Start daily pre-shift checklist enforcement — owner: Shift Lead — due: 1 week.
- A2 (high): Require photo uploads for every load (before/after) to `uploads/` and link to case — owner: Dispatch Ops — due: 2 weeks.
- A3 (medium): Add incident audit trail in case form and map "Safety" category to Safety Team contacts — owner: Engineering + Ops — due: 3 weeks.

Recommended follow-ups
- R1: Integrate checklist submission into driver-app (mobile) with offline caching and auto-upload when online.
- R2: Add automated alerts for overweight or missing photos to Dispatch Slack/Email.
- R3: Quarterly audit of checklist compliance and incident trends (owner: Safety Manager).

Files found (sources & references in repo)
- `ESCALATE_MODAL_IMPROVEMENTS.md` — escalation categories and Safety mapping.
- `ANGULAR_FRONTEND_PHASE2_COMPLETE.md` — loading states, file/photo upload notes, and testing checklist.
- `DAILY_TMS_ONCALL.md` — operational checks including `uploads` disk space and health endpoints.
- `WEBSOCKET_TOKEN_REFRESH_FIX.md` — subscription context; relevant for live tracking during loading.
- `CUSTOMER_MANAGEMENT_COMPLETE_SUMMARY.md` — example of audit trail implementation and DB indexes (reference for case auditing).

Notes
- This is an implementation-first summary intended to be used by Ops and Engineering as a starting SOP. Use `docs/G_TEAM/checklist.yaml` as the canonical checklist template for implementation.
