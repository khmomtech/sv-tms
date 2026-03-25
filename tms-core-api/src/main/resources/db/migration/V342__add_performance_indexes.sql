-- Performance indexes required by GET /api/customer/{id}/incidents query
-- DriverIssueRepository.findByOrderCustomerId() joins:
--   driver_issues.dispatch_id -> dispatches.id (the FK join)
--   dispatches.customer_id   (filter)
--   driver_issues.incident_status (optional filter / ORDER BY)

CREATE INDEX IF NOT EXISTS idx_dispatches_customer_id
    ON dispatches (customer_id);

CREATE INDEX IF NOT EXISTS idx_driver_issues_dispatch_id
    ON driver_issues (dispatch_id);

CREATE INDEX IF NOT EXISTS idx_driver_issues_incident_status
    ON driver_issues (incident_status);
