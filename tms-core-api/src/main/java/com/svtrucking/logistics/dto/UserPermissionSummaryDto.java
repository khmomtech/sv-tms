package com.svtrucking.logistics.dto;

import java.util.Map;
import java.util.Set;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;

@Getter
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class UserPermissionSummaryDto {

  private Long userId;
  private Set<String> permissions;
  private Map<String, Set<String>> permissionMatrix;
}
