-- Create table to store driver attendance records
CREATE TABLE IF NOT EXISTS driver_attendance (
  id BIGINT PRIMARY KEY AUTO_INCREMENT,
  driver_id BIGINT NOT NULL,
  attendance_date DATE NOT NULL,
  status VARCHAR(32) NOT NULL,
  check_in_time TIME NULL,
  check_out_time TIME NULL,
  hours_worked DECIMAL(5,2) NULL,
  notes TEXT NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NULL DEFAULT NULL,
  CONSTRAINT fk_driver_attendance_driver FOREIGN KEY (driver_id) REFERENCES drivers(id)
);

CREATE INDEX IF NOT EXISTS idx_attendance_driver_date ON driver_attendance(driver_id, attendance_date);
