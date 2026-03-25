package com.svtrucking.logistics.service;

import com.svtrucking.logistics.dto.VehicleDocumentDto;
import com.svtrucking.logistics.dto.VehicleDocumentRequest;
import com.svtrucking.logistics.enums.VehicleDocumentType;
import com.svtrucking.logistics.exception.ResourceNotFoundException;
import com.svtrucking.logistics.model.Vehicle;
import com.svtrucking.logistics.model.VehicleDocument;
import com.svtrucking.logistics.repository.DocumentRepository;
import com.svtrucking.logistics.repository.VehicleRepository;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.sql.Date;
import java.util.Optional;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
@Slf4j
@RequiredArgsConstructor
public class DocumentAdminService {
  private final DocumentRepository documentRepository;
  private final VehicleRepository vehicleRepository;
  private final VehicleDocumentService vehicleDocumentService;

  @Transactional
  public VehicleDocumentDto createDocument(VehicleDocumentRequest request, String updatedBy) {
    Vehicle vehicle = vehicleRepository.findById(request.getVehicleId())
        .orElseThrow(() -> new ResourceNotFoundException("Vehicle not found with id: " + request.getVehicleId()));
    VehicleDocument doc = buildDocument(request, vehicle);
    doc.setCreatedAt(LocalDateTime.now());
    doc.setUpdatedAt(LocalDateTime.now());
    doc.setUpdatedBy(updatedBy);
    VehicleDocument saved = documentRepository.save(doc);
    return vehicleDocumentService.map(saved);
  }

  @Transactional
  public VehicleDocumentDto updateDocument(Long id, VehicleDocumentRequest request, String updatedBy) {
    VehicleDocument existing = documentRepository.findById(id)
        .orElseThrow(() -> new ResourceNotFoundException("Document not found with id: " + id));
    applyRequest(existing, request);
    existing.setUpdatedAt(LocalDateTime.now());
    existing.setUpdatedBy(updatedBy);
    VehicleDocument saved = documentRepository.save(existing);
    return vehicleDocumentService.map(saved);
  }

  @Transactional
  public void deleteDocument(Long id) {
    if (!documentRepository.existsById(id)) {
      throw new ResourceNotFoundException("Document not found with id: " + id);
    }
    documentRepository.deleteById(id);
  }

  private VehicleDocument buildDocument(VehicleDocumentRequest request, Vehicle vehicle) {
    VehicleDocument doc = new VehicleDocument();
    doc.setVehicle(vehicle);
    applyRequest(doc, request);
    return doc;
  }

  private void applyRequest(VehicleDocument doc, VehicleDocumentRequest request) {
    if (request.getDocumentType() != null) {
      doc.setDocumentType(resolveType(request.getDocumentType()));
    }
    if (request.getDocumentUrl() != null) {
      doc.setDocumentUrl(request.getDocumentUrl());
    }
    if (request.getDocumentNumber() != null) {
      doc.setDocumentNumber(request.getDocumentNumber());
    }
    if (request.getIssueDate() != null) {
      doc.setIssueDate(Date.valueOf(request.getIssueDate()));
    }
    if (request.getExpiryDate() != null) {
      doc.setExpiryDate(Date.valueOf(request.getExpiryDate()));
    }
    if (request.getApproved() != null) {
      doc.setApproved(request.getApproved());
    }
    if (request.getNotes() != null) {
      doc.setNotes(request.getNotes());
    }
  }

  private VehicleDocumentType resolveType(String raw) {
    if (raw == null || raw.isBlank()) {
      return VehicleDocumentType.OTHER;
    }
    try {
      return VehicleDocumentType.valueOf(raw.trim().toUpperCase());
    } catch (IllegalArgumentException ex) {
      return VehicleDocumentType.OTHER;
    }
  }

  @Transactional(readOnly = true)
  public Page<VehicleDocumentDto> report(
      String dateField,
      LocalDate from,
      LocalDate to,
      Long vehicleId,
      String documentType,
      String search,
      Pageable pageable) {
    VehicleDocumentType type = null;
    if (documentType != null && !documentType.isBlank()) {
      try {
        type = VehicleDocumentType.valueOf(documentType.trim().toUpperCase());
      } catch (IllegalArgumentException ignored) {
        type = null;
      }
    }

    LocalDate safeFrom = Optional.ofNullable(from).orElse(LocalDate.of(1900, 1, 1));
    LocalDate safeTo = Optional.ofNullable(to).orElse(LocalDate.of(2999, 12, 31));

    String field = dateField == null ? "created" : dateField.trim().toLowerCase();

    Page<VehicleDocument> page;
    if ("issue".equals(field)) {
      page =
          documentRepository.reportByIssueDate(
              vehicleId, type, normalizeSearch(search), Date.valueOf(safeFrom), Date.valueOf(safeTo), pageable);
    } else if ("expiry".equals(field) || "expiration".equals(field)) {
      page =
          documentRepository.reportByExpiryDate(
              vehicleId, type, normalizeSearch(search), Date.valueOf(safeFrom), Date.valueOf(safeTo), pageable);
    } else {
      LocalDateTime fromTs = safeFrom.atStartOfDay();
      LocalDateTime toTs = safeTo.atTime(23, 59, 59);
      page =
          documentRepository.reportByCreatedAt(
              vehicleId, type, normalizeSearch(search), fromTs, toTs, pageable);
    }

    return page.map(vehicleDocumentService::map);
  }

  private String normalizeSearch(String search) {
    return (search == null || search.isBlank()) ? null : search.trim();
  }
}
