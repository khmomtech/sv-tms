package com.svtrucking.logistics.model;

import com.fasterxml.jackson.annotation.JsonIgnoreProperties;
import com.fasterxml.jackson.annotation.JsonInclude;
import com.fasterxml.jackson.annotation.JsonManagedReference;
import com.svtrucking.logistics.enums.DriverStatus;
import com.svtrucking.logistics.enums.VehicleType;
import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.ManyToOne;
import jakarta.persistence.OneToMany;
import jakarta.persistence.Table;
import jakarta.persistence.Transient;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.List;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;
import jakarta.persistence.CascadeType;
import jakarta.persistence.FetchType;
import jakarta.persistence.OneToOne;
import jakarta.persistence.PrePersist;
import jakarta.persistence.PreUpdate;
// DriverLicense import removed — using driver_documents

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
// Removed unused imports after refactor
@Builder
@Entity
@Table(name = "drivers", indexes = {

        @jakarta.persistence.Index(name = "idx_driver_device", columnList = "device_token"),
        @jakarta.persistence.Index(name = "idx_driver_user", columnList = "user_id"),
        @jakarta.persistence.Index(name = "idx_driver_status", columnList = "status"),
        @jakarta.persistence.Index(name = "idx_driver_zone", columnList = "zone")
})
@JsonIgnoreProperties({ "hibernateLazyInitializer", "handler" })
public class Driver {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "first_name")
    private String firstName;

    @Column(name = "last_name")
    private String lastName;

    @Column(name = "name")
    private String name; // Computed field

    @Column(name = "license_class", length = 10)
    private String licenseClass;

    @Column(nullable = false)
    private String phone;

    private Double rating;

    @Column(name = "id_card_expiry")
    private LocalDate idCardExpiry;

    // Performance metrics
    @Column(name = "performance_score")
    @Builder.Default
    private Integer performanceScore = 92;

    @Column(name = "leaderboard_rank")
    @Builder.Default
    private Integer leaderboardRank = 0;

    @Column(name = "on_time_percent")
    @Builder.Default
    private Integer onTimePercent = 98;

    @Column(name = "safety_score")
    @Builder.Default
    private String safetyScore = "Excellent";

    @Column(name = "is_active")
    private Boolean isActive;

    private String zone;

    @Enumerated(EnumType.STRING)
    @Column(name = "vehicle_type")
    private VehicleType vehicleType;

    @Enumerated(EnumType.STRING)
    @Column(name = "status", length = 16 /* default set in @PrePersist */)
    private DriverStatus status;

    @Column(name = "device_token")
    private String deviceToken;

    @Column(name = "profile_picture")
    private String profilePicture;

    @Column(name = "is_partner", nullable = false)
    private boolean isPartner;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "driver_group_id")
    private DriverGroup driverGroup;

    /** Reference to partner company */
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "partner_company_id")
    private PartnerCompany partnerCompanyEntity;

    // Heartbeat tracking fields
    @Column(name = "last_seen_at")
    private LocalDateTime lastSeenAt;

    @Column(name = "net_type")
    private String netType;

    @Column(name = "battery")
    private Integer battery;

    @Column(name = "gps_on")
    private Boolean gpsOn;

    @Column(name = "app_version")
    private String appVersion;

    // Login account (optional)
    @OneToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "user_id", unique = true)
    private User user;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "employee_id")
    private Employee employee;

    // Kept for compatibility (you can remove if no longer used)
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "assigned_vehicle_id")
    private Vehicle assignedVehicle;

    // Temporary override vehicle (valid until expiry). If set and not expired, this
    // is the
    // effective vehicle shown to Driver App and used for dispatch/trip mapping.
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "temp_assigned_vehicle_id")
    private Vehicle tempAssignedVehicle;

    @Column(name = "temp_assignment_expiry")
    private LocalDateTime tempAssignmentExpiry;

    @OneToMany(mappedBy = "driver", cascade = CascadeType.ALL, fetch = FetchType.LAZY)
    private List<VehicleDriver> vehicleDriverAssignments;

    @OneToMany(mappedBy = "driver", cascade = CascadeType.ALL, fetch = FetchType.LAZY)
    @JsonInclude(JsonInclude.Include.NON_EMPTY)
    private List<Dispatch> assignedDispatches;

    @OneToMany(mappedBy = "driver", cascade = CascadeType.ALL, fetch = FetchType.LAZY)
    @JsonManagedReference
    private List<LocationHistory> locationHistory;

    @OneToMany(mappedBy = "driver", cascade = CascadeType.ALL, fetch = FetchType.LAZY)
    private List<DriverMonthlyPerformance> monthlyPerformance;

    // driverLicense relationship removed — license documents are now stored in
    // driver_documents (category='license')

    // Transient holder for license number (read from driver_documents, not
    // driver_licenses)
    @Transient
    private String licenseNumber;

    @OneToOne(mappedBy = "driver", cascade = CascadeType.ALL, orphanRemoval = true, fetch = FetchType.LAZY)
    private DriverLatestLocation latestLocation;

    // Computed: Get full name
    public String getFullName() {
        return ((firstName != null ? firstName : "") + " " + (lastName != null ? lastName : "")).trim();
    }

    // getLicenseNumber / setLicenseNumber delegate to the plain @Transient field.
    // License data lives in driver_documents (category='license').
    public String getLicenseNumber() {
        return this.licenseNumber;
    }

    public void setLicenseNumber(String licenseNumber) {
        this.licenseNumber = licenseNumber;
    }

    @PrePersist
    @PreUpdate
    public void syncNameField() {
        this.name = getFullName();

        if (this.status == null) {
            this.status = DriverStatus.ONLINE; // default
        }
    }

    // ---------- Assignment helpers ----------
    /**
     * Returns the current active VehicleDriver assignment for this driver, or null
     * if none.
     */
    @Transient
    public VehicleDriver getCurrentVehicleDriverAssignment() {
        if (vehicleDriverAssignments == null || vehicleDriverAssignments.isEmpty()) {
            return null;
        }
        return vehicleDriverAssignments.stream()
                .filter(VehicleDriver::isActive)
                .sorted((a, b) -> b.getAssignedAt().compareTo(a.getAssignedAt()))
                .findFirst()
                .orElse(null);
    }

    @Transient
    public Vehicle getCurrentAssignedVehicle() {
        // Prefer temporary override if not expired
        if (tempAssignedVehicle != null) {
            if (tempAssignmentExpiry == null || tempAssignmentExpiry.isAfter(LocalDateTime.now())) {
                return tempAssignedVehicle;
            }
        }
        VehicleDriver currentAssignment = getCurrentVehicleDriverAssignment();
        if (currentAssignment != null && currentAssignment.getVehicle() != null) {
            return currentAssignment.getVehicle();
        }
        return assignedVehicle;
    }

    @Transient
    public Long getCurrentAssignedVehicleId() {
        Vehicle v = getCurrentAssignedVehicle();
        return v != null ? v.getId() : null;
    }

    // Helper: Has login account
    @Transient
    public boolean hasLoginAccount() {
        return this.user != null;
    }
}
