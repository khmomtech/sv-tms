package com.svtrucking.logistics.service;

import com.svtrucking.logistics.dto.FailureCodeDto;
import com.svtrucking.logistics.exception.ResourceNotFoundException;
import com.svtrucking.logistics.model.FailureCode;
import com.svtrucking.logistics.repository.FailureCodeRepository;
import java.util.List;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
@RequiredArgsConstructor
public class FailureCodeService {

  private final FailureCodeRepository failureCodeRepository;

  @Transactional(readOnly = true)
  public Page<FailureCodeDto> list(Boolean active, Pageable pageable) {
    return failureCodeRepository.findByActive(active, pageable).map(FailureCodeDto::fromEntity);
  }

  @Transactional(readOnly = true)
  public List<FailureCodeDto> listActive() {
    return failureCodeRepository.findByActiveTrueOrderByCodeAsc().stream()
        .map(FailureCodeDto::fromEntity)
        .toList();
  }

  @Transactional(readOnly = true)
  public FailureCodeDto get(Long id) {
    FailureCode entity =
        failureCodeRepository
            .findById(id)
            .orElseThrow(() -> new ResourceNotFoundException("Failure code not found: " + id));
    return FailureCodeDto.fromEntity(entity);
  }

  @Transactional
  public FailureCodeDto create(FailureCodeDto dto) {
    FailureCode entity =
        FailureCode.builder()
            .code(dto.getCode())
            .description(dto.getDescription())
            .category(dto.getCategory())
            .active(dto.getActive() == null ? Boolean.TRUE : dto.getActive())
            .build();
    return FailureCodeDto.fromEntity(failureCodeRepository.save(entity));
  }

  @Transactional
  public FailureCodeDto update(Long id, FailureCodeDto dto) {
    FailureCode entity =
        failureCodeRepository
            .findById(id)
            .orElseThrow(() -> new ResourceNotFoundException("Failure code not found: " + id));
    if (dto.getCode() != null) entity.setCode(dto.getCode());
    if (dto.getDescription() != null) entity.setDescription(dto.getDescription());
    if (dto.getCategory() != null) entity.setCategory(dto.getCategory());
    if (dto.getActive() != null) entity.setActive(dto.getActive());
    return FailureCodeDto.fromEntity(failureCodeRepository.save(entity));
  }

  @Transactional
  public void deactivate(Long id) {
    FailureCode entity =
        failureCodeRepository
            .findById(id)
            .orElseThrow(() -> new ResourceNotFoundException("Failure code not found: " + id));
    entity.setActive(false);
    failureCodeRepository.save(entity);
  }
}
