-- Migration: Add name field to driver_documents table
-- This migration adds the document name field for proper document identification

ALTER TABLE driver_documents ADD COLUMN `name` VARCHAR(255) NOT NULL DEFAULT 'Unnamed Document' AFTER driver_id;
