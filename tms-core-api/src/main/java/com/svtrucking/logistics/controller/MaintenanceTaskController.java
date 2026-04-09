package com.svtrucking.logistics.controller;

import com.svtrucking.logistics.core.ApiResponse;
import com.svtrucking.logistics.dto.MaintenanceTaskDto;
import com.svtrucking.logistics.service.MaintenanceTaskService;
import jakarta.validation.Valid;
import java.time.LocalDate;
import java.util.List;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.data.domain.Page;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/admin/maintenance-tasks")
@RequiredArgsConstructor
@Slf4j
public class MaintenanceTaskController {

  private final MaintenanceTaskService taskService;

  /** List maintenance tasks with optional filtering */
  @GetMapping
  public ResponseEntity<ApiResponse<Page<MaintenanceTaskDto>>> listTasks(
      @RequestParam(required = false) String keyword,
      @RequestParam(required = false) String status,
      @RequestParam(required = false) Long vehicleId,
      @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE)
          LocalDate dueBefore,
      @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE)
          LocalDate dueAfter,
      @RequestParam(defaultValue = "0") int page,
      @RequestParam(defaultValue = "10") int size) {
    log.info(
        "📄 Fetching tasks with filters: keyword={}, status={}, dueBefore={}, dueAfter={}, vehicleId={}, page={}, size={}",
        keyword,
        status,
        dueBefore,
        dueAfter,
        vehicleId,
        page,
        size);
    Page<MaintenanceTaskDto> pageResult =
        taskService.getFilteredTasks(keyword, status, dueBefore, dueAfter, vehicleId, page, size);
    return ResponseEntity.ok(new ApiResponse<>(true, "Tasks fetched", pageResult));
  }

  /** 🔍 Get single task by ID */
  @GetMapping("/{id}")
  public ResponseEntity<ApiResponse<MaintenanceTaskDto>> getTask(@PathVariable Long id) {
    log.info("🔍 Fetching maintenance task by ID: {}", id);
    MaintenanceTaskDto dto = taskService.getById(id);
    return ResponseEntity.ok(new ApiResponse<>(true, "Task found", dto));
  }

  /** ➕ Create new maintenance task */
  @PostMapping
  public ResponseEntity<ApiResponse<MaintenanceTaskDto>> createTask(
      @Valid @RequestBody MaintenanceTaskDto dto) {
    log.info("➕ Creating maintenance task: {}", dto);
    MaintenanceTaskDto created = taskService.create(dto);
    return ResponseEntity.ok(new ApiResponse<>(true, "Task created", created));
  }

  /** ✏️ Update existing maintenance task */
  @PutMapping("/{id}")
  public ResponseEntity<ApiResponse<MaintenanceTaskDto>> updateTask(
      @PathVariable Long id, @Valid @RequestBody MaintenanceTaskDto dto) {
    log.info("✏️ Updating maintenance task ID {}: {}", id, dto);
    MaintenanceTaskDto updated = taskService.update(id, dto);
    return ResponseEntity.ok(new ApiResponse<>(true, "Task updated", updated));
  }

  /** 🗑️ Delete task by ID */
  @DeleteMapping("/{id}")
  public ResponseEntity<ApiResponse<Void>> deleteTask(@PathVariable Long id) {
    log.warn("🗑️ Deleting maintenance task ID: {}", id);
    taskService.delete(id);
    return ResponseEntity.ok(new ApiResponse<>(true, "Task deleted", null));
  }

  /** Mark task as completed */
  @PostMapping("/{id}/complete")
  public ResponseEntity<ApiResponse<MaintenanceTaskDto>> completeTask(@PathVariable Long id) {
    log.info("Completing maintenance task ID: {}", id);
    MaintenanceTaskDto completed = taskService.completeTask(id);
    return ResponseEntity.ok(new ApiResponse<>(true, "Task completed", completed));
  }

  /** ⚠️ Get all overdue tasks */
  @GetMapping("/overdue")
  public ResponseEntity<ApiResponse<List<MaintenanceTaskDto>>> getOverdueTasks() {
    log.info("⚠️ Fetching overdue maintenance tasks");
    List<MaintenanceTaskDto> tasks = taskService.getOverdueTasks();
    return ResponseEntity.ok(new ApiResponse<>(true, "Overdue tasks retrieved", tasks));
  }

  /** 📅 Get upcoming tasks within specified days */
  @GetMapping("/upcoming")
  public ResponseEntity<ApiResponse<List<MaintenanceTaskDto>>> getUpcomingTasks(
      @RequestParam(defaultValue = "7") int days) {
    log.info("📅 Fetching tasks due in next {} days", days);
    List<MaintenanceTaskDto> tasks = taskService.getUpcomingTasks(days);
    return ResponseEntity.ok(new ApiResponse<>(true, "Upcoming tasks retrieved", tasks));
  }

  /** 🚚 Get all tasks for a specific vehicle */
  @GetMapping("/vehicle/{vehicleId}")
  public ResponseEntity<ApiResponse<List<MaintenanceTaskDto>>> getTasksByVehicle(
      @PathVariable Long vehicleId) {
    log.info("🚚 Fetching tasks for vehicle ID: {}", vehicleId);
    List<MaintenanceTaskDto> tasks = taskService.getTasksByVehicle(vehicleId);
    return ResponseEntity.ok(new ApiResponse<>(true, "Vehicle tasks retrieved", tasks));
  }
}
