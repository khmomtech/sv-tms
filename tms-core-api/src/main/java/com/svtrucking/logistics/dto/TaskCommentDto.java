package com.svtrucking.logistics.dto;

import com.fasterxml.jackson.annotation.JsonInclude;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;

@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
@JsonInclude(JsonInclude.Include.NON_NULL)
public class TaskCommentDto {

  private Long id;

  @NotNull(message = "Task ID is required")
  private Long taskId;

  private Long authorId;
  private String authorUsername;
  private String authorName;

  @NotBlank(message = "Comment content is required")
  @Size(max = 10000, message = "Comment cannot exceed 10000 characters")
  private String content;

  private Boolean isInternal;

  // Threading
  private Long parentCommentId;

  @Builder.Default
  private List<TaskCommentDto> replies = new ArrayList<>();

  private LocalDateTime createdAt;
  private LocalDateTime editedAt;

  // Computed
  private Integer repliesCount;
}
