package com.svtrucking.logistics.dto;

import com.fasterxml.jackson.annotation.JsonInclude;
import com.fasterxml.jackson.annotation.JsonProperty;
import com.svtrucking.logistics.enums.DriverStatus;
import com.svtrucking.logistics.enums.VehicleType;
import com.svtrucking.logistics.model.Driver;
import com.svtrucking.logistics.model.DriverLatestLocation;
import com.svtrucking.logistics.model.LocationHistory;
import com.svtrucking.logistics.model.Vehicle;
import com.svtrucking.logistics.utils.AssetUrlHelper;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.Comparator;
import java.util.List;
import java.util.Optional;
import java.util.function.Supplier;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;
import org.hibernate.LazyInitializationException;
import org.hibernate.exception.SQLGrammarException;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.dao.InvalidDataAccessResourceUsageException;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
@JsonInclude(JsonInclude.Include.NON_NULL)
public class DriverDto {

    private static final Logger LOG = LoggerFactory.getLogger(DriverDto.class);

    private Long id;
    private String firstName;
    private String lastName;
    private String name; // full name (optional for backward compatibility)
    private String licenseNumber;
    private String licenseClass; // Commercial license class (A, B, C, D, etc.)
    private String phone;
    private Double rating;

    // Performance metrics (current month summary from drivers table)
    private Integer performanceScore;
    private Integer score; // Alias for performanceScore
    private Integer rank; // Alias for leaderboardRank
    private Integer leaderboardRank;
    private Integer onTimePercent;
    private String safety;
    private String safetyScore; // Alias for safety

    // Monthly performance details (from driver_monthly_performance table)
    private Integer totalDeliveries;
    private Integer completedDeliveries;
    private Integer onTimeDeliveries;
    private String rankTier; // Gold, Silver, Bronze
    private String performancePeriod; // e.g., "2025-12" for current month

    @JsonProperty("isActive")
    private Boolean active;

    private String zone;
    private VehicleType vehicleType;
    private DriverStatus status;
    private LocalDateTime lastLocationAt;

    private String partnerCompany;

    @JsonProperty("isPartner")
    private Boolean partner;

    private String profilePicture;
    private Double latitude;
    private Double longitude;
    private String deviceToken;
    private LocalDate idCardExpiry;
    private Long driverGroupId;
    private String driverGroupName;

    private Long employeeId;
    private Long assignedVehicleId;
    private VehicleDto assignedVehicle;

    // New flat fields
    private String assignedVehiclePlate;
    private VehicleType assignedVehicleType;

    // Latest location snapshot
    private LocationHistoryDto latestLocation;

    private UserSimpleDto user;
    private List<LocationHistoryDto> locationHistory;

    // -------------------- Factory Methods --------------------

    public static DriverDto fromEntity(Driver driver) {
        return fromEntity(driver, true, false);
    }

    public static DriverDto fromEntityWithLatestLocation(Driver driver) {
        return fromEntity(driver, true, true);
    }

    public static DriverDto fromEntityWithoutLocationHistory(Driver driver) {
        return fromEntity(driver, false, false);
    }

    public static DriverDto fromEntity(
            Driver driver, boolean includeLocationHistory, boolean onlyLatestLocation) {
        if (driver == null)
            return null;

        // ---- Location (from latestLocation relationship or history) ----
        List<LocationHistoryDto> locationHistoryDtos = null;
        Double lat = null;
        Double lng = null;
        LocalDateTime lastLocationTime = null;
        LocationHistoryDto latestLocDto = null;

        DriverLatestLocation latestLocation = null;
        try {
            latestLocation = driver.getLatestLocation();
        } catch (LazyInitializationException lie) {
                    LOG.debug("Latest location proxy not initialized for driver {}: {}", driver.getId(), lie.getMessage());
        }

        if (latestLocation != null) {
            lat = latestLocation.getLatitude();
            lng = latestLocation.getLongitude();
            if (latestLocation.getLastSeen() != null) {
                lastLocationTime = latestLocation.getLastSeen().toLocalDateTime();
            }
        }

        if (includeLocationHistory) {
            List<LocationHistory> hist = null;
            try {
                hist = driver.getLocationHistory();
            } catch (LazyInitializationException lie) {
                        LOG.debug(
                                "Location history proxy not initialized for driver {}: {}", driver.getId(), lie.getMessage());
            }

            if (hist != null && !hist.isEmpty()) {
                List<LocationHistory> sorted = hist.stream()
                        .sorted(Comparator.comparing(LocationHistory::getTimestamp).reversed())
                        .toList();

                if (!sorted.isEmpty()) {
                    if (onlyLatestLocation) {
                        LocationHistory latest = sorted.get(0);
                        latestLocDto = LocationHistoryDto.fromEntity(latest);
                        locationHistoryDtos = List.of(latestLocDto);
                        lat = latest.getLatitude();
                        lng = latest.getLongitude();
                        lastLocationTime = latest.getTimestamp();
                    } else {
                        locationHistoryDtos = sorted.stream().map(LocationHistoryDto::fromEntity).toList();
                    }
                }
            }
        }

        // ---- Assigned vehicle ----
        VehicleDto vehicleDto = null;
        Long vehicleId = null;
        String vehiclePlate = null;
        VehicleType vehicleType = null;

        Vehicle vehicle = safeGetCurrentAssignedVehicle(driver);
        // Use getCurrentAssignedVehicle() for assignment
        if (vehicle != null) {
            try {
                vehicleId = vehicle.getId();
                vehiclePlate = vehicle.getLicensePlate();
                vehicleType = vehicle.getType();
            } catch (Exception e) {
                        LOG.debug("Could not read vehicle info for driver {}: {}", driver.getId(), e.toString());
            }

            try {
                vehicleDto = VehicleDto.fromEntity(vehicle);
            } catch (LazyInitializationException lie) {
                LOG.warn(
                        "Vehicle mapping triggered lazy load outside session for driver {}: {}",
                        driver.getId(),
                        lie.getMessage());
            } catch (Exception e) {
                LOG.warn("Failed to map assigned vehicle for driver {}: {}", driver.getId(), e.getMessage());
            }
        }

        // ---- Name fallback ----
        String resolvedFullName = Optional.ofNullable(driver.getFullName())
                .filter(n -> !n.isBlank())
                .orElseGet(
                        () -> {
                            String first = Optional.ofNullable(driver.getFirstName()).orElse("");
                            String last = Optional.ofNullable(driver.getLastName()).orElse("");
                            return (first + " " + last).trim();
                        });

        return DriverDto.builder()
                .id(driver.getId())
                .firstName(driver.getFirstName())
                .lastName(driver.getLastName())
                .name(resolvedFullName)
                .licenseNumber(driver.getLicenseNumber())
                .licenseClass(driver.getLicenseClass())
                .phone(driver.getPhone())
                .rating(driver.getRating())
                .performanceScore(driver.getPerformanceScore())
                .score(driver.getPerformanceScore()) // Alias
                .leaderboardRank(driver.getLeaderboardRank())
                .rank(driver.getLeaderboardRank()) // Alias
                .onTimePercent(driver.getOnTimePercent())
                .safetyScore(driver.getSafetyScore())
                .safety(driver.getSafetyScore()) // Alias
                .active(Boolean.TRUE.equals(driver.getIsActive()))
                .zone(driver.getZone())
                .status(driver.getStatus())
                .idCardExpiry(driver.getIdCardExpiry())
                .lastLocationAt(lastLocationTime)
                .partnerCompany(
                        driver.getPartnerCompanyEntity() != null ? driver.getPartnerCompanyEntity().getCompanyName()
                                : null)
                .partner(driver.isPartner())
                .profilePicture(resolveProfilePictureUrl(driver.getProfilePicture()))
                .latitude(lat)
                .longitude(lng)
                .deviceToken(driver.getDeviceToken())
                .driverGroupId(
                        safeLazy(
                                driver.getId(),
                                "driverGroupId",
                                () -> Optional.ofNullable(driver.getDriverGroup()).map(g -> g.getId()).orElse(null)))
                .driverGroupName(
                        safeLazy(
                                driver.getId(),
                                "driverGroupName",
                                () -> Optional.ofNullable(driver.getDriverGroup()).map(g -> g.getName()).orElse(null)))
                .employeeId(Optional.ofNullable(driver.getEmployee()).map(e -> e.getId()).orElse(null))
                .user(
                        safeLazy(
                                driver.getId(),
                                "user",
                                () -> UserSimpleDto.fromEntity(driver.getUser())))
                .assignedVehicleId(vehicleId)
                .assignedVehicle(vehicleDto)
                .assignedVehiclePlate(vehiclePlate)
                .assignedVehicleType(vehicleType)
                .latestLocation(latestLocDto)
                .locationHistory(locationHistoryDtos)
                .build();
    }

    private static String resolveProfilePictureUrl(String storedPath) {
        return AssetUrlHelper.toAbsoluteUrl(storedPath);
    }

    private static Vehicle safeGetCurrentAssignedVehicle(Driver driver) {
        try {
            return driver.getCurrentAssignedVehicle();
        } catch (SQLGrammarException | InvalidDataAccessResourceUsageException ex) {
            LOG.warn(
                    "Vehicles table schema mismatch while resolving assignment for driver {}: {}",
                    driver.getId(),
                    ex.getMessage());
        } catch (LazyInitializationException lie) {
            LOG.debug(
                    "Assigned vehicle helper triggered lazy load for driver {}: {}",
                    driver.getId(),
                    lie.getMessage());
        } catch (Exception e) {
            LOG.debug("Failed to resolve assigned vehicle for driver {}: {}", driver.getId(), e.getMessage());
        }
        return null;
    }

    private static <T> T safeLazy(Long driverId, String label, Supplier<T> supplier) {
        try {
            return supplier.get();
        } catch (LazyInitializationException lie) {
            LOG.debug("Lazy load skipped for {} of driver {}: {}", label, driverId, lie.getMessage());
        } catch (Exception e) {
            LOG.debug("Failed to read {} for driver {}: {}", label, driverId, e.getMessage());
        }
        return null;
    }
}
