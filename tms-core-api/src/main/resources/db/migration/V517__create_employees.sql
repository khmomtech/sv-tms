-- Create employees table to back Employee entity
CREATE TABLE IF NOT EXISTS employees (
  id BIGINT AUTO_INCREMENT PRIMARY KEY,
  employee_code VARCHAR(50) NOT NULL UNIQUE,
  first_name VARCHAR(100) NOT NULL,
  last_name VARCHAR(100) NOT NULL,
  email VARCHAR(150) NOT NULL UNIQUE,
  phone VARCHAR(50),
  department VARCHAR(120),
  position VARCHAR(120),
  hire_date DATE,
  status VARCHAR(20),
  user_id BIGINT,
  CONSTRAINT fk_employees_user FOREIGN KEY (user_id) REFERENCES users(id)
);
