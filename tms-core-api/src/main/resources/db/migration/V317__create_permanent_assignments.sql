-- Create permanent_assignments table for 1:1 driver-truck assignments
CREATE TABLE permanent_assignments (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    driver_id BIGINT NOT NULL,
    vehicle_id BIGINT NOT NULL,
    assigned_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    assigned_by VARCHAR(100) NOT NULL,
    reason VARCHAR(500),
    revoked_at TIMESTAMP NULL,
    revoked_by VARCHAR(100),
    revoke_reason VARCHAR(500),
    version BIGINT NOT NULL DEFAULT 0,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NULL ON UPDATE CURRENT_TIMESTAMP,
    
    CONSTRAINT fk_permanent_assignment_driver FOREIGN KEY (driver_id) REFERENCES drivers(id) ON DELETE RESTRICT,
    CONSTRAINT fk_permanent_assignment_truck FOREIGN KEY (vehicle_id) REFERENCES vehicles(id) ON DELETE RESTRICT,
    
    INDEX idx_driver_active (driver_id, revoked_at),
    INDEX idx_truck_active (vehicle_id, revoked_at),
    INDEX idx_assigned_at (assigned_at),
    INDEX idx_revoked_at (revoked_at),
    INDEX idx_assigned_by (assigned_by)
);

-- Database-level constraint enforcement via triggers (MySQL 5.7/8.0 compatible)
DELIMITER $$

CREATE TRIGGER trg_before_insert_permanent_assignment
BEFORE INSERT ON permanent_assignments
FOR EACH ROW
BEGIN
    DECLARE active_driver_count INT;
    DECLARE active_truck_count INT;
    
    IF NEW.revoked_at IS NULL THEN
        SELECT COUNT(*) INTO active_driver_count
        FROM permanent_assignments
        WHERE driver_id = NEW.driver_id AND revoked_at IS NULL;
        
        IF active_driver_count > 0 THEN
            SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Driver already has an active assignment';
        END IF;
        
        SELECT COUNT(*) INTO active_truck_count
        FROM permanent_assignments
        WHERE vehicle_id = NEW.vehicle_id AND revoked_at IS NULL;
        
        IF active_truck_count > 0 THEN
            SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Truck already has an active assignment';
        END IF;
    END IF;
END$$

DELIMITER ;
