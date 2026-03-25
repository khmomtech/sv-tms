-- ============================================================
-- 01-telematics-db.sql
-- Creates the svlogistics_telematics schema and dedicated user
-- for tms-telematics-api.
-- ============================================================

CREATE DATABASE IF NOT EXISTS svlogistics_telematics
  CHARACTER SET utf8mb4
  COLLATE utf8mb4_unicode_ci;

CREATE USER IF NOT EXISTS 'tele_user'@'%' IDENTIFIED WITH mysql_native_password BY 'telepass';
GRANT ALL PRIVILEGES ON svlogistics_telematics.* TO 'tele_user'@'%';

FLUSH PRIVILEGES;
