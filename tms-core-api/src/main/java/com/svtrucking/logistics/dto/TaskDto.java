package com.svtrucking.logistics.dto;

import com.fasterxml.jackson.annotation.JsonInclude;
import com.fasterxml.jackson.annotation.JsonIgnoreProperties;
import com.svtrucking.logistics.enums.TaskPriority;
import com.svtrucking.logistics.enums.TaskStatus;
import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.HashSet;
import java.util.List;
import java.util.Set;

@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
@JsonInclude(JsonInclude.Include.NON_NULL)
@JsonIgnoreProperties(ignoreUnknown = true)
public class TaskDto {

  private Long id;
  private String code;

  // Basic Info
  @NotBlank(message = "Title is required")
  @Size(max = 200, message = "Title cannot exceed 200 characters")
  private String title;

  @Size(max = 10000, message = "Description cannot exceed 10000 characters")
  private String description;

  // Status & Priority
  private TaskStatus status;

  @NotNull(message = "Priority is required")
  private TaskPriority priority;

  // Assignment & Ownership
  private Long assignedToId;
  private String assignedToUsername;
  private String assignedToName;

  private Long createdById;
  private String createdByUsername;
  private String createdByName;
  private Long modifiedById;
  private String modifiedByUsername;
  private String modifiedByName;
  private LocalDateTime modifiedAt;

  private Long completedById;
  private String completedByUsername;
  private String completedByName;

  @Size(max = 100, message = "Team name cannot exceed 100 characters")
  private String team;

  @Size(max = 100, message = "Department name cannot exceed 100 characters")
  private String department;

  // Flexible Relations
  @Size(max = 50, message = "Relation type cannot exceed 50 characters")
  private String relationType;

  private Long relationId;
  private String relationDisplay; // Computed: display name of related entity

  // Time Tracking & Dates
  private LocalDateTime dueDate;
  private LocalDateTime startDate;
  private LocalDateTime completedAt;
  private LocalDateTime createdAt;
  private LocalDateTime updatedAt;

  @Min(value = 0, message = "Estimated minutes cannot be negative")
  private Integer estimatedMinutes;

  @Min(value = 0, message = "Actual minutes cannot be negative")
  private Integer actualMinutes;
  private LocalDateTime estimatedDate;
  private LocalDateTime actualDate;

  // Flags & Metadata
  private Boolean isUrgent;
  private Boolean isRecurring;
  private Boolean isArchived;
  private Boolean isDeleted;

  @Min(value = 0, message = "Progress must be at least 0")
  @Max(value = 100, message = "Progress cannot exceed 100")
  private Integer progressPercentage;

  // Hierarchical
  private Long parentTaskId;
  private String parentTaskTitle;

  @Builder.Default
  private List<TaskDto> subtasks = new ArrayList<>();

  // Collaboration & Tracking
  @Builder.Default
  private List<TaskCommentDto> comments = new ArrayList<>();

  @Builder.Default
  private List<TaskAttachmentDto> attachments = new ArrayList<>();

  @Builder.Default
  private Set<Long> watcherIds = new HashSet<>();

  @Builder.Default
  private Set<String> watcherUsernames = new HashSet<>();

  @Builder.Default
  private Set<TaskTagDto> tags = new HashSet<>();

  @Builder.Default
  private List<TaskActivityLogDto> activityLogs = new ArrayList<>();

  // Computed fields
  private Boolean isOverdue;
  private Integer commentsCount;
  private Integer attachmentsCount;
  private Integer watchersCount;
  private Integer subtasksCount;
  private Integer completedSubtasksCount;
}
