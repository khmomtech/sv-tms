package com.svtrucking.telematics.model;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.PrePersist;
import jakarta.persistence.PreUpdate;
import jakarta.persistence.Table;
import java.time.LocalDateTime;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

/**
 * Minimal driver info snapshot pushed by tms-backend (fire-and-forget PATCH
 * /api/internal/telematics/driver-sync).
 * Used so telematics service can display driver name/plate in public tracking
 * without cross-service joins.
 */
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
@Entity
@Table(name = "driver_snapshot")
public class DriverSnapshot {

    @Id
    @Column(name = "driver_id", nullable = false)
    private Long driverId;

    @Column(name = "full_name", length = 255)
    private String fullName;

    @Column(name = "phone_number", length = 32)
    private String phoneNumber;

    @Column(name = "vehicle_plate", length = 32)
    private String vehiclePlate;

    @Column(name = "synced_at", nullable = false)
    private LocalDateTime syncedAt;

    @PrePersist
    @PreUpdate
    void onSave() {
        this.syncedAt = LocalDateTime.now();
    }
}
