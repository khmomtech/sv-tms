package com.svtrucking.logistics.model;

import com.svtrucking.logistics.enums.PreEntrySafetyStatus;
import jakarta.persistence.*;
import lombok.*;
import org.hibernate.annotations.CreationTimestamp;
import org.hibernate.annotations.UpdateTimestamp;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.List;

/**
 * Pre-entry safety check before warehouse arrival.
 * Performed at the gate/checkpoint before vehicle proceeds to loading
 * warehouse.
 * Separate from PreLoadingSafetyCheck which is done at warehouse loading bay.
 * 
 * This is part of Phase 3: Field Checker & Safety feature.
 * Enables detailed safety inspection with item-level tracking and conditional
 * overrides.
 */
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
@Entity
@Table(name = "pre_entry_safety_check", indexes = {
        @Index(name = "idx_pre_entry_dispatch", columnList = "dispatch_id"),
        @Index(name = "idx_pre_entry_vehicle", columnList = "vehicle_id"),
        @Index(name = "idx_pre_entry_driver", columnList = "driver_id"),
        @Index(name = "idx_pre_entry_status", columnList = "status"),
        @Index(name = "idx_pre_entry_check_date", columnList = "check_date")
})
public class PreEntrySafetyCheck {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @OneToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "dispatch_id", nullable = false, unique = true)
    private Dispatch dispatch;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "vehicle_id", nullable = false)
    private Vehicle vehicle;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "driver_id", nullable = false)
    private Driver driver;

    @Column(name = "warehouse_code", length = 50)
    private String warehouseCode;

    @Enumerated(EnumType.STRING)
    @Column(name = "status", nullable = false, length = 50)
    private PreEntrySafetyStatus status;

    @Column(name = "check_date", nullable = false)
    private LocalDate checkDate;

    @Column(name = "remarks", columnDefinition = "TEXT")
    private String remarks;

    // Inspection details
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "checked_by")
    private User checkedBy;

    @Column(name = "checked_at")
    private LocalDateTime checkedAt;

    @Column(name = "checker_signature_path", length = 255)
    private String checkerSignaturePath;

    @ElementCollection(fetch = FetchType.LAZY)
    @CollectionTable(name = "pre_entry_safety_inspection_photos", joinColumns = @JoinColumn(name = "safety_check_id"))
    @Column(name = "photo_path")
    private List<String> inspectionPhotos;

    // Conditional override
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "override_approved_by")
    private User overrideApprovedBy;

    @Column(name = "override_approved_at")
    private LocalDateTime overrideApprovedAt;

    @Column(name = "override_remarks", columnDefinition = "TEXT")
    private String overrideRemarks;

    // Metadata
    @CreationTimestamp
    @Column(name = "created_at", nullable = false, updatable = false)
    private LocalDateTime createdAt;

    @UpdateTimestamp
    @Column(name = "updated_at")
    private LocalDateTime updatedAt;

    // Relationships
    @OneToMany(mappedBy = "safetyCheck", cascade = CascadeType.ALL, fetch = FetchType.LAZY, orphanRemoval = true)
    private List<PreEntrySafetyItem> items;

    public String getDisplayStatus() {
        return status != null ? status.getValue() : "UNKNOWN";
    }
}
