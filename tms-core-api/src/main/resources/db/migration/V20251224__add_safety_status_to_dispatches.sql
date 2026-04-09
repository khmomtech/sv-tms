-- Add safety_status column to store safety check result separately from lifecycle status
ALTER TABLE dispatches ADD COLUMN safety_status VARCHAR(50);
