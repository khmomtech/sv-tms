-- Migration: Create driver_documents table
-- This migration creates the table to store driver documents with expiry tracking

CREATE TABLE IF NOT EXISTS driver_documents (
  id BIGINT AUTO_INCREMENT PRIMARY KEY,
  driver_id BIGINT NOT NULL,
  category VARCHAR(50) NOT NULL,
  expiry_date DATE,
  description TEXT,
  is_required BOOLEAN DEFAULT FALSE,
  file_url VARCHAR(500),
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  
  CONSTRAINT fk_driver_documents_driver FOREIGN KEY (driver_id) 
    REFERENCES drivers(id) ON DELETE CASCADE
);

-- Create indexes for better query performance
CREATE INDEX idx_driver_documents_driver_id ON driver_documents(driver_id);
CREATE INDEX idx_driver_documents_category ON driver_documents(category);
CREATE INDEX idx_driver_documents_expiry_date ON driver_documents(expiry_date);
CREATE INDEX idx_driver_documents_is_required ON driver_documents(is_required);
CREATE INDEX idx_driver_documents_driver_expiry ON driver_documents(driver_id, expiry_date);
