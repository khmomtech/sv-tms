package com.svtrucking.logistics.model;

import com.svtrucking.logistics.enums.TaskPriority;
import com.svtrucking.logistics.enums.TaskStatus;
import jakarta.persistence.*;
import lombok.*;
import org.hibernate.annotations.CreationTimestamp;
import org.hibernate.annotations.UpdateTimestamp;

import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.HashSet;
import java.util.List;
import java.util.Set;

/**
 * Unified Task Entity - Can be used for ANY task in the system
 * - Standalone tasks (not related to orders/vehicles/etc)
 * - Project tasks
 * - Department tasks
 * - Administrative tasks
 * - Team collaboration
 * - Can OPTIONALLY link to other entities via relationType + relationId
 * 
 * Examples of relationType:
 * - "INCIDENT" → links to driver_issues table
 * - "WORK_ORDER" → links to work_orders table
 * - "VEHICLE" → links to vehicles table
 * - "CASE" → links to cases table
 * - "TRANSPORT_ORDER" → links to transport_orders table
 * - "DRIVER" → links to drivers table
 * - "CUSTOMER" → links to customers table
 * - null → standalone task (not related to any entity)
 */
@Entity
@Table(name = "tasks", indexes = {
    @Index(name = "idx_tasks_status", columnList = "status"),
    @Index(name = "idx_tasks_priority", columnList = "priority"),
    @Index(name = "idx_tasks_assigned_to", columnList = "assigned_to_user_id"),
    @Index(name = "idx_tasks_relation", columnList = "relation_type, relation_id"),
    @Index(name = "idx_tasks_due_date", columnList = "due_date"),
    @Index(name = "idx_tasks_parent", columnList = "parent_task_id"),
    @Index(name = "idx_tasks_not_deleted", columnList = "is_deleted, status")
})
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class Task {

  @Id
  @GeneratedValue(strategy = GenerationType.IDENTITY)
  private Long id;

  @Column(length = 50, unique = true)
  private String code; // Auto-generated: TASK-2025-0001

  // ════════════════════════════════════════════════════════════════
  // BASIC INFO
  // ════════════════════════════════════════════════════════════════

  @Column(nullable = false, length = 200)
  private String title;

  @Column(columnDefinition = "TEXT")
  private String description;

  // ════════════════════════════════════════════════════════════════
  // STATUS & PRIORITY
  // ════════════════════════════════════════════════════════════════

  @Enumerated(EnumType.STRING)
  @Column(length = 30, nullable = false)
  @Builder.Default
  private TaskStatus status = TaskStatus.OPEN;

  @Enumerated(EnumType.STRING)
  @Column(length = 20, nullable = false)
  @Builder.Default
  private TaskPriority priority = TaskPriority.MEDIUM;

  // ════════════════════════════════════════════════════════════════
  // ASSIGNMENT & OWNERSHIP
  // ════════════════════════════════════════════════════════════════

  @ManyToOne(fetch = FetchType.LAZY)
  @JoinColumn(name = "assigned_to_user_id")
  private User assignedTo;

  @ManyToOne(fetch = FetchType.LAZY)
  @JoinColumn(name = "created_by_user_id", nullable = false)
  private User createdBy;

  @ManyToOne(fetch = FetchType.LAZY)
  @JoinColumn(name = "completed_by_user_id")
  private User completedBy;

  @Column(length = 100)
  private String team; // "Operations", "Maintenance", "Customer Service"

  @Column(length = 100)
  private String department; // "Fleet", "Dispatch", "Admin"

  // ════════════════════════════════════════════════════════════════
  // FLEXIBLE RELATIONS (★ KEY FEATURE)
  // ════════════════════════════════════════════════════════════════

  /**
   * Optional: Link this task to another entity
   * Examples:
   * - "INCIDENT" + relationId → driver_issues.id
   * - "WORK_ORDER" + relationId → work_orders.id
   * - "VEHICLE" + relationId → vehicles.id
   * - "CASE" + relationId → cases.id
   * - "TRANSPORT_ORDER" + relationId → transport_orders.id
   * - "DRIVER" + relationId → drivers.id
   * - "CUSTOMER" + relationId → customers.id
   * - null (standalone task)
   */
  @Column(name = "relation_type", length = 50)
  private String relationType;

  @Column(name = "relation_id")
  private Long relationId;

  // ════════════════════════════════════════════════════════════════
  // TIME TRACKING & DATES
  // ════════════════════════════════════════════════════════════════

  @Column(name = "due_date")
  private LocalDateTime dueDate;

  @Column(name = "start_date")
  private LocalDateTime startDate;

  @Column(name = "completed_at")
  private LocalDateTime completedAt;

  @CreationTimestamp
  @Column(nullable = false, updatable = false)
  private LocalDateTime createdAt;

  @UpdateTimestamp
  private LocalDateTime updatedAt;

  // Time estimates (in minutes)
  @Column(name = "estimated_minutes")
  private Integer estimatedMinutes;

  @Column(name = "actual_minutes")
  private Integer actualMinutes;

  // ════════════════════════════════════════════════════════════════
  // FLAGS & METADATA
  // ════════════════════════════════════════════════════════════════

  @Column(name = "is_urgent")
  @Builder.Default
  private Boolean isUrgent = false;

  @Column(name = "is_recurring")
  @Builder.Default
  private Boolean isRecurring = false;

  @Column(name = "is_archived")
  @Builder.Default
  private Boolean isArchived = false;

  @Column(name = "is_deleted")
  @Builder.Default
  private Boolean isDeleted = false;

  @Column(name = "progress_percentage")
  @Builder.Default
  private Integer progressPercentage = 0; // 0-100

  // ════════════════════════════════════════════════════════════════
  // HIERARCHICAL STRUCTURE (Parent/Subtasks)
  // ════════════════════════════════════════════════════════════════

  @ManyToOne(fetch = FetchType.LAZY)
  @JoinColumn(name = "parent_task_id")
  private Task parentTask;

  @OneToMany(mappedBy = "parentTask", cascade = CascadeType.ALL, orphanRemoval = true)
  @Builder.Default
  private List<Task> subtasks = new ArrayList<>();

  // ════════════════════════════════════════════════════════════════
  // COLLABORATION & TRACKING
  // ════════════════════════════════════════════════════════════════

  @OneToMany(mappedBy = "task", cascade = CascadeType.ALL, orphanRemoval = true)
  @Builder.Default
  private List<TaskComment> comments = new ArrayList<>();

  @OneToMany(mappedBy = "task", cascade = CascadeType.ALL, orphanRemoval = true)
  @Builder.Default
  private List<TaskAttachment> attachments = new ArrayList<>();

  @ManyToMany
  @JoinTable(
      name = "task_watchers",
      joinColumns = @JoinColumn(name = "task_id"),
      inverseJoinColumns = @JoinColumn(name = "user_id")
  )
  @Builder.Default
  private Set<User> watchers = new HashSet<>();

  @ManyToMany
  @JoinTable(
      name = "task_tags",
      joinColumns = @JoinColumn(name = "task_id"),
      inverseJoinColumns = @JoinColumn(name = "tag_id")
  )
  @Builder.Default
  private Set<TaskTag> tags = new HashSet<>();

  @OneToMany(mappedBy = "task", cascade = CascadeType.ALL, orphanRemoval = true)
  @Builder.Default
  private List<TaskActivityLog> activityLogs = new ArrayList<>();

  // ════════════════════════════════════════════════════════════════
  // HELPER METHODS
  // ════════════════════════════════════════════════════════════════

  @PrePersist
  protected void onCreate() {
    if (createdAt == null) {
      createdAt = LocalDateTime.now();
    }
    if (progressPercentage == null) {
      progressPercentage = 0;
    }
  }

  @PreUpdate
  protected void onUpdate() {
    updatedAt = LocalDateTime.now();
  }

  /**
   * Check if task is overdue
   */
  public boolean isOverdue() {
    return dueDate != null
        && LocalDateTime.now().isAfter(dueDate)
        && status != TaskStatus.COMPLETED
        && status != TaskStatus.CANCELLED;
  }

  /**
   * Check if task is related to specific entity type and ID
   */
  public boolean isRelatedTo(String type, Long id) {
    return type != null && type.equals(relationType) 
        && id != null && id.equals(relationId);
  }

  /**
   * Mark task as completed
   */
  public void markCompleted(User user) {
    this.status = TaskStatus.COMPLETED;
    this.completedAt = LocalDateTime.now();
    this.completedBy = user;
    this.progressPercentage = 100;
  }

  /**
   * Calculate progress based on subtasks
   */
  public void recalculateProgress() {
    if (subtasks == null || subtasks.isEmpty()) {
      return;
    }
    long completed = subtasks.stream()
        .filter(t -> t.getStatus() == TaskStatus.COMPLETED)
        .count();
    this.progressPercentage = (int) ((completed * 100) / subtasks.size());
  }

  /**
   * Add a comment to this task
   */
  public void addComment(TaskComment comment) {
    comments.add(comment);
    comment.setTask(this);
  }

  /**
   * Add an attachment to this task
   */
  public void addAttachment(TaskAttachment attachment) {
    attachments.add(attachment);
    attachment.setTask(this);
  }

  /**
   * Add a watcher to this task
   */
  public void addWatcher(User user) {
    watchers.add(user);
  }

  /**
   * Remove a watcher from this task
   */
  public void removeWatcher(User user) {
    watchers.remove(user);
  }

  /**
   * Add a tag to this task
   */
  public void addTag(TaskTag tag) {
    tags.add(tag);
  }

  /**
   * Remove a tag from this task
   */
  public void removeTag(TaskTag tag) {
    tags.remove(tag);
  }

  /**
   * Log an activity
   */
  public void logActivity(String action, String message, User user) {
    TaskActivityLog log = TaskActivityLog.builder()
        .task(this)
        .action(action)
        .message(message)
        .user(user)
        .build();
    activityLogs.add(log);
  }
}
