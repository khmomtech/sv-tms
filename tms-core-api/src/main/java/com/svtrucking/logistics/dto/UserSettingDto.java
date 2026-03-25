package com.svtrucking.logistics.dto;

import com.fasterxml.jackson.annotation.JsonInclude;
import com.svtrucking.logistics.model.UserSetting;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
@JsonInclude(JsonInclude.Include.NON_NULL)
public class UserSettingDto {

  private Long id;
  private Long userId;
  private String key;
  private String value;

  private String createdAt;
  private String updatedAt;

  public static UserSettingDto fromEntity(UserSetting setting) {
    return UserSettingDto.builder()
        .id(setting.getId())
        .userId(setting.getUserId())
        .key(setting.getKey())
        .value(setting.getValue())
        .createdAt(setting.getCreatedAt() != null ? setting.getCreatedAt().toString() : null)
        .updatedAt(setting.getUpdatedAt() != null ? setting.getUpdatedAt().toString() : null)
        .build();
  }

  public UserSetting toEntity() {
    return UserSetting.builder()
        .id(this.id)
        .userId(this.userId)
        .key(this.key)
        .value(this.value)
        .build();
  }
}
