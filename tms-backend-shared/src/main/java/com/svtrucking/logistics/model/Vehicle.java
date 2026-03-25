package com.svtrucking.logistics.model;

import com.fasterxml.jackson.annotation.JsonIgnore;
import com.svtrucking.logistics.enums.TruckSize;
import com.svtrucking.logistics.enums.VehicleStatus;
import com.svtrucking.logistics.enums.VehicleType;
import com.svtrucking.logistics.enums.VehicleOwnership;
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
import jakarta.validation.constraints.*;
import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.List;
import org.hibernate.Hibernate;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.EqualsAndHashCode;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;
import jakarta.persistence.CascadeType;
import jakarta.persistence.FetchType;
import jakarta.persistence.Index;
import jakarta.persistence.PrePersist;
import jakarta.persistence.PreUpdate;
import jakarta.persistence.UniqueConstraint;

@Entity
@Table(name = "vehicles", indexes = {
        @Index(name = "idx_vehicle_plate", columnList = "license_plate"),
        @Index(name = "idx_vehicle_status", columnList = "status"),
        @Index(name = "idx_vehicle_type", columnList = "type"),
        @Index(name = "idx_vehicle_truck_size", columnList = "truck_size")
}, uniqueConstraints = {
        @UniqueConstraint(name = "uk_vehicle_license_plate", columnNames = { "license_plate" }),
        @UniqueConstraint(name = "uk_vehicle_vin", columnNames = { "vin" })
})
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
@EqualsAndHashCode(onlyExplicitlyIncluded = true)
public class Vehicle {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @EqualsAndHashCode.Include
    private Long id;

    @NotBlank
    @Size(max = 20)
    @Column(name = "license_plate", nullable = false, length = 20)
    private String licensePlate;

    @Size(max = 17)
    @Column(name = "vin", length = 17)
    private String vin;

    @DecimalMin(value = "0.00", inclusive = true)
    @Column(name = "fuel_consumption", precision = 8, scale = 2)
    private BigDecimal fuelConsumption;

    @DecimalMin(value = "0.00", inclusive = true)
    @Column(name = "max_weight", precision = 10, scale = 2)
    private BigDecimal maxWeight;

    @DecimalMin(value = "0.00", inclusive = true)
    @Column(name = "max_volume", precision = 10, scale = 2)
    private BigDecimal maxVolume;

    @Column(name = "last_inspection_date")
    private LocalDate lastInspectionDate;

    @Column(name = "next_service_due")
    private LocalDate nextServiceDue;

    @Column(name = "last_service_date")
    private LocalDate lastServiceDate;

    @NotBlank
    @Size(max = 80)
    @Column(name = "manufacturer", nullable = false, length = 80)
    private String manufacturer;

    @Min(1900)
    @Max(2100)
    @Column(name = "year_made")
    private Integer yearMade;

    @NotNull
    @DecimalMin(value = "0.00", inclusive = true)
    @Column(name = "mileage", precision = 10, scale = 2, nullable = false)
    private BigDecimal mileage;

    @NotBlank
    @Size(max = 80)
    @Column(name = "model", nullable = false, length = 80)
    private String model;

    // Trailer/parent vehicle reference (nullable)
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "parent_vehicle_id")
    @JsonIgnore
    private Vehicle parentVehicle;

    @NotNull
    @Enumerated(EnumType.STRING)
    @Column(name = "status", nullable = false, length = 20)
    private VehicleStatus status;

    @NotNull
    @Enumerated(EnumType.STRING)
    @Column(name = "type", nullable = false, length = 20)
    private VehicleType type;

    @NotNull
    @Enumerated(EnumType.STRING)
    @Column(name = "ownership", nullable = false, length = 20)
    private VehicleOwnership ownership;

    @Enumerated(EnumType.STRING)
    @Column(name = "truck_size", length = 20)
    private TruckSize truckSize;

    @PositiveOrZero
    @Column(name = "qty_pallets_capacity")
    private Integer qtyPalletsCapacity;

    @Size(max = 80)
    @Column(name = "assigned_zone", length = 80)
    private String assignedZone;

    @Column(name = "required_license_class", length = 10)
    private String requiredLicenseClass;

    @OneToMany(mappedBy = "vehicle", cascade = CascadeType.ALL, orphanRemoval = true, fetch = FetchType.LAZY)
    private List<VehicleRoute> routes;

    @Size(max = 64)
    @Column(name = "gps_device_id", length = 64)
    private String gpsDeviceId;

    @Column(name = "remarks", columnDefinition = "TEXT")
    private String remarks;

    @Column(name = "created_at", updatable = false, nullable = false)
    private LocalDateTime createdAt;

    @Column(name = "updated_at", nullable = false)
    private LocalDateTime updatedAt;

    @PrePersist
    public void onCreate() {
        LocalDateTime now = LocalDateTime.now();
        this.createdAt = now;
        this.updatedAt = now;

        // Ensure non-null enums have defaults
        if (this.status == null)
            this.status = VehicleStatus.AVAILABLE;
        if (this.type == null)
            this.type = VehicleType.TRUCK;
        if (this.ownership == null)
            this.ownership = VehicleOwnership.OWNED;
    }

    @PreUpdate
    public void onUpdate() {
        this.updatedAt = LocalDateTime.now();
    }

    @OneToMany(mappedBy = "vehicle", cascade = CascadeType.ALL, orphanRemoval = true, fetch = FetchType.LAZY)
    @JsonIgnore
    private List<VehicleDriver> assignments;

    @OneToMany(mappedBy = "vehicle", cascade = CascadeType.ALL, orphanRemoval = true, fetch = FetchType.LAZY)
    @JsonIgnore
    private List<VehicleDocument> documents;

    @OneToMany(mappedBy = "vehicle", fetch = FetchType.LAZY)
    @JsonIgnore
    private List<WorkOrder> workOrders;

    @OneToMany(mappedBy = "vehicle", fetch = FetchType.LAZY)
    @JsonIgnore
    private List<MaintenanceRequest> maintenanceRequests;

    @OneToMany(mappedBy = "parentVehicle", fetch = FetchType.LAZY)
    @JsonIgnore
    private List<Vehicle> trailers;

    @Transient
    public Driver getCurrentAssignedDriver() {
        if (assignments == null) return null;
        try {
            if (!Hibernate.isInitialized(assignments)) return null;
        } catch (Exception ignored) {
            return null;
        }
        return assignments.stream()
                .filter(VehicleDriver::isActive)
                .sorted(java.util.Comparator.comparing(VehicleDriver::getAssignedAt).reversed())
                .map(VehicleDriver::getDriver)
                .findFirst()
                .orElse(null);
    }

    @Override
    public String toString() {
        return "Vehicle{"
                + "id="
                + id
                + ", licensePlate='"
                + licensePlate
                + '\''
                + ", vin='"
                + vin
                + '\''
                + ", model='"
                + model
                + '\''
                + ", type="
                + type
                + ", ownership="
                + ownership
                + ", truckSize="
                + truckSize
                + ", status="
                + status
                + '}';
    }
}
