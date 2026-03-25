# Assumptions

- Safety checklist master data is stored in DB and seeded from Excel (file: `របាយការណ៍តៃកុងត្រួតពិនិត្យ_ប្រចាំថ្ងៃ_2.xlsx`), with additional workflow categories (driver health, safety equipment, load, environment) added to match the required 6-step flow.
- Admin KPI cards on the list page are computed from the currently loaded page of results, not from a dedicated aggregate endpoint.
- Environment selections are stored as item remarks with automatic risk results (e.g., Rain/Fog/Night → YES_RISK, MEDIUM by default).
- Driver app uses SharedPreferences for offline draft storage and queued attachments.
- Dispatch creation is blocked in backend service; driver app also blocks “Start Trip” on Home when not approved.
- Excel import merges by `category.code` / Khmer name and `item_key` (defaults to `item_{id}` from Excel).
