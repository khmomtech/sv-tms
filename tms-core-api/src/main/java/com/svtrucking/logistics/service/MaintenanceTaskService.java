package com.svtrucking.logistics.service;

import com.svtrucking.logistics.dto.MaintenanceTaskDto;
import com.svtrucking.logistics.model.MaintenanceTask;
import com.svtrucking.logistics.model.MaintenanceTaskType;
import com.svtrucking.logistics.model.Vehicle;
import com.svtrucking.logistics.repository.MaintenanceTaskRepository;
import com.svtrucking.logistics.repository.MaintenanceTaskTypeRepository;
import com.svtrucking.logistics.repository.VehicleRepository;
import jakarta.persistence.EntityNotFoundException;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.List;
import java.util.stream.Collectors;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.cache.annotation.CacheEvict;
import org.springframework.cache.annotation.Cacheable;
import org.springframework.data.domain.*;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
@RequiredArgsConstructor
@Slf4j
public class MaintenanceTaskService {

  private final MaintenanceTaskRepository taskRepo;
  private final MaintenanceTaskTypeRepository typeRepo;
  private final VehicleRepository vehicleRepo;

  /** Get all tasks with keyword search */
  @Cacheable(value = "maintenanceTasks", key = "#keyword + '-' + #page + '-' + #size")
  public Page<MaintenanceTaskDto> getAll(String keyword, int page, int size) {
    log.debug("Fetching maintenance tasks - keyword: {}, page: {}, size: {}", keyword, page, size);
    
    Pageable pageable = PageRequest.of(page, size, Sort.by("createdDate").descending());
    Page<MaintenanceTask> taskPage =
        keyword == null || keyword.isBlank()
            ? taskRepo.findAll(pageable)
            : taskRepo.findByTitleContainingIgnoreCase(keyword, pageable);

    return taskPage.map(MaintenanceTaskDto::fromEntity);
  }

  /** 🔍 Get task by ID */
  public MaintenanceTaskDto getById(Long id) {
    log.debug("Fetching maintenance task by ID: {}", id);
    MaintenanceTask task = findTaskById(id);
    return MaintenanceTaskDto.fromEntity(task);
  }

  /** ➕ Create a new maintenance task */
  @Transactional
  @CacheEvict(value = "maintenanceTasks", allEntries = true)
  public MaintenanceTaskDto create(MaintenanceTaskDto dto) {
    log.info("Creating new maintenance task: {}", dto.getTitle());
    
    validateTaskDto(dto);
    
    MaintenanceTask task = new MaintenanceTask();
    mapDtoToTask(task, dto, true);
    MaintenanceTask saved = taskRepo.save(task);
    
    log.info("Successfully created maintenance task ID: {}", saved.getId());
    return MaintenanceTaskDto.fromEntity(saved);
  }

  /** ✏️ Update existing maintenance task */
  @Transactional
  @CacheEvict(value = "maintenanceTasks", allEntries = true)
  public MaintenanceTaskDto update(Long id, MaintenanceTaskDto dto) {
    log.info("Updating maintenance task ID: {}", id);
    
    validateTaskDto(dto);
    
    MaintenanceTask task = findTaskById(id);
    mapDtoToTask(task, dto, false);
    MaintenanceTask updated = taskRepo.save(task);
    
    log.info("Successfully updated maintenance task ID: {}", id);
    return MaintenanceTaskDto.fromEntity(updated);
  }

  /** 🗑️ Delete a task */
  @Transactional
  @CacheEvict(value = "maintenanceTasks", allEntries = true)
  public void delete(Long id) {
    log.info("Deleting maintenance task ID: {}", id);
    
    if (!taskRepo.existsById(id)) {
      log.error("Cannot delete - task not found: {}", id);
      throw new EntityNotFoundException("Task not found with ID: " + id);
    }
    
    taskRepo.deleteById(id);
    log.info("Successfully deleted maintenance task ID: {}", id);
  }

  /** 🧠 Advanced Filtering */
  public Page<MaintenanceTaskDto> getFilteredTasks(
      String keyword,
      String status,
      LocalDate dueBefore,
      LocalDate dueAfter,
      Long vehicleId,
      int page,
      int size) {
    
    log.debug("Filtering tasks - keyword: {}, status: {}, dueBefore: {}, dueAfter: {}, vehicleId: {}", 
        keyword, status, dueBefore, dueAfter, vehicleId);
    
    Pageable pageable = PageRequest.of(page, size, Sort.by("createdDate").descending());
    Page<MaintenanceTask> filteredPage =
        taskRepo.filterTasks(
            keyword == null ? "" : keyword, status, dueBefore, dueAfter, vehicleId, pageable);
    
    return filteredPage.map(MaintenanceTaskDto::fromEntity);
  }

  /** Get overdue tasks */
  public List<MaintenanceTaskDto> getOverdueTasks() {
    log.debug("Fetching overdue maintenance tasks");
    
    LocalDateTime now = LocalDateTime.now();
    return taskRepo.findAll().stream()
        .filter(task -> task.getDueDate() != null)
        .filter(task -> task.getDueDate().isBefore(now))
        .filter(task -> task.getStatus() != com.svtrucking.logistics.enums.MaintenanceStatus.COMPLETED)
        .map(MaintenanceTaskDto::fromEntity)
        .collect(Collectors.toList());
  }

  /** Get upcoming tasks (due within next N days) */
  public List<MaintenanceTaskDto> getUpcomingTasks(int daysAhead) {
    log.debug("Fetching tasks due in next {} days", daysAhead);
    
    LocalDateTime now = LocalDateTime.now();
    LocalDateTime futureDate = now.plusDays(daysAhead);
    
    return taskRepo.findAll().stream()
        .filter(task -> task.getDueDate() != null)
        .filter(task -> !task.getDueDate().isBefore(now))
        .filter(task -> !task.getDueDate().isAfter(futureDate))
        .filter(task -> task.getStatus() != com.svtrucking.logistics.enums.MaintenanceStatus.COMPLETED)
        .map(MaintenanceTaskDto::fromEntity)
        .collect(Collectors.toList());
  }

  /** Get tasks by vehicle */
  public List<MaintenanceTaskDto> getTasksByVehicle(Long vehicleId) {
    log.debug("Fetching tasks for vehicle ID: {}", vehicleId);
    
    // Validate vehicle exists
    findVehicle(vehicleId);
    
    return taskRepo.findAll().stream()
        .filter(task -> task.getVehicle() != null && task.getVehicle().getId().equals(vehicleId))
        .map(MaintenanceTaskDto::fromEntity)
        .collect(Collectors.toList());
  }

  /** Mark task as completed */
  @Transactional
  @CacheEvict(value = "maintenanceTasks", allEntries = true)
  public MaintenanceTaskDto completeTask(Long id) {
    log.info("Marking task {} as completed", id);
    
    MaintenanceTask task = findTaskById(id);
    task.setStatus(com.svtrucking.logistics.enums.MaintenanceStatus.COMPLETED);
    task.setCompletedAt(LocalDateTime.now());
    
    MaintenanceTask updated = taskRepo.save(task);
    log.info("Task {} marked as completed", id);
    
    return MaintenanceTaskDto.fromEntity(updated);
  }

  /** 🧩 Internal: Reuse common mapping logic */
  private void mapDtoToTask(MaintenanceTask task, MaintenanceTaskDto dto, boolean isNew) {
    task.setTitle(dto.getTitle());
    task.setDescription(dto.getDescription());
    task.setDueDate(dto.getDueDate());
    task.setStatus(dto.getStatus() != null ? dto.getStatus() : com.svtrucking.logistics.enums.MaintenanceStatus.PENDING);
    task.setCompletedAt(dto.getCompletedAt());
    task.setUpdatedDate(LocalDateTime.now());
    
    if (isNew) {
      task.setCreatedDate(LocalDateTime.now());
    }

    // Relationships
    task.setTaskType(findTaskType(dto.getTaskTypeId()));
    task.setVehicle(findVehicle(dto.getVehicleId()));
  }

  /** Validate task DTO */
  private void validateTaskDto(MaintenanceTaskDto dto) {
    if (dto.getTitle() == null || dto.getTitle().trim().isEmpty()) {
      throw new IllegalArgumentException("Task title is required");
    }
    
    if (dto.getTaskTypeId() == null) {
      throw new IllegalArgumentException("Task type is required");
    }
    
    if (dto.getVehicleId() == null) {
      throw new IllegalArgumentException("Vehicle is required");
    }
    
    if (dto.getDueDate() == null) {
      throw new IllegalArgumentException("Due date is required");
    }
  }

  /** 🔍 Helper to get task by ID or throw */
  private MaintenanceTask findTaskById(Long id) {
    return taskRepo.findById(id)
        .orElseThrow(() -> {
          log.error("Maintenance task not found: {}", id);
          return new EntityNotFoundException("Task not found with ID: " + id);
        });
  }

  private MaintenanceTaskType findTaskType(Long id) {
    return typeRepo
        .findById(id)
        .orElseThrow(() -> {
          log.error("Task type not found: {}", id);
          return new EntityNotFoundException("Task type not found with ID: " + id);
        });
  }

  private Vehicle findVehicle(Long id) {
    return vehicleRepo
        .findById(id)
        .orElseThrow(() -> {
          log.error("Vehicle not found: {}", id);
          return new EntityNotFoundException("Vehicle not found with ID: " + id);
        });
  }
}
