package com.svtrucking.logistics.controller;

import com.svtrucking.logistics.core.ApiResponse;
import com.svtrucking.logistics.dto.*;
import com.svtrucking.logistics.enums.TaskStatus;
import com.svtrucking.logistics.service.TaskService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.domain.Sort;
import org.springframework.data.web.PageableDefault;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.validation.annotation.Validated;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;
import org.springframework.web.util.UriComponentsBuilder;

import java.net.URI;
import java.util.List;

/**
 * REST Controller for unified task management
 * Handles all task types: standalone, incident tasks, work order tasks, vehicle tasks, etc.
 */
@RestController
@RequestMapping("/api/tasks")
@RequiredArgsConstructor
@Validated
@CrossOrigin(origins = "*")
@Slf4j
public class TaskController {

  private final TaskService taskService;

  // ════════════════════════════════════════════════════════════════
  // TASK CRUD OPERATIONS
  // ════════════════════════════════════════════════════════════════

  /**
   * Create a new task
   * POST /api/tasks
   */
  @PostMapping(produces = MediaType.APPLICATION_JSON_VALUE)
  @PreAuthorize("hasAuthority('task:create') or hasAuthority('all_functions') or hasRole('SUPERADMIN')")
  public ResponseEntity<ApiResponse<TaskDto>> createTask(
      @Valid @RequestBody TaskDto taskDto,
      UriComponentsBuilder uriBuilder) {
    
    TaskDto created = taskService.createTask(taskDto);
    
    URI location = uriBuilder.path("/api/tasks/{id}")
        .buildAndExpand(created.getId())
        .toUri();
    
    return ResponseEntity.created(location)
        .body(new ApiResponse<>(true, "Task created successfully", created));
  }

  /**
   * Get task by ID
   * GET /api/tasks/{id}
   */
  @GetMapping(value = "/{id}", produces = MediaType.APPLICATION_JSON_VALUE)
  @PreAuthorize("hasAuthority('task:read') or hasAuthority('all_functions') or hasRole('SUPERADMIN')")
  public ResponseEntity<ApiResponse<TaskDto>> getTaskById(@PathVariable Long id) {
    TaskDto task = taskService.getTaskById(id);
    return ResponseEntity.ok(new ApiResponse<>(true, "Task retrieved successfully", task));
  }

  /**
   * Update task
   * PUT /api/tasks/{id}
   */
  @PutMapping(value = "/{id}", produces = MediaType.APPLICATION_JSON_VALUE)
  @PreAuthorize("hasAuthority('task:update') or hasAuthority('all_functions') or hasRole('SUPERADMIN')")
  public ResponseEntity<ApiResponse<TaskDto>> updateTask(
      @PathVariable Long id,
      @Valid @RequestBody TaskDto taskDto) {
    
    TaskDto updated = taskService.updateTask(id, taskDto);
    return ResponseEntity.ok(new ApiResponse<>(true, "Task updated successfully", updated));
  }

  /**
   * Delete task (soft delete)
   * DELETE /api/tasks/{id}
   */
  @DeleteMapping(value = "/{id}", produces = MediaType.APPLICATION_JSON_VALUE)
  @PreAuthorize("hasAuthority('task:delete') or hasAuthority('all_functions') or hasRole('SUPERADMIN')")
  public ResponseEntity<ApiResponse<Void>> deleteTask(@PathVariable Long id) {
    taskService.deleteTask(id);
    return ResponseEntity.ok(new ApiResponse<>(true, "Task deleted successfully", null));
  }

  /**
   * Complete task
   * POST /api/tasks/{id}/complete
   */
  @PostMapping(value = "/{id}/complete", produces = MediaType.APPLICATION_JSON_VALUE)
  @PreAuthorize("hasAuthority('task:update') or hasAuthority('all_functions') or hasRole('SUPERADMIN')")
  public ResponseEntity<ApiResponse<TaskDto>> completeTask(@PathVariable Long id) {
    TaskDto completed = taskService.completeTask(id);
    return ResponseEntity.ok(new ApiResponse<>(true, "Task completed successfully", completed));
  }

  /**
   * Assign/unassign task to a user
   * POST /api/tasks/{id}/assign
   */
  @PostMapping(value = "/{id}/assign", produces = MediaType.APPLICATION_JSON_VALUE)
  @PreAuthorize("hasAuthority('task:update') or hasAuthority('all_functions') or hasRole('SUPERADMIN')")
  public ResponseEntity<ApiResponse<TaskDto>> assignTask(
      @PathVariable Long id,
      @RequestBody AssignRequest request) {
    TaskDto updated = taskService.assignTask(id, request.userId());
    return ResponseEntity.ok(new ApiResponse<>(true, "Task assignment updated", updated));
  }

  public record AssignRequest(Long userId) {}

  /**
   * Update task status
   * PUT /api/tasks/{id}/status
   */
  @PutMapping(value = "/{id}/status", produces = MediaType.APPLICATION_JSON_VALUE)
  @PreAuthorize("hasAuthority('task:update') or hasAuthority('all_functions') or hasRole('SUPERADMIN')")
  public ResponseEntity<ApiResponse<TaskDto>> updateStatus(
      @PathVariable Long id, @RequestBody StatusRequest request) {
    TaskDto updated = taskService.updateStatus(id, request.status());
    return ResponseEntity.ok(new ApiResponse<>(true, "Task status updated", updated));
  }

  public record StatusRequest(TaskStatus status) {}

  // ════════════════════════════════════════════════════════════════
  // TASK QUERIES & FILTERING
  // ════════════════════════════════════════════════════════════════

  /**
   * Get all tasks with filtering and pagination
   * GET /api/tasks
   */
  @GetMapping(produces = MediaType.APPLICATION_JSON_VALUE)
  @PreAuthorize("hasAuthority('task:read') or hasAuthority('all_functions') or hasRole('SUPERADMIN')")
  public ResponseEntity<ApiResponse<Page<TaskDto>>> getTasks(
      @ModelAttribute TaskFilterDto filter) {
    
    Page<TaskDto> tasks = taskService.getTasks(filter);
    return ResponseEntity.ok(new ApiResponse<>(true, "Tasks retrieved successfully", tasks));
  }

  /**
   * Get tasks for specific entity (e.g., all tasks for work order #567)
   * GET /api/tasks/entity/{relationType}/{relationId}
   * Example: GET /api/tasks/entity/WORK_ORDER/567
   */
  @GetMapping(value = "/entity/{relationType}/{relationId}", produces = MediaType.APPLICATION_JSON_VALUE)
  @PreAuthorize("hasAuthority('task:read') or hasAuthority('all_functions') or hasRole('SUPERADMIN')")
  public ResponseEntity<ApiResponse<List<TaskDto>>> getTasksForEntity(
      @PathVariable String relationType,
      @PathVariable Long relationId) {
    
    List<TaskDto> tasks = taskService.getTasksForEntity(relationType, relationId);
    return ResponseEntity.ok(new ApiResponse<>(true, "Tasks retrieved successfully", tasks));
  }

  /**
   * Get standalone tasks (not related to any entity)
   * GET /api/tasks/standalone
   */
  @GetMapping(value = "/standalone", produces = MediaType.APPLICATION_JSON_VALUE)
  @PreAuthorize("hasAuthority('task:read') or hasAuthority('all_functions') or hasRole('SUPERADMIN')")
  public ResponseEntity<ApiResponse<Page<TaskDto>>> getStandaloneTasks(
      @PageableDefault(size = 20, sort = "createdAt", direction = Sort.Direction.DESC) Pageable pageable) {
    
    Page<TaskDto> tasks = taskService.getStandaloneTasks(pageable);
    return ResponseEntity.ok(new ApiResponse<>(true, "Standalone tasks retrieved successfully", tasks));
  }

  /**
   * Get my tasks (assigned to current user)
   * GET /api/tasks/my-tasks
   */
  @GetMapping(value = "/my-tasks", produces = MediaType.APPLICATION_JSON_VALUE)
  @PreAuthorize("hasAuthority('task:read') or hasAuthority('all_functions') or hasRole('SUPERADMIN')")
  public ResponseEntity<ApiResponse<Page<TaskDto>>> getMyTasks(
      @PageableDefault(size = 20, sort = "dueDate", direction = Sort.Direction.ASC) Pageable pageable) {
    
    Page<TaskDto> tasks = taskService.getMyTasks(pageable);
    return ResponseEntity.ok(new ApiResponse<>(true, "My tasks retrieved successfully", tasks));
  }

  /**
   * Get overdue tasks
   * GET /api/tasks/overdue
   */
  @GetMapping(value = "/overdue", produces = MediaType.APPLICATION_JSON_VALUE)
  @PreAuthorize("hasAuthority('task:read') or hasAuthority('all_functions') or hasRole('SUPERADMIN')")
  public ResponseEntity<ApiResponse<List<TaskDto>>> getOverdueTasks() {
    List<TaskDto> tasks = taskService.getOverdueTasks();
    return ResponseEntity.ok(new ApiResponse<>(true, "Overdue tasks retrieved successfully", tasks));
  }

  /**
   * Get task statistics
   * GET /api/tasks/statistics
   */
  @GetMapping(value = "/statistics", produces = MediaType.APPLICATION_JSON_VALUE)
  @PreAuthorize("hasAuthority('task:read') or hasAuthority('all_functions') or hasRole('SUPERADMIN')")
  public ResponseEntity<ApiResponse<TaskStatisticsDto>> getStatistics() {
    TaskStatisticsDto stats = taskService.getStatistics();
    return ResponseEntity.ok(new ApiResponse<>(true, "Statistics retrieved successfully", stats));
  }

  // ════════════════════════════════════════════════════════════════
  // COMMENTS
  // ════════════════════════════════════════════════════════════════

  /**
   * Add comment to task
   * POST /api/tasks/{taskId}/comments
   */
  @PostMapping(value = "/{taskId}/comments", produces = MediaType.APPLICATION_JSON_VALUE)
  @PreAuthorize("hasAuthority('task:comment') or hasAuthority('all_functions') or hasRole('SUPERADMIN')")
  public ResponseEntity<ApiResponse<TaskCommentDto>> addComment(
      @PathVariable Long taskId,
      @Valid @RequestBody TaskCommentDto commentDto) {
    
    TaskCommentDto created = taskService.addComment(taskId, commentDto);
    return ResponseEntity.ok(new ApiResponse<>(true, "Comment added successfully", created));
  }

  /**
   * Get comments for task
   * GET /api/tasks/{taskId}/comments
   */
  @GetMapping(value = "/{taskId}/comments", produces = MediaType.APPLICATION_JSON_VALUE)
  @PreAuthorize("hasAuthority('task:read') or hasAuthority('all_functions') or hasRole('SUPERADMIN')")
  public ResponseEntity<ApiResponse<List<TaskCommentDto>>> getComments(@PathVariable Long taskId) {
    List<TaskCommentDto> comments = taskService.getComments(taskId);
    return ResponseEntity.ok(new ApiResponse<>(true, "Comments retrieved successfully", comments));
  }

  // ════════════════════════════════════════════════════════════════
  // ATTACHMENTS
  // ════════════════════════════════════════════════════════════════

  /**
   * Add attachment to task
   * POST /api/tasks/{taskId}/attachments
   */
  @PostMapping(
      value = "/{taskId}/attachments",
      consumes = MediaType.MULTIPART_FORM_DATA_VALUE,
      produces = MediaType.APPLICATION_JSON_VALUE)
  @PreAuthorize("hasAuthority('task:update') or hasAuthority('all_functions') or hasRole('SUPERADMIN')")
  public ResponseEntity<ApiResponse<TaskAttachmentDto>> uploadAttachment(
      @PathVariable Long taskId,
      @RequestPart("file") MultipartFile file,
      @RequestParam(value = "description", required = false) String description) {

    TaskAttachmentDto created = taskService.uploadAttachment(taskId, file, description);
    return ResponseEntity.ok(new ApiResponse<>(true, "Attachment uploaded successfully", created));
  }

  /**
   * Add attachment metadata to task (legacy JSON endpoint)
   */
  @PostMapping(
      value = "/{taskId}/attachments/metadata",
      consumes = MediaType.APPLICATION_JSON_VALUE,
      produces = MediaType.APPLICATION_JSON_VALUE)
  @PreAuthorize("hasAuthority('task:update') or hasAuthority('all_functions') or hasRole('SUPERADMIN')")
  public ResponseEntity<ApiResponse<TaskAttachmentDto>> addAttachment(
      @PathVariable Long taskId,
      @Valid @RequestBody TaskAttachmentDto attachmentDto) {
    
    TaskAttachmentDto created = taskService.addAttachment(taskId, attachmentDto);
    return ResponseEntity.ok(new ApiResponse<>(true, "Attachment added successfully", created));
  }

  /**
   * Get attachments for task
   * GET /api/tasks/{taskId}/attachments
   */
  @GetMapping(value = "/{taskId}/attachments", produces = MediaType.APPLICATION_JSON_VALUE)
  @PreAuthorize("hasAuthority('task:read') or hasAuthority('all_functions') or hasRole('SUPERADMIN')")
  public ResponseEntity<ApiResponse<List<TaskAttachmentDto>>> getAttachments(@PathVariable Long taskId) {
    List<TaskAttachmentDto> attachments = taskService.getAttachments(taskId);
    return ResponseEntity.ok(new ApiResponse<>(true, "Attachments retrieved successfully", attachments));
  }

  // ════════════════════════════════════════════════════════════════
  // TAGS
  // ════════════════════════════════════════════════════════════════

  /**
   * Add tag to task
   * POST /api/tasks/{taskId}/tags/{tagId}
   */
  @PostMapping(value = "/{taskId}/tags/{tagId}", produces = MediaType.APPLICATION_JSON_VALUE)
  @PreAuthorize("hasAuthority('task:update') or hasAuthority('all_functions') or hasRole('SUPERADMIN')")
  public ResponseEntity<ApiResponse<Void>> addTag(
      @PathVariable Long taskId,
      @PathVariable Long tagId) {
    
    taskService.addTagToTask(taskId, tagId);
    return ResponseEntity.ok(new ApiResponse<>(true, "Tag added successfully", null));
  }

  /**
   * Remove tag from task
   * DELETE /api/tasks/{taskId}/tags/{tagId}
   */
  @DeleteMapping(value = "/{taskId}/tags/{tagId}", produces = MediaType.APPLICATION_JSON_VALUE)
  @PreAuthorize("hasAuthority('task:update') or hasAuthority('all_functions') or hasRole('SUPERADMIN')")
  public ResponseEntity<ApiResponse<Void>> removeTag(
      @PathVariable Long taskId,
      @PathVariable Long tagId) {
    
    taskService.removeTagFromTask(taskId, tagId);
    return ResponseEntity.ok(new ApiResponse<>(true, "Tag removed successfully", null));
  }

  // ════════════════════════════════════════════════════════════════
  // WATCHERS
  // ════════════════════════════════════════════════════════════════

  /**
   * Add watcher to task
   * POST /api/tasks/{taskId}/watchers/{userId}
   */
  @PostMapping(value = "/{taskId}/watchers/{userId}", produces = MediaType.APPLICATION_JSON_VALUE)
  @PreAuthorize("hasAuthority('task:update') or hasAuthority('all_functions') or hasRole('SUPERADMIN')")
  public ResponseEntity<ApiResponse<Void>> addWatcher(
      @PathVariable Long taskId,
      @PathVariable Long userId) {
    
    taskService.addWatcher(taskId, userId);
    return ResponseEntity.ok(new ApiResponse<>(true, "Watcher added successfully", null));
  }

  /**
   * Remove watcher from task
   * DELETE /api/tasks/{taskId}/watchers/{userId}
   */
  @DeleteMapping(value = "/{taskId}/watchers/{userId}", produces = MediaType.APPLICATION_JSON_VALUE)
  @PreAuthorize("hasAuthority('task:update') or hasAuthority('all_functions') or hasRole('SUPERADMIN')")
  public ResponseEntity<ApiResponse<Void>> removeWatcher(
      @PathVariable Long taskId,
      @PathVariable Long userId) {
    
    taskService.removeWatcher(taskId, userId);
    return ResponseEntity.ok(new ApiResponse<>(true, "Watcher removed successfully", null));
  }

  // ════════════════════════════════════════════════════════════════
  // ACTIVITY LOGS
  // ════════════════════════════════════════════════════════════════

  /**
   * Get activity logs for task
   * GET /api/tasks/{taskId}/activity
   */
  @GetMapping(value = "/{taskId}/activity", produces = MediaType.APPLICATION_JSON_VALUE)
  @PreAuthorize("hasAuthority('task:read') or hasAuthority('all_functions') or hasRole('SUPERADMIN')")
  public ResponseEntity<ApiResponse<List<TaskActivityLogDto>>> getActivityLogs(@PathVariable Long taskId) {
    List<TaskActivityLogDto> logs = taskService.getActivityLogs(taskId);
    return ResponseEntity.ok(new ApiResponse<>(true, "Activity logs retrieved successfully", logs));
  }
}
