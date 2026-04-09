package com.svtrucking.logistics.service;

import com.svtrucking.logistics.dto.DispatchDto;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.util.ArrayList;
import java.util.List;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class ChangeTruckResult {
  private DispatchDto dispatch;
  private boolean driverAssignedToNewVehicle;
  private List<String> warnings = new ArrayList<>();

  public ChangeTruckResult(DispatchDto dispatch, boolean driverAssignedToNewVehicle) {
    this.dispatch = dispatch;
    this.driverAssignedToNewVehicle = driverAssignedToNewVehicle;
  }
}
