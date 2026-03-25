package com.svtrucking.logistics.dto.responses;

import com.svtrucking.logistics.enums.DriverStatus;
import com.svtrucking.logistics.enums.VehicleType;
import java.util.List;
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
public class DriverLoginResponseDto {

  private String token;

  private DriverUserInfo user;

  @Getter
  @Setter
  @NoArgsConstructor
  @AllArgsConstructor
  @Builder
  public static class DriverUserInfo {
    private String username;
    private String email;
    private List<String> roles;
    private List<String> permissions;
    private Long driverId;
    private String zone;
    private VehicleType vehicleType;
    private DriverStatus status;
  }
}
