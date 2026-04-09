package com.svtrucking.logistics.controller;

import com.svtrucking.logistics.dto.PartsMasterDto;
import com.svtrucking.logistics.service.PartsMasterService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PatchMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;

@RestController
@RequestMapping("/api/admin/parts")
@RequiredArgsConstructor
@PreAuthorize("hasAnyRole('ADMIN', 'MANAGER', 'DISPATCHER')")
public class PartsMasterController {

  private final PartsMasterService partsMasterService;

  @GetMapping
  public ResponseEntity<Page<PartsMasterDto>> getAllParts(
      @RequestParam(required = false) Boolean active, Pageable pageable) {
    return ResponseEntity.ok(partsMasterService.getAllParts(active, pageable));
  }

  @GetMapping("/category/{category}")
  public ResponseEntity<Page<PartsMasterDto>> getPartsByCategory(
      @PathVariable String category,
      @RequestParam(required = false) Boolean active,
      Pageable pageable) {
    return ResponseEntity.ok(partsMasterService.getPartsByCategory(category, active, pageable));
  }

  @GetMapping("/search")
  public ResponseEntity<Page<PartsMasterDto>> searchParts(
      @RequestParam(required = false) String keyword,
      @RequestParam(required = false) String category,
      Pageable pageable) {
    return ResponseEntity.ok(partsMasterService.searchParts(keyword, category, pageable));
  }

  @GetMapping("/categories")
  public ResponseEntity<List<String>> getAllCategories() {
    return ResponseEntity.ok(partsMasterService.getAllCategories());
  }

  @GetMapping("/{id}")
  public ResponseEntity<PartsMasterDto> getPartById(@PathVariable Long id) {
    return ResponseEntity.ok(partsMasterService.getPartById(id));
  }

  @GetMapping("/code/{partCode}")
  public ResponseEntity<PartsMasterDto> getPartByCode(@PathVariable String partCode) {
    return ResponseEntity.ok(partsMasterService.getPartByCode(partCode));
  }

  @PostMapping
  @PreAuthorize("hasAnyRole('ADMIN', 'MANAGER')")
  public ResponseEntity<PartsMasterDto> createPart(@Valid @RequestBody PartsMasterDto partDto) {
    PartsMasterDto created = partsMasterService.createPart(partDto);
    return ResponseEntity.status(HttpStatus.CREATED).body(created);
  }

  @PutMapping("/{id}")
  @PreAuthorize("hasAnyRole('ADMIN', 'MANAGER')")
  public ResponseEntity<PartsMasterDto> updatePart(
      @PathVariable Long id, @Valid @RequestBody PartsMasterDto partDto) {
    return ResponseEntity.ok(partsMasterService.updatePart(id, partDto));
  }

  @PatchMapping("/{id}/deactivate")
  @PreAuthorize("hasAnyRole('ADMIN', 'MANAGER')")
  public ResponseEntity<Void> deactivatePart(@PathVariable Long id) {
    partsMasterService.deactivatePart(id);
    return ResponseEntity.noContent().build();
  }

  @DeleteMapping("/{id}")
  @PreAuthorize("hasRole('ADMIN')")
  public ResponseEntity<Void> deletePart(@PathVariable Long id) {
    partsMasterService.deletePart(id);
    return ResponseEntity.noContent().build();
  }

  @GetMapping("/stats/active-count")
  public ResponseEntity<Long> countActiveParts() {
    return ResponseEntity.ok(partsMasterService.countActiveParts());
  }
}
