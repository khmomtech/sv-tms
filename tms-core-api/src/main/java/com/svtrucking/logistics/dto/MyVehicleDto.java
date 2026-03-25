package com.svtrucking.logistics.dto;

import com.fasterxml.jackson.annotation.JsonFormat;
import com.fasterxml.jackson.annotation.JsonInclude;
import lombok.Builder;
import lombok.Data;

import java.time.LocalDate;

@Data
@Builder
@JsonInclude(JsonInclude.Include.NON_NULL)
public class MyVehicleDto {

    // Vehicle Info
    private String licensePlate;
    private String status;
    private String vehicleType;
    private String fuelType;
    private String engineNumber;
    private String model;
    private String manufacturer;

    // Assignment Info
    private String assignedTo;
    @JsonFormat(pattern = "yyyy-MM-dd")
    private LocalDate assignedDate;

    // Maintenance Info
    @JsonFormat(pattern = "yyyy-MM-dd")
    private LocalDate lastServiceAt;
    @JsonFormat(pattern = "yyyy-MM-dd")
    private LocalDate nextServiceAt;
    private String maintenanceStatus;
    @JsonFormat(pattern = "yyyy-MM-dd")
    private LocalDate annualInspectionDate;
    @JsonFormat(pattern = "yyyy-MM-dd")
    private LocalDate nextPreventiveCheckDate;
    private Integer fatsRemainingKm;
    private Integer engineOilRemainingKm;

    // Document Expiry Info
    @JsonFormat(pattern = "yyyy-MM-dd")
    private LocalDate insuranceExpiry;
    @JsonFormat(pattern = "yyyy-MM-dd")
    private LocalDate registrationExpiry;
    @JsonFormat(pattern = "yyyy-MM-dd")
    private LocalDate permitExpiry;
    @JsonFormat(pattern = "yyyy-MM-dd")
    private LocalDate gpsCertificateExpiry;
}
