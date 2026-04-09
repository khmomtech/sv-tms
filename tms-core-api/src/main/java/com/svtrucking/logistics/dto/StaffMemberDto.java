package com.svtrucking.logistics.dto;

import com.svtrucking.logistics.model.StaffMember;
import java.time.LocalDateTime;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class StaffMemberDto {
  private Long id;
  private Long userId;
  private String fullName;
  private String email;
  private String phone;
  private String jobTitle;
  private String department;
  private Boolean active;
  private LocalDateTime createdAt;

  public static StaffMemberDto fromEntity(StaffMember staff) {
    if (staff == null) return null;
    return StaffMemberDto.builder()
        .id(staff.getId())
        .userId(staff.getUser() != null ? staff.getUser().getId() : null)
        .fullName(staff.getFullName())
        .email(staff.getEmail())
        .phone(staff.getPhone())
        .jobTitle(staff.getJobTitle())
        .department(staff.getDepartment())
        .active(staff.getActive())
        .createdAt(staff.getCreatedAt())
        .build();
  }
}
