package com.svtrucking.logistics.service;

import com.svtrucking.logistics.dto.VehicleDocumentDto;
import com.svtrucking.logistics.model.VehicleDocument;
import com.svtrucking.logistics.repository.DocumentRepository;
import java.nio.file.Paths;
import java.util.List;
import java.util.stream.Collectors;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;

/** Provides read-only access to vehicle documents. */
@Service
@Slf4j
@RequiredArgsConstructor
public class VehicleDocumentService {
  private final DocumentRepository documentRepository;

  public List<VehicleDocumentDto> getDocumentsByVehicle(Long vehicleId) {
    if (vehicleId == null) return List.of();
    List<VehicleDocument> docs = documentRepository.findByVehicleId(vehicleId);
    log.debug("Found {} documents for vehicle {}", docs.size(), vehicleId);
    return docs.stream().map(this::map).collect(Collectors.toList());
  }

  public VehicleDocumentDto map(VehicleDocument doc) {
    if (doc == null) return null;
    var vehicle = doc.getVehicle();
    String vehicleName = vehicle != null ? vehicle.getManufacturer() + " " + vehicle.getModel() : null;
    String licensePlate = vehicle != null ? vehicle.getLicensePlate() : null;
    String fileName = deriveFileName(doc.getDocumentUrl());
    String docNumber = doc.getDocumentNumber();
    if (docNumber == null) {
      docNumber = deriveDocNumber(doc);
    }

    return VehicleDocumentDto.builder()
        .id(doc.getId())
        .vehicleId(vehicle != null ? vehicle.getId() : null)
        .vehicleName(vehicleName)
        .licensePlate(licensePlate)
        .documentType(doc.getDocumentType() != null ? doc.getDocumentType().name() : null)
        .documentUrl(doc.getDocumentUrl())
        .documentName(fileName)
        .docNumber(docNumber)
        .notes(doc.getNotes())
        .issueDate(doc.getIssueDate())
        .expiryDate(doc.getExpiryDate())
        .approved(doc.isApproved())
        .updatedAt(doc.getUpdatedAt())
        .updatedBy(doc.getUpdatedBy())
        .build();
  }

  private String deriveFileName(String url) {
    if (url == null || url.isBlank()) return null;
    try {
      return Paths.get(url).getFileName().toString();
    } catch (Exception ex) {
      return url;
    }
  }

  private String deriveDocNumber(VehicleDocument doc) {
    var vehicle = doc.getVehicle();
    if (vehicle != null && vehicle.getLicensePlate() != null) {
      return vehicle.getLicensePlate() + "-" + doc.getId();
    }
    return doc.getId() != null ? doc.getId().toString() : null;
  }
}
