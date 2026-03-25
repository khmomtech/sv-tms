package com.svtrucking.logistics.service;

import com.svtrucking.logistics.dto.MaintenanceTaskTypeDto;
import com.svtrucking.logistics.model.MaintenanceTaskType;
import com.svtrucking.logistics.repository.MaintenanceTaskTypeRepository;
import jakarta.persistence.EntityNotFoundException;
import java.util.List;
import java.util.stream.Collectors;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.*;
import org.springframework.stereotype.Service;

@Service
@RequiredArgsConstructor
public class MaintenanceTaskTypeService {

  private final MaintenanceTaskTypeRepository repo;

  public Page<MaintenanceTaskTypeDto> getAll(String keyword, Pageable pageable) {
    Page<MaintenanceTaskType> page =
        (keyword == null || keyword.isEmpty())
            ? repo.findAll(pageable)
            : repo.findByNameContainingIgnoreCase(keyword, pageable);

    return page.map(MaintenanceTaskTypeDto::fromEntity);
  }

  public List<MaintenanceTaskTypeDto> getAllNoPage() {
    return repo.findAll().stream()
        .map(MaintenanceTaskTypeDto::fromEntity)
        .collect(Collectors.toList());
  }

  public MaintenanceTaskTypeDto getById(Long id) {
    MaintenanceTaskType entity =
        repo.findById(id).orElseThrow(() -> new EntityNotFoundException("Task Type not found"));
    return MaintenanceTaskTypeDto.fromEntity(entity);
  }

  public MaintenanceTaskTypeDto create(MaintenanceTaskTypeDto dto) {
    MaintenanceTaskType saved = repo.save(MaintenanceTaskTypeDto.toEntity(dto));
    return MaintenanceTaskTypeDto.fromEntity(saved);
  }

  public MaintenanceTaskTypeDto update(Long id, MaintenanceTaskTypeDto dto) {
    MaintenanceTaskType existing =
        repo.findById(id).orElseThrow(() -> new EntityNotFoundException("Task Type not found"));
    existing.setName(dto.getName());
    existing.setDescription(dto.getDescription());
    return MaintenanceTaskTypeDto.fromEntity(repo.save(existing));
  }

  public void delete(Long id) {
    if (!repo.existsById(id)) {
      throw new EntityNotFoundException("Task Type not found");
    }
    repo.deleteById(id);
  }
}
