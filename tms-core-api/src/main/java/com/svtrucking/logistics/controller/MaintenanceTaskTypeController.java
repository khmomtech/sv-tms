package com.svtrucking.logistics.controller;

import com.svtrucking.logistics.core.ApiResponse;
import com.svtrucking.logistics.dto.MaintenanceTaskTypeDto;
import com.svtrucking.logistics.service.MaintenanceTaskTypeService;
import jakarta.validation.Valid;
import java.time.Instant;
import java.util.List;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.*;
import org.springframework.http.*;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/admin/maintenance-task-types")
@CrossOrigin(origins = "*")
@RequiredArgsConstructor
public class MaintenanceTaskTypeController {

  private final MaintenanceTaskTypeService service;

  @GetMapping("/list")
  public ResponseEntity<ApiResponse<Page<MaintenanceTaskTypeDto>>> getAll(
      @RequestParam(defaultValue = "") String search,
      @RequestParam(defaultValue = "0") int page,
      @RequestParam(defaultValue = "10") int size) {
    Pageable pageable = PageRequest.of(page, size, Sort.by("id").descending());
    Page<MaintenanceTaskTypeDto> data = service.getAll(search, pageable);
    return ResponseEntity.ok(
        new ApiResponse<>(true, " Task types loaded", data, null, Instant.now()));
  }

  @GetMapping("/all")
  public ResponseEntity<ApiResponse<List<MaintenanceTaskTypeDto>>> getAllNoPage() {
    return ResponseEntity.ok(
        new ApiResponse<>(true, " All task types", service.getAllNoPage(), null, Instant.now()));
  }

  @GetMapping("/{id}")
  public ResponseEntity<ApiResponse<MaintenanceTaskTypeDto>> getById(@PathVariable Long id) {
    return ResponseEntity.ok(
        new ApiResponse<>(true, " Task type found", service.getById(id), null, Instant.now()));
  }

  @PostMapping
  public ResponseEntity<ApiResponse<MaintenanceTaskTypeDto>> create(
      @Valid @RequestBody MaintenanceTaskTypeDto dto) {
    return ResponseEntity.status(HttpStatus.CREATED)
        .body(
            new ApiResponse<>(
                true, " Task type created", service.create(dto), null, Instant.now()));
  }

  @PutMapping("/{id}")
  public ResponseEntity<ApiResponse<MaintenanceTaskTypeDto>> update(
      @PathVariable Long id, @Valid @RequestBody MaintenanceTaskTypeDto dto) {
    return ResponseEntity.ok(
        new ApiResponse<>(
            true, " Task type updated", service.update(id, dto), null, Instant.now()));
  }

  @DeleteMapping("/{id}")
  public ResponseEntity<ApiResponse<Void>> delete(@PathVariable Long id) {
    service.delete(id);
    return ResponseEntity.ok(
        new ApiResponse<>(true, " Task type deleted", null, null, Instant.now()));
  }
}
