package com.svtrucking.logistics.service;

import com.svtrucking.logistics.dto.PartsMasterDto;
import com.svtrucking.logistics.model.PartsMaster;
import com.svtrucking.logistics.repository.PartsMasterRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

@Service
@RequiredArgsConstructor
@Slf4j
public class PartsMasterService {

  private final PartsMasterRepository partsMasterRepository;

  @Transactional(readOnly = true)
  public Page<PartsMasterDto> getAllParts(Boolean active, Pageable pageable) {
    if (active != null) {
      return partsMasterRepository
          .findByActiveAndIsDeletedFalse(active, pageable)
          .map(PartsMasterDto::fromEntity);
    }
    return partsMasterRepository.findAll(pageable).map(PartsMasterDto::fromEntity);
  }

  @Transactional(readOnly = true)
  public Page<PartsMasterDto> getPartsByCategory(String category, Boolean active, Pageable pageable) {
    return partsMasterRepository
        .findByCategoryAndActiveAndIsDeletedFalse(category, active != null ? active : true, pageable)
        .map(PartsMasterDto::fromEntity);
  }

  @Transactional(readOnly = true)
  public Page<PartsMasterDto> searchParts(String keyword, String category, Pageable pageable) {
    return partsMasterRepository
        .searchParts(keyword, category, pageable)
        .map(PartsMasterDto::fromEntity);
  }

  @Transactional(readOnly = true)
  public PartsMasterDto getPartById(Long id) {
    PartsMaster part =
        partsMasterRepository
            .findById(id)
            .orElseThrow(() -> new RuntimeException("Part not found with id: " + id));
    return PartsMasterDto.fromEntity(part);
  }

  @Transactional(readOnly = true)
  public PartsMasterDto getPartByCode(String partCode) {
    PartsMaster part =
        partsMasterRepository
            .findByPartCode(partCode)
            .orElseThrow(() -> new RuntimeException("Part not found with code: " + partCode));
    return PartsMasterDto.fromEntity(part);
  }

  @Transactional(readOnly = true)
  public List<String> getAllCategories() {
    return partsMasterRepository.findDistinctCategories();
  }

  @Transactional
  public PartsMasterDto createPart(PartsMasterDto dto) {
    log.info("Creating part: {}", dto.getPartCode());

    // Check if part code already exists
    if (partsMasterRepository.findByPartCode(dto.getPartCode()).isPresent()) {
      throw new RuntimeException("Part code already exists: " + dto.getPartCode());
    }

    PartsMaster part = dto.toEntity();
    PartsMaster savedPart = partsMasterRepository.save(part);

    log.info("Created part with ID: {}", savedPart.getId());
    return PartsMasterDto.fromEntity(savedPart);
  }

  @Transactional
  public PartsMasterDto updatePart(Long id, PartsMasterDto dto) {
    log.info("Updating part: {}", id);

    PartsMaster part =
        partsMasterRepository
            .findById(id)
            .orElseThrow(() -> new RuntimeException("Part not found with id: " + id));

    // Update fields
    part.setPartName(dto.getPartName());
    part.setCategory(dto.getCategory());
    part.setDescription(dto.getDescription());
    part.setUnitPrice(dto.getUnitPrice() != null ? java.math.BigDecimal.valueOf(dto.getUnitPrice()) : null);
    part.setSupplier(dto.getSupplier());
    part.setManufacturer(dto.getManufacturer());
    part.setActive(dto.getActive());

    PartsMaster updatedPart = partsMasterRepository.save(part);
    return PartsMasterDto.fromEntity(updatedPart);
  }

  @Transactional
  public void deactivatePart(Long id) {
    log.info("Deactivating part: {}", id);

    PartsMaster part =
        partsMasterRepository
            .findById(id)
            .orElseThrow(() -> new RuntimeException("Part not found with id: " + id));

    part.setActive(false);
    partsMasterRepository.save(part);
  }

  @Transactional
  public void deletePart(Long id) {
    log.info("Soft deleting part: {}", id);

    PartsMaster part =
        partsMasterRepository
            .findById(id)
            .orElseThrow(() -> new RuntimeException("Part not found with id: " + id));

    part.setIsDeleted(true);
    partsMasterRepository.save(part);
  }

  @Transactional(readOnly = true)
  public Long countActiveParts() {
    return partsMasterRepository.countByActiveAndIsDeletedFalse(true);
  }
}
