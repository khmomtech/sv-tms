package com.svtrucking.logistics.dto;

import com.fasterxml.jackson.annotation.JsonInclude;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
@JsonInclude(JsonInclude.Include.NON_NULL)
public class TaskStatisticsDto {

  private Long totalTasks;
  private Long openTasks;
  private Long inProgressTasks;
  private Long completedTasks;
  private Long blockedTasks;
  private Long onHoldTasks;
  private Long inReviewTasks;
  private Long cancelledTasks;

  private Long criticalPriorityTasks;
  private Long highPriorityTasks;
  private Long mediumPriorityTasks;
  private Long lowPriorityTasks;

  private Long overdueTasks;
  private Long urgentTasks;

  private Long tasksAssignedToMe;
  private Long tasksCreatedByMe;
  private Long tasksWatchedByMe;

  private Long standaloneTasks;
  private Long incidentTasks;
  private Long workOrderTasks;
  private Long vehicleTasks;
  private Long caseTasks;

  private Double avgCompletionTimeMinutes;
  private Integer completionRatePercentage; // completed / total * 100
}
