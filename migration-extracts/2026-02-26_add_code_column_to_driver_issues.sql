-- Migration: Add code column to driver_issues table
ALTER TABLE driver_issues ADD COLUMN code VARCHAR(50) UNIQUE AFTER id;