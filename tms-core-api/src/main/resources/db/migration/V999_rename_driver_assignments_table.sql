-- Migration: Rename driver_assignments table to assignment_vehicle_to_driver
-- This migration renames the table to align with the new class naming convention
-- Created: December 11, 2025

-- Rename table
ALTER TABLE driver_assignments RENAME TO assignment_vehicle_to_driver;

-- Rename indexes
ALTER INDEX idx_da_driver RENAME TO idx_avtd_driver;
ALTER INDEX idx_da_vehicle RENAME TO idx_avtd_vehicle;
ALTER INDEX idx_da_status RENAME TO idx_avtd_status;
ALTER INDEX idx_da_assigned_unassigned RENAME TO idx_avtd_assigned_unassigned;

-- Verify migration
SELECT TABLE_NAME FROM INFORMATION_SCHEMA.TABLES 
WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'assignment_vehicle_to_driver';
