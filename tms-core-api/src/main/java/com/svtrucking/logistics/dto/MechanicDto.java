package com.svtrucking.logistics.dto;

import com.svtrucking.logistics.model.Mechanic;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;
import java.time.LocalDateTime;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class MechanicDto {
  private Long id;
  private Long userId;
  private Long staffId;

  @NotBlank(message = "Full name is required")
  @Size(max = 200, message = "Full name cannot exceed 200 characters")
  private String fullName;

  @Size(max = 50, message = "Phone cannot exceed 50 characters")
  private String phone;

  private Boolean active;
  private LocalDateTime createdAt;

  public static MechanicDto fromEntity(Mechanic m) {
    if (m == null) return null;
    return MechanicDto.builder()
        .id(m.getId())
        .userId(m.getUser() != null ? m.getUser().getId() : null)
        .staffId(m.getStaffMember() != null ? m.getStaffMember().getId() : null)
        .fullName(m.getFullName())
        .phone(m.getPhone())
        .active(m.getActive())
        .createdAt(m.getCreatedAt())
        .build();
  }
}
