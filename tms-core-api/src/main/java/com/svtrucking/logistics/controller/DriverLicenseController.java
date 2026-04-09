package com.svtrucking.logistics.controller;

import com.svtrucking.logistics.core.ApiResponse;
import com.svtrucking.logistics.dto.DriverLicenseDto;
import com.svtrucking.logistics.service.DriverLicenseService;
import com.svtrucking.logistics.service.FileStorageService;
import java.util.List;
import lombok.RequiredArgsConstructor;
import org.springframework.http.*;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

@RestController
@RequestMapping("/api/admin/driver-licenses")
@CrossOrigin(origins = "*")
@RequiredArgsConstructor
public class DriverLicenseController {

  private final DriverLicenseService driverLicenseService;
  private final FileStorageService fileStorageService;

  //  CREATE License
  @PostMapping("/{driverId}")
  public ResponseEntity<ApiResponse<DriverLicenseDto>> addDriverLicense(
      @PathVariable Long driverId, @RequestBody DriverLicenseDto licenseDto) {
    try {
      DriverLicenseDto saved = driverLicenseService.createOrUpdateLicense(driverId, licenseDto);
      return ResponseEntity.ok(new ApiResponse<>(true, "License saved successfully.", saved));
    } catch (Exception e) {
      return ResponseEntity.status(HttpStatus.BAD_REQUEST)
          .body(new ApiResponse<>(false, "Failed to save license: " + e.getMessage()));
    }
  }

  // ✏️ UPDATE License
  @PutMapping("/{driverId}")
  public ResponseEntity<ApiResponse<DriverLicenseDto>> updateDriverLicense(
      @PathVariable Long driverId, @RequestBody DriverLicenseDto licenseDto) {
    try {
      DriverLicenseDto updated = driverLicenseService.createOrUpdateLicense(driverId, licenseDto);
      return ResponseEntity.ok(new ApiResponse<>(true, "License updated.", updated));
    } catch (Exception e) {
      return ResponseEntity.status(HttpStatus.BAD_REQUEST)
          .body(new ApiResponse<>(false, "Failed to update license: " + e.getMessage()));
    }
  }

  //  READ License by Driver ID
  @GetMapping("/{driverId}")
  public ResponseEntity<ApiResponse<DriverLicenseDto>> getLicenseByDriverId(
      @PathVariable Long driverId) {
    try {
      DriverLicenseDto dto = driverLicenseService.getLicenseByDriverId(driverId);
      if (dto == null) {
        return ResponseEntity.status(HttpStatus.NOT_FOUND)
            .body(new ApiResponse<>(false, "License not found."));
      }
      return ResponseEntity.ok(new ApiResponse<>(true, "License fetched.", dto));
    } catch (Exception e) {
      return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
          .body(new ApiResponse<>(false, "Failed to fetch license: " + e.getMessage()));
    }
  }

  //  DELETE by License ID (soft delete)
  @DeleteMapping("/by-id/{licenseId}")
  public ResponseEntity<ApiResponse<String>> deleteLicenseById(@PathVariable Long licenseId) {
    try {
      driverLicenseService.deleteLicenseById(licenseId);
      return ResponseEntity.ok(new ApiResponse<>(true, "License deleted."));
    } catch (Exception e) {
      return ResponseEntity.status(HttpStatus.BAD_REQUEST)
          .body(new ApiResponse<>(false, "Failed to delete license: " + e.getMessage()));
    }
  }

  //  All Licenses (admin use)
  @GetMapping
  public ResponseEntity<ApiResponse<List<DriverLicenseDto>>> getAllLicenses(
      @RequestParam(defaultValue = "false") boolean includeDeleted) {
    try {
      List<DriverLicenseDto> list =
          includeDeleted
              ? driverLicenseService.getAllLicensesIncludingDeleted()
              : driverLicenseService.getAllLicenses();
      return ResponseEntity.ok(new ApiResponse<>(true, "Licenses fetched", list));
    } catch (Exception e) {
      return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
          .body(new ApiResponse<>(false, "Failed to fetch licenses: " + e.getMessage()));
    }
  }

  //  Upload Front Card
  @PostMapping("/{driverId}/upload-front")
  public ResponseEntity<ApiResponse<String>> uploadFrontImage(
      @PathVariable Long driverId, @RequestParam MultipartFile file) {
    return handleFileUpload(file, "licenses", driverId, true);
  }

  //  Upload Back Card
  @PostMapping("/{driverId}/upload-back")
  public ResponseEntity<ApiResponse<String>> uploadBackImage(
      @PathVariable Long driverId, @RequestParam MultipartFile file) {
    return handleFileUpload(file, "licenses", driverId, false);
  }

  //  Shared Upload Logic
  private ResponseEntity<ApiResponse<String>> handleFileUpload(
      MultipartFile file, String folder, Long driverId, boolean isFront) {

    String contentType = file.getContentType();
    if (file.isEmpty() || contentType == null || !contentType.startsWith("image/")) {
      return ResponseEntity.badRequest()
          .body(new ApiResponse<>(false, "Invalid or empty image file. Content-Type must be image/*."));
    }

    try {
      String fileUrl = fileStorageService.storeFileInSubfolder(file, folder);
      driverLicenseService.updateLicenseImage(driverId, isFront, fileUrl);
      return ResponseEntity.ok(new ApiResponse<>(true, "Upload successful", fileUrl));
    } catch (Exception e) {
      return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
          .body(new ApiResponse<>(false, "Upload failed: " + e.getMessage()));
    }
  }
}
