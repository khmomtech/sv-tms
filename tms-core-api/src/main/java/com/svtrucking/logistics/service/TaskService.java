package com.svtrucking.logistics.service;

import com.svtrucking.logistics.dto.*;
import com.svtrucking.logistics.enums.TaskPriority;
import com.svtrucking.logistics.enums.TaskStatus;
import com.svtrucking.logistics.exception.ResourceNotFoundException;
import com.svtrucking.logistics.model.*;
import com.svtrucking.logistics.repository.*;
import com.svtrucking.logistics.security.SecurityUtils;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.data.domain.Sort;
import org.springframework.data.jpa.domain.Specification;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.multipart.MultipartFile;

import jakarta.persistence.criteria.Predicate;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.*;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
@Slf4j
@Transactional
public class TaskService {

  private final TaskRepository taskRepository;
  private final TaskCommentRepository taskCommentRepository;
  private final TaskAttachmentRepository taskAttachmentRepository;
  private final TaskTagRepository taskTagRepository;
  private final TaskActivityLogRepository taskActivityLogRepository;
  private final UserRepository userRepository;
  private final FileStorageService fileStorageService;

  // ════════════════════════════════════════════════════════════════
  // TASK CRUD OPERATIONS
  // ════════════════════════════════════════════════════════════════

  /**
   * Create a new task
   */
  public TaskDto createTask(TaskDto dto) {
    User currentUser = getCurrentUser();

    Task task = Task.builder()
        .code(generateTaskCode())
        .title(dto.getTitle())
        .description(dto.getDescription())
        .status(dto.getStatus() != null ? dto.getStatus() : TaskStatus.OPEN)
        .priority(dto.getPriority() != null ? dto.getPriority() : TaskPriority.MEDIUM)
        .team(dto.getTeam())
        .department(dto.getDepartment())
        .relationType(dto.getRelationType())
        .relationId(dto.getRelationId())
        .dueDate(dto.getDueDate())
        .startDate(dto.getStartDate())
        .estimatedMinutes(dto.getEstimatedMinutes())
        .isUrgent(dto.getIsUrgent() != null ? dto.getIsUrgent() : false)
        .isRecurring(dto.getIsRecurring() != null ? dto.getIsRecurring() : false)
        .createdBy(currentUser)
        .build();

    // Set assigned user if provided
    if (dto.getAssignedToId() != null) {
      User assignedUser = userRepository.findById(dto.getAssignedToId())
          .orElseThrow(() -> new ResourceNotFoundException("User not found with id: " + dto.getAssignedToId()));
      task.setAssignedTo(assignedUser);
    }

    // Set parent task if provided
    if (dto.getParentTaskId() != null) {
      Task parentTask = taskRepository.findById(dto.getParentTaskId())
          .orElseThrow(() -> new ResourceNotFoundException("Parent task not found with id: " + dto.getParentTaskId()));
      task.setParentTask(parentTask);
    }

    Task savedTask = taskRepository.save(task);

    // Log activity
    logActivity(savedTask, "CREATED", "Task created: " + savedTask.getTitle(), currentUser);

    log.info("Task created: {} by user: {}", savedTask.getCode(), currentUser.getUsername());
    return toDto(savedTask);
  }

  /**
   * Update an existing task
   */
  public TaskDto updateTask(Long id, TaskDto dto) {
    Task task = findTaskById(id);
    User currentUser = getCurrentUser();

    // Track changes for activity log
    Map<String, Object> changes = new HashMap<>();

    if (dto.getTitle() != null && !dto.getTitle().equals(task.getTitle())) {
      changes.put("title", Map.of("old", task.getTitle(), "new", dto.getTitle()));
      task.setTitle(dto.getTitle());
    }

    if (dto.getDescription() != null) {
      task.setDescription(dto.getDescription());
    }

    if (dto.getStatus() != null && dto.getStatus() != task.getStatus()) {
      changes.put("status", Map.of("old", task.getStatus(), "new", dto.getStatus()));
      task.setStatus(dto.getStatus());
      
      if (dto.getStatus() == TaskStatus.COMPLETED) {
        task.setCompletedAt(LocalDateTime.now());
        task.setCompletedBy(currentUser);
        task.setProgressPercentage(100);
      }
    }

    if (dto.getPriority() != null && dto.getPriority() != task.getPriority()) {
      changes.put("priority", Map.of("old", task.getPriority(), "new", dto.getPriority()));
      task.setPriority(dto.getPriority());
    }

    if (dto.getAssignedToId() != null) {
      User assignedUser = userRepository.findById(dto.getAssignedToId())
          .orElseThrow(() -> new ResourceNotFoundException("User not found with id: " + dto.getAssignedToId()));
      if (!assignedUser.equals(task.getAssignedTo())) {
        changes.put("assignee", Map.of("old", task.getAssignedTo() != null ? task.getAssignedTo().getUsername() : "none", 
                                       "new", assignedUser.getUsername()));
        task.setAssignedTo(assignedUser);
      }
    }

    if (dto.getDueDate() != null) {
      task.setDueDate(dto.getDueDate());
    }

    if (dto.getEstimatedMinutes() != null) {
      task.setEstimatedMinutes(dto.getEstimatedMinutes());
    }

    if (dto.getActualMinutes() != null) {
      task.setActualMinutes(dto.getActualMinutes());
    }

    if (dto.getProgressPercentage() != null) {
      task.setProgressPercentage(dto.getProgressPercentage());
    }

    if (dto.getIsUrgent() != null) {
      task.setIsUrgent(dto.getIsUrgent());
    }

    Task updatedTask = taskRepository.save(task);

    // Log changes
    if (!changes.isEmpty()) {
      TaskActivityLog activityLog = TaskActivityLog.builder()
          .task(updatedTask)
          .action("UPDATED")
          .message("Task updated: " + String.join(", ", changes.keySet()))
          .user(currentUser)
          .metadata(changes)
          .build();
      taskActivityLogRepository.save(activityLog);
    }

    log.info("Task updated: {} by user: {}", updatedTask.getCode(), currentUser.getUsername());
    return toDto(updatedTask);
  }

  /**
   * Assign or unassign a task to a user
   */
  @Transactional
  public TaskDto assignTask(Long taskId, Long userId) {
    User currentUser = getCurrentUser();
    Task task = taskRepository.findById(taskId)
        .orElseThrow(() -> new ResourceNotFoundException("Task not found with id: " + taskId));

    User newAssignee = null;
    if (userId != null) {
      newAssignee = userRepository.findById(userId)
          .orElseThrow(() -> new ResourceNotFoundException("User not found with id: " + userId));
    }

    User previousAssignee = task.getAssignedTo();
    if ((previousAssignee == null && newAssignee == null) ||
        (previousAssignee != null && previousAssignee.equals(newAssignee))) {
      return toDto(task); // no change
    }

    task.setAssignedTo(newAssignee);
    Task saved = taskRepository.save(task);

    String message = newAssignee == null
        ? "Task unassigned"
        : "Assigned to " + newAssignee.getUsername();
    logActivity(saved, "ASSIGNEE_UPDATED", message, currentUser);

    return toDto(saved);
  }

  /**
   * Get task by ID
   */
  @Transactional(readOnly = true)
  public TaskDto getTaskById(Long id) {
    Task task = findTaskById(id);
    return toDto(task);
  }

  /**
   * Delete task (soft delete)
   */
  public void deleteTask(Long id) {
    Task task = findTaskById(id);
    User currentUser = getCurrentUser();

    task.setIsDeleted(true);
    taskRepository.save(task);

    logActivity(task, "DELETED", "Task deleted", currentUser);
    log.info("Task deleted: {} by user: {}", task.getCode(), currentUser.getUsername());
  }

  /**
   * Mark task as completed
   */
  public TaskDto completeTask(Long id) {
    Task task = findTaskById(id);
    User currentUser = getCurrentUser();

    task.markCompleted(currentUser);
    Task completedTask = taskRepository.save(task);

    logActivity(completedTask, "COMPLETED", "Task completed", currentUser);
    log.info("Task completed: {} by user: {}", completedTask.getCode(), currentUser.getUsername());

    // Update parent task progress if exists
    if (task.getParentTask() != null) {
      task.getParentTask().recalculateProgress();
      taskRepository.save(task.getParentTask());
    }

    return toDto(completedTask);
  }

  /**
   * Update status only (lightweight endpoint)
   */
  public TaskDto updateStatus(Long id, TaskStatus status) {
    if (status == null) {
      throw new IllegalArgumentException("Status is required");
    }
    Task task = findTaskById(id);
    User currentUser = getCurrentUser();
    TaskStatus previous = task.getStatus();

    task.setStatus(status);
    if (status == TaskStatus.COMPLETED) {
      task.markCompleted(currentUser);
    }

    Task saved = taskRepository.save(task);

    if (previous != status) {
      logActivity(saved, "STATUS_UPDATED", "Status changed to " + status.name(), currentUser);
    }

    return toDto(saved);
  }

  // ════════════════════════════════════════════════════════════════
  // TASK QUERIES & FILTERING
  // ════════════════════════════════════════════════════════════════

  /**
   * Get all tasks with filtering and pagination
   */
  @Transactional(readOnly = true)
  public Page<TaskDto> getTasks(TaskFilterDto filter) {
    Pageable pageable = createPageable(filter);
    Specification<Task> spec = createSpecification(filter);

    Page<Task> taskPage = taskRepository.findAll(spec, pageable);
    return taskPage.map(this::toDto);
  }

  /**
   * Get tasks for specific entity (e.g., all tasks for a work order)
   */
  @Transactional(readOnly = true)
  public List<TaskDto> getTasksForEntity(String relationType, Long relationId) {
    List<Task> tasks = taskRepository.findByRelationTypeAndRelationIdAndIsDeletedFalse(relationType, relationId);
    return tasks.stream().map(this::toDto).collect(Collectors.toList());
  }

  /**
   * Get standalone tasks (not related to any entity)
   */
  @Transactional(readOnly = true)
  public Page<TaskDto> getStandaloneTasks(Pageable pageable) {
    Page<Task> tasks = taskRepository.findByRelationTypeIsNullAndIsDeletedFalse(pageable);
    return tasks.map(this::toDto);
  }

  /**
   * Get tasks assigned to user
   */
  @Transactional(readOnly = true)
  public Page<TaskDto> getMyTasks(Pageable pageable) {
    User currentUser = getCurrentUser();
    Page<Task> tasks = taskRepository.findByAssignedToIdAndIsDeletedFalse(currentUser.getId(), pageable);
    return tasks.map(this::toDto);
  }

  /**
   * Get overdue tasks
   */
  @Transactional(readOnly = true)
  public List<TaskDto> getOverdueTasks() {
    List<TaskStatus> completedStatuses = Arrays.asList(TaskStatus.COMPLETED, TaskStatus.CANCELLED);
    List<Task> tasks = taskRepository.findOverdueTasks(LocalDateTime.now(), completedStatuses);
    return tasks.stream().map(this::toDto).collect(Collectors.toList());
  }

  /**
   * Get task statistics
   */
  @Transactional(readOnly = true)
  public TaskStatisticsDto getStatistics() {
    User currentUser = getCurrentUser();
    
    return TaskStatisticsDto.builder()
        .totalTasks(taskRepository.countByIsDeletedFalse())
        .openTasks(taskRepository.countByStatusAndIsDeletedFalse(TaskStatus.OPEN))
        .inProgressTasks(taskRepository.countByStatusAndIsDeletedFalse(TaskStatus.IN_PROGRESS))
        .completedTasks(taskRepository.countByStatusAndIsDeletedFalse(TaskStatus.COMPLETED))
        .blockedTasks(taskRepository.countByStatusAndIsDeletedFalse(TaskStatus.BLOCKED))
        .onHoldTasks(taskRepository.countByStatusAndIsDeletedFalse(TaskStatus.ON_HOLD))
        .inReviewTasks(taskRepository.countByStatusAndIsDeletedFalse(TaskStatus.IN_REVIEW))
        .cancelledTasks(taskRepository.countByStatusAndIsDeletedFalse(TaskStatus.CANCELLED))
        .criticalPriorityTasks(taskRepository.countByPriorityAndIsDeletedFalse(TaskPriority.CRITICAL))
        .highPriorityTasks(taskRepository.countByPriorityAndIsDeletedFalse(TaskPriority.HIGH))
        .mediumPriorityTasks(taskRepository.countByPriorityAndIsDeletedFalse(TaskPriority.MEDIUM))
        .lowPriorityTasks(taskRepository.countByPriorityAndIsDeletedFalse(TaskPriority.LOW))
        .overdueTasks(taskRepository.countOverdueTasks(LocalDateTime.now(), 
            Arrays.asList(TaskStatus.COMPLETED, TaskStatus.CANCELLED)))
        .tasksAssignedToMe(taskRepository.countByAssignedToIdAndIsDeletedFalse(currentUser.getId()))
        .tasksCreatedByMe(taskRepository.countByCreatedByIdAndIsDeletedFalse(currentUser.getId()))
        .tasksWatchedByMe(taskRepository.countTasksWatchedByUser(currentUser.getId()))
        .standaloneTasks(taskRepository.countByRelationTypeIsNullAndIsDeletedFalse())
        .build();
  }

  // ════════════════════════════════════════════════════════════════
  // COMMENTS
  // ════════════════════════════════════════════════════════════════

  /**
   * Add comment to task
   */
  public TaskCommentDto addComment(Long taskId, TaskCommentDto dto) {
    Task task = findTaskById(taskId);
    User currentUser = getCurrentUser();

    TaskComment comment = TaskComment.builder()
        .task(task)
        .author(currentUser)
        .content(dto.getContent())
        .isInternal(dto.getIsInternal() != null ? dto.getIsInternal() : false)
        .build();

    if (dto.getParentCommentId() != null) {
      TaskComment parentComment = taskCommentRepository.findById(dto.getParentCommentId())
          .orElseThrow(() -> new ResourceNotFoundException("Parent comment not found"));
      comment.setParentComment(parentComment);
    }

    TaskComment savedComment = taskCommentRepository.save(comment);

    logActivity(task, "COMMENTED", "Comment added", currentUser);
    log.info("Comment added to task: {} by user: {}", task.getCode(), currentUser.getUsername());

    return toCommentDto(savedComment);
  }

  /**
   * Get comments for task
   */
  @Transactional(readOnly = true)
  public List<TaskCommentDto> getComments(Long taskId) {
    List<TaskComment> comments = taskCommentRepository.findByTaskIdAndIsDeletedFalseOrderByCreatedAtAsc(taskId);
    return comments.stream().map(this::toCommentDto).collect(Collectors.toList());
  }

  // ════════════════════════════════════════════════════════════════
  // ATTACHMENTS
  // ════════════════════════════════════════════════════════════════

  /**
   * Add attachment to task
   */
  public TaskAttachmentDto uploadAttachment(Long taskId, MultipartFile file, String description) {
    if (file == null || file.isEmpty()) {
      throw new IllegalArgumentException("File is required");
    }

    String fileUrl = fileStorageService.storeFileInSubfolder(file, "tasks/" + taskId);
    TaskAttachmentDto dto = TaskAttachmentDto.builder()
        .fileName(file.getOriginalFilename() != null ? file.getOriginalFilename() : "attachment")
        .fileUrl(fileUrl)
        .mimeType(file.getContentType())
        .fileSizeBytes(file.getSize())
        .description(description)
        .build();

    return addAttachment(taskId, dto);
  }

  /**
   * Add attachment metadata to task (legacy/internal).
   */
  public TaskAttachmentDto addAttachment(Long taskId, TaskAttachmentDto dto) {
    Task task = findTaskById(taskId);
    User currentUser = getCurrentUser();

    TaskAttachment attachment = TaskAttachment.builder()
        .task(task)
        .fileName(dto.getFileName())
        .fileUrl(dto.getFileUrl())
        .mimeType(dto.getMimeType())
        .fileSizeBytes(dto.getFileSizeBytes())
        .description(dto.getDescription())
        .uploadedBy(currentUser)
        .build();

    TaskAttachment savedAttachment = taskAttachmentRepository.save(attachment);

    logActivity(task, "ATTACHMENT_ADDED", "Attachment added: " + dto.getFileName(), currentUser);
    log.info("Attachment added to task: {} by user: {}", task.getCode(), currentUser.getUsername());

    return toAttachmentDto(savedAttachment);
  }

  /**
   * Get attachments for task
   */
  @Transactional(readOnly = true)
  public List<TaskAttachmentDto> getAttachments(Long taskId) {
    List<TaskAttachment> attachments = taskAttachmentRepository.findByTaskIdAndIsDeletedFalseOrderByUploadedAtDesc(taskId);
    return attachments.stream().map(this::toAttachmentDto).collect(Collectors.toList());
  }

  // ════════════════════════════════════════════════════════════════
  // TAGS
  // ════════════════════════════════════════════════════════════════

  /**
   * Add tag to task
   */
  public void addTagToTask(Long taskId, Long tagId) {
    Task task = findTaskById(taskId);
    TaskTag tag = taskTagRepository.findById(tagId)
        .orElseThrow(() -> new ResourceNotFoundException("Tag not found with id: " + tagId));

    task.addTag(tag);
    taskRepository.save(task);

    logActivity(task, "TAG_ADDED", "Tag added: " + tag.getName(), getCurrentUser());
  }

  /**
   * Remove tag from task
   */
  public void removeTagFromTask(Long taskId, Long tagId) {
    Task task = findTaskById(taskId);
    TaskTag tag = taskTagRepository.findById(tagId)
        .orElseThrow(() -> new ResourceNotFoundException("Tag not found with id: " + tagId));

    task.removeTag(tag);
    taskRepository.save(task);

    logActivity(task, "TAG_REMOVED", "Tag removed: " + tag.getName(), getCurrentUser());
  }

  // ════════════════════════════════════════════════════════════════
  // WATCHERS
  // ════════════════════════════════════════════════════════════════

  /**
   * Add watcher to task
   */
  public void addWatcher(Long taskId, Long userId) {
    Task task = findTaskById(taskId);
    User user = userRepository.findById(userId)
        .orElseThrow(() -> new ResourceNotFoundException("User not found with id: " + userId));

    task.addWatcher(user);
    taskRepository.save(task);

    logActivity(task, "WATCHER_ADDED", "Watcher added: " + user.getUsername(), getCurrentUser());
  }

  /**
   * Remove watcher from task
   */
  public void removeWatcher(Long taskId, Long userId) {
    Task task = findTaskById(taskId);
    User user = userRepository.findById(userId)
        .orElseThrow(() -> new ResourceNotFoundException("User not found with id: " + userId));

    task.removeWatcher(user);
    taskRepository.save(task);

    logActivity(task, "WATCHER_REMOVED", "Watcher removed: " + user.getUsername(), getCurrentUser());
  }

  // ════════════════════════════════════════════════════════════════
  // ACTIVITY LOGS
  // ════════════════════════════════════════════════════════════════

  /**
   * Get activity logs for task
   */
  @Transactional(readOnly = true)
  public List<TaskActivityLogDto> getActivityLogs(Long taskId) {
    List<TaskActivityLog> logs = taskActivityLogRepository.findByTaskIdOrderByCreatedAtDesc(taskId);
    return logs.stream().map(this::toActivityLogDto).collect(Collectors.toList());
  }

  // ════════════════════════════════════════════════════════════════
  // HELPER METHODS
  // ════════════════════════════════════════════════════════════════

  private Task findTaskById(Long id) {
    return taskRepository.findById(id)
        .filter(task -> !task.getIsDeleted())
        .orElseThrow(() -> new ResourceNotFoundException("Task not found with id: " + id));
  }

  private User getCurrentUser() {
    String username = SecurityUtils.getCurrentUserLogin();
    if (username == null) {
      throw new RuntimeException("No authenticated user found");
    }
    return userRepository.findByUsername(username)
        .orElseThrow(() -> new RuntimeException("User not found: " + username));
  }

  private String generateTaskCode() {
    String prefix = "TASK-" + LocalDateTime.now().format(DateTimeFormatter.ofPattern("yyyy"));
    long count = taskRepository.count() + 1;
    return String.format("%s-%04d", prefix, count);
  }

  private void logActivity(Task task, String action, String message, User user) {
    TaskActivityLog log = TaskActivityLog.builder()
        .task(task)
        .action(action)
        .message(message)
        .user(user)
        .build();
    taskActivityLogRepository.save(log);
  }

  private Pageable createPageable(TaskFilterDto filter) {
    int page = filter.getPage() != null ? filter.getPage() : 0;
    int size = filter.getSize() != null ? filter.getSize() : 20;
    
    String sortBy = filter.getSortBy() != null ? filter.getSortBy() : "createdAt";
    Sort.Direction direction = "asc".equalsIgnoreCase(filter.getSortDirection()) 
        ? Sort.Direction.ASC : Sort.Direction.DESC;
    
    return PageRequest.of(page, size, Sort.by(direction, sortBy));
  }

  private Specification<Task> createSpecification(TaskFilterDto filter) {
    return (root, query, cb) -> {
      List<Predicate> predicates = new ArrayList<>();

      // Not deleted
      predicates.add(cb.isFalse(root.get("isDeleted")));

      // Keyword search
      if (filter.getKeyword() != null && !filter.getKeyword().isEmpty()) {
        String keyword = "%" + filter.getKeyword().toLowerCase() + "%";
        predicates.add(cb.or(
            cb.like(cb.lower(root.get("title")), keyword),
            cb.like(cb.lower(root.get("description")), keyword)
        ));
      }

      // Status filter
      if (filter.getStatuses() != null && !filter.getStatuses().isEmpty()) {
        predicates.add(root.get("status").in(filter.getStatuses()));
      }

      // Priority filter
      if (filter.getPriorities() != null && !filter.getPriorities().isEmpty()) {
        predicates.add(root.get("priority").in(filter.getPriorities()));
      }

      // Assignee filter
      if (filter.getAssigneeIds() != null && !filter.getAssigneeIds().isEmpty()) {
        predicates.add(root.get("assignedTo").get("id").in(filter.getAssigneeIds()));
      }

      // Department filter
      if (filter.getDepartment() != null) {
        predicates.add(cb.equal(root.get("department"), filter.getDepartment()));
      }

      // Team filter
      if (filter.getTeam() != null) {
        predicates.add(cb.equal(root.get("team"), filter.getTeam()));
      }

      // Relation type filter
      if (filter.getRelationType() != null) {
        predicates.add(cb.equal(root.get("relationType"), filter.getRelationType()));
      }

      // Relation ID filter
      if (filter.getRelationId() != null) {
        predicates.add(cb.equal(root.get("relationId"), filter.getRelationId()));
      }

      // Overdue filter
      if (filter.getOverdue() != null && filter.getOverdue()) {
        predicates.add(cb.and(
            cb.lessThan(root.get("dueDate"), LocalDateTime.now()),
            cb.notEqual(root.get("status"), TaskStatus.COMPLETED),
            cb.notEqual(root.get("status"), TaskStatus.CANCELLED)
        ));
      }

      // Urgent filter
      if (filter.getUrgent() != null && filter.getUrgent()) {
        predicates.add(cb.isTrue(root.get("isUrgent")));
      }

      // Archived filter
      if (filter.getArchived() != null) {
        predicates.add(cb.equal(root.get("isArchived"), filter.getArchived()));
      }

      return cb.and(predicates.toArray(new Predicate[0]));
    };
  }

  // DTO Conversion Methods
  private TaskDto toDto(Task task) {
    TaskDto dto = TaskDto.builder()
        .id(task.getId())
        .code(task.getCode())
        .title(task.getTitle())
        .description(task.getDescription())
        .status(task.getStatus())
        .priority(task.getPriority())
        .team(task.getTeam())
        .department(task.getDepartment())
        .relationType(task.getRelationType())
        .relationId(task.getRelationId())
        .dueDate(task.getDueDate())
        .startDate(task.getStartDate())
        .completedAt(task.getCompletedAt())
        .createdAt(task.getCreatedAt())
        .updatedAt(task.getUpdatedAt())
        .estimatedMinutes(task.getEstimatedMinutes())
        .actualMinutes(task.getActualMinutes())
        .estimatedDate(task.getDueDate())
        .actualDate(task.getCompletedAt())
        .isUrgent(task.getIsUrgent())
        .isRecurring(task.getIsRecurring())
        .isArchived(task.getIsArchived())
        .progressPercentage(task.getProgressPercentage())
        .isOverdue(task.isOverdue())
        .commentsCount(task.getComments().size())
        .attachmentsCount(task.getAttachments().size())
        .watchersCount(task.getWatchers().size())
        .build();

    if (task.getAssignedTo() != null) {
      dto.setAssignedToId(task.getAssignedTo().getId());
      dto.setAssignedToUsername(task.getAssignedTo().getUsername());
    }

    if (task.getCreatedBy() != null) {
      dto.setCreatedById(task.getCreatedBy().getId());
      dto.setCreatedByUsername(task.getCreatedBy().getUsername());
      dto.setCreatedByName(task.getCreatedBy().getUsername());
    }

    if (task.getCompletedBy() != null) {
      dto.setCompletedById(task.getCompletedBy().getId());
      dto.setCompletedByUsername(task.getCompletedBy().getUsername());
    }

    if (task.getParentTask() != null) {
      dto.setParentTaskId(task.getParentTask().getId());
      dto.setParentTaskTitle(task.getParentTask().getTitle());
    }

    taskActivityLogRepository.findFirstByTaskIdOrderByCreatedAtDesc(task.getId()).ifPresent(lastLog -> {
      dto.setModifiedAt(lastLog.getCreatedAt());
      if (lastLog.getUser() != null) {
        dto.setModifiedById(lastLog.getUser().getId());
        dto.setModifiedByUsername(lastLog.getUser().getUsername());
        dto.setModifiedByName(lastLog.getUser().getUsername());
      }
    });

    return dto;
  }

  private TaskCommentDto toCommentDto(TaskComment comment) {
    if (comment == null) return null;

    User author = comment.getAuthor();
    String authorName = "Unknown";
    String authorUsername = null;
    Long authorId = null;

    if (author != null) {
      authorId = author.getId();
      authorUsername = author.getUsername();
      if (author.getUsername() != null && !author.getUsername().isBlank()) {
        authorName = author.getUsername();
      }
    }

    return TaskCommentDto.builder()
        .id(comment.getId())
        .taskId(comment.getTask().getId())
        .authorId(authorId)
        .authorUsername(authorUsername)
        .authorName(authorName)
        .content(comment.getContent())
        .isInternal(comment.getIsInternal())
        .parentCommentId(comment.getParentComment() != null ? comment.getParentComment().getId() : null)
        .createdAt(comment.getCreatedAt())
        .editedAt(comment.getEditedAt())
        .repliesCount(comment.getReplies().size())
        .build();
  }

  private TaskAttachmentDto toAttachmentDto(TaskAttachment attachment) {
    User uploader = attachment.getUploadedBy();
    return TaskAttachmentDto.builder()
        .id(attachment.getId())
        .taskId(attachment.getTask().getId())
        .fileName(attachment.getFileName())
        .fileUrl(attachment.getFileUrl())
        .mimeType(attachment.getMimeType())
        .fileSizeBytes(attachment.getFileSizeBytes())
        .uploadedById(uploader != null ? uploader.getId() : null)
        .uploadedByUsername(uploader != null ? uploader.getUsername() : null)
        .uploadedAt(attachment.getUploadedAt())
        .description(attachment.getDescription())
        .build();
  }

  private TaskActivityLogDto toActivityLogDto(TaskActivityLog log) {
    TaskActivityLogDto dto = TaskActivityLogDto.builder()
        .id(log.getId())
        .taskId(log.getTask().getId())
        .action(log.getAction())
        .message(log.getMessage())
        .createdAt(log.getCreatedAt())
        .metadata(log.getMetadata())
        .build();

    if (log.getUser() != null) {
      dto.setUserId(log.getUser().getId());
      dto.setUsername(log.getUser().getUsername());
    }

    return dto;
  }
}
