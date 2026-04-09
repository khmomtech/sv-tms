package com.svtrucking.logistics.dto;

import com.fasterxml.jackson.annotation.JsonInclude;
import com.svtrucking.logistics.enums.TaskPriority;
import com.svtrucking.logistics.enums.TaskStatus;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;
import java.util.List;

/**
 * Filter DTO for task search and filtering
 */
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
@JsonInclude(JsonInclude.Include.NON_NULL)
public class TaskFilterDto {

  private String keyword; // Search in title and description

  private List<Long> assigneeIds;
  private List<TaskPriority> priorities;
  private List<TaskStatus> statuses;

  private LocalDateTime dueBefore;
  private LocalDateTime dueAfter;
  private LocalDateTime createdBefore;
  private LocalDateTime createdAfter;

  private Boolean overdue;
  private Boolean urgent;
  private Boolean hasAttachments;
  private Boolean archived;

  private List<Long> tagIds;
  private List<String> tagNames;

  private Long vehicleId;
  private Long customerId;
  private Long driverId;
  private Long workOrderId;
  private Long caseId;

  private String relationType;
  private Long relationId;

  private String department;
  private String team;

  private Long createdById;
  private Long watcherId; // Find tasks watched by user

  private Boolean includeSubtasks;
  private Boolean parentTasksOnly; // Only tasks without parent

  // Sorting
  private String sortBy; // "priority", "dueDate", "createdAt", "status"
  private String sortDirection; // "asc", "desc"

  // Pagination
  private Integer page;
  private Integer size;
}
