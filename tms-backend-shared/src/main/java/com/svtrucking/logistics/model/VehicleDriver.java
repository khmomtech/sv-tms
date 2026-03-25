package com.svtrucking.logistics.model;

import jakarta.persistence.*;
import java.time.LocalDateTime;
import lombok.Data;
import org.springframework.data.annotation.CreatedDate;
import org.springframework.data.annotation.LastModifiedDate;
import org.springframework.data.jpa.domain.support.AuditingEntityListener;

@Entity
@Table(name = "vehicle_drivers", indexes = {
        @Index(name = "idx_driver_active", columnList = "driver_id,revoked_at"),
        @Index(name = "idx_truck_active", columnList = "vehicle_id,revoked_at"),
        @Index(name = "idx_assigned_at", columnList = "assigned_at"),
        @Index(name = "idx_revoked_at", columnList = "revoked_at")
})
@Data
@EntityListeners(AuditingEntityListener.class)
public class VehicleDriver {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "driver_id", nullable = false)
    private Driver driver;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "vehicle_id", nullable = false)
    private Vehicle vehicle;

    @Column(name = "assigned_at", nullable = false)
    private LocalDateTime assignedAt;

    @Column(name = "assigned_by", nullable = false)
    private String assignedBy; // admin user ID or username

    @Column(name = "reason")
    private String reason;

    @Column(name = "revoked_at")
    private LocalDateTime revokedAt;

    @Column(name = "revoked_by")
    private String revokedBy;

    @Column(name = "revoke_reason")
    private String revokeReason;

    @Version
    @Column(name = "version")
    private Long version; // Optimistic locking

    @CreatedDate
    @Column(name = "created_at", nullable = false, updatable = false)
    private LocalDateTime createdAt;

    @LastModifiedDate
    @Column(name = "updated_at")
    private LocalDateTime updatedAt;

    @PrePersist
    protected void onCreate() {
        if (assignedAt == null) {
            assignedAt = LocalDateTime.now();
        }
        if (this.version == null) {
            this.version = 0L;
        }
    }

    @PostLoad
    private void initializeVersion() {
        if (this.version == null) {
            this.version = 0L;
        }
    }

    @PreUpdate
    private void ensureVersionNotNull() {
        if (this.version == null) {
            this.version = 0L;
        }
    }

    public boolean isActive() {
        return revokedAt == null;
    }

    public boolean canBeRevoked() {
        return isActive();
    }
}
