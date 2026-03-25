package com.svtrucking.logistics.controller;

import com.svtrucking.logistics.core.ApiResponse;
import com.svtrucking.logistics.dto.SafetyCheckDto;
import com.svtrucking.logistics.dto.SafetyCheckItemDto;
import com.svtrucking.logistics.dto.requests.PublicSafetyCheckRequest;
import com.svtrucking.logistics.repository.VehicleRepository;
import com.svtrucking.logistics.service.SafetyCheckService;
import jakarta.validation.Valid;
import java.time.LocalDate;
import java.util.List;
import java.util.Set;
import lombok.RequiredArgsConstructor;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/public/safety-checks")
@RequiredArgsConstructor
public class PublicSafetyCheckController {

  private final SafetyCheckService safetyCheckService;
  private final VehicleRepository vehicleRepository;

  @GetMapping("/vehicles")
  public ResponseEntity<ApiResponse<Set<String>>> listVehiclePlates() {
    return ResponseEntity.ok(ApiResponse.success("Vehicles", vehicleRepository.findAllPlates()));
  }

  @GetMapping("/today")
  public ResponseEntity<ApiResponse<SafetyCheckDto>> today(
      @RequestParam("plate") String plate) {
    SafetyCheckDto dto = safetyCheckService.getPublicToday(plate);
    return ResponseEntity.ok(ApiResponse.success("Public today safety check", dto));
  }

  // Keep `/master` for backward compatibility with deployed safety frontend.
  // Also support `/master-items` as a clearer alias.
  @GetMapping({"/master", "/master-items"})
  public ResponseEntity<ApiResponse<List<SafetyCheckItemDto>>> masterItems() {
    List<SafetyCheckItemDto> list = safetyCheckService.getPublicMasterItems();
    return ResponseEntity.ok(ApiResponse.success("Public safety master items", list));
  }

  @GetMapping("/history")
  public ResponseEntity<ApiResponse<List<SafetyCheckDto>>> history(
      @RequestParam("plate") String plate,
      @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate from,
      @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate to) {
    List<SafetyCheckDto> list = safetyCheckService.getPublicHistory(plate, from, to);
    return ResponseEntity.ok(ApiResponse.success("Public safety history", list));
  }

  @GetMapping("/{id}")
  public ResponseEntity<ApiResponse<SafetyCheckDto>> detail(
      @PathVariable("id") Long id,
      @RequestParam("plate") String plate) {
    SafetyCheckDto dto = safetyCheckService.getPublicDetail(id, plate);
    return ResponseEntity.ok(ApiResponse.success("Public safety detail", dto));
  }

  @GetMapping("/detail")
  public ResponseEntity<ApiResponse<SafetyCheckDto>> detailByQuery(
      @RequestParam("id") Long id,
      @RequestParam("plate") String plate) {
    SafetyCheckDto dto = safetyCheckService.getPublicDetail(id, plate);
    return ResponseEntity.ok(ApiResponse.success("Public safety detail", dto));
  }

  @PostMapping("/submit")
  public ResponseEntity<ApiResponse<SafetyCheckDto>> submitPublic(
      @Valid @RequestBody PublicSafetyCheckRequest request) {
    SafetyCheckDto dto = safetyCheckService.submitPublic(request);
    return ResponseEntity.ok(ApiResponse.success("Submitted", dto));
  }
}
