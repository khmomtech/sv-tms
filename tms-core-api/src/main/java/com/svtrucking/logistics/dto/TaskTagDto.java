package com.svtrucking.logistics.dto;

import com.fasterxml.jackson.annotation.JsonInclude;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Pattern;
import jakarta.validation.constraints.Size;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
@JsonInclude(JsonInclude.Include.NON_NULL)
public class TaskTagDto {

  private Long id;

  @NotBlank(message = "Tag name is required")
  @Size(max = 50, message = "Tag name cannot exceed 50 characters")
  private String name;

  @Size(max = 7, message = "Color must be valid hex code")
  @Pattern(regexp = "^#[0-9A-Fa-f]{6}$", message = "Color must be valid hex code (e.g., #FF5733)")
  private String color;

  @Size(max = 50, message = "Category cannot exceed 50 characters")
  private String category;

  @Size(max = 500, message = "Description cannot exceed 500 characters")
  private String description;

  private Boolean isActive;

  // Computed
  private Integer usageCount; // Number of tasks using this tag
}
