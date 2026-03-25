-- ============================================================
-- 03-device-gateway-db.sql
-- Creates the device_gateway schema and dedicated user for device-gateway.
-- ============================================================

CREATE DATABASE IF NOT EXISTS device_gateway
  CHARACTER SET utf8mb4
  COLLATE utf8mb4_unicode_ci;

CREATE USER IF NOT EXISTS 'gateway_user'@'%' IDENTIFIED WITH mysql_native_password BY 'gatewaypass';
GRANT ALL PRIVILEGES ON device_gateway.* TO 'gateway_user'@'%';

FLUSH PRIVILEGES;
