-- Migration: Add audit tracking to driver_documents table
-- This migration adds the updated_by column to track which user last modified each document

ALTER TABLE driver_documents ADD COLUMN `updated_by` VARCHAR(255) DEFAULT 'system' AFTER updated_at;

-- Add an index on updated_by for filtering by user
CREATE INDEX idx_driver_documents_updated_by ON driver_documents(updated_by);

-- Add an index on updated_at for sorting/filtering
CREATE INDEX idx_driver_documents_updated_at ON driver_documents(updated_at);

-- Update existing records to have 'system' as the updater
UPDATE driver_documents SET updated_by = 'system' WHERE updated_by IS NULL;

-- Make the column non-nullable after setting defaults
ALTER TABLE driver_documents MODIFY COLUMN `updated_by` VARCHAR(255) NOT NULL DEFAULT 'system';
