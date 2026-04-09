package com.svtrucking.logistics.service;

import com.svtrucking.logistics.model.VehicleInspection;
import com.svtrucking.logistics.repository.InspectionRepository;
import java.util.List;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

@Service
public class InspectionService {

  @Autowired private InspectionRepository inspectionRepo;

  // Get all inspections
  public List<VehicleInspection> getAllInspections() {
    return inspectionRepo.findAll();
  }

  // Get inspections by vehicle
  public List<VehicleInspection> getInspectionsByVehicle(Long vehicleId) {
    return inspectionRepo.findByVehicleId(vehicleId);
  }

  // Add new inspection
  public VehicleInspection addInspection(VehicleInspection inspection) {
    return inspectionRepo.save(inspection);
  }

  // Update existing inspection
  public VehicleInspection updateInspection(Long id, VehicleInspection updatedInspection) {
    return inspectionRepo
        .findById(id)
        .map(
            inspection -> {
              inspection.setBrakesChecked(updatedInspection.isBrakesChecked());
              inspection.setTiresChecked(updatedInspection.isTiresChecked());
              inspection.setOilChecked(updatedInspection.isOilChecked());
              inspection.setLightsChecked(updatedInspection.isLightsChecked());
              inspection.setEngineChecked(updatedInspection.isEngineChecked());
              inspection.setComments(updatedInspection.getComments());
              inspection.setStatus(updatedInspection.getStatus());
              return inspectionRepo.save(inspection);
            })
        .orElseThrow(() -> new RuntimeException("Inspection Not Found"));
  }

  // Delete inspection
  public void deleteInspection(Long id) {
    inspectionRepo.deleteById(id);
  }
}
