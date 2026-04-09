package com.svtrucking.logistics.service;

import com.svtrucking.logistics.model.ImportAudit;
import com.svtrucking.logistics.repository.ImportAuditRepository;
import java.time.LocalDateTime;
import java.util.Optional;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
public class ImportAuditService {

  private final ImportAuditRepository repo;

  public ImportAuditService(ImportAuditRepository repo) {
    this.repo = repo;
  }

  @Transactional
  public ImportAudit startImport(String importId, String sourceFile, Integer rowCount, String createdBy) {
    ImportAudit ia = ImportAudit.builder()
        .importId(importId)
        .sourceFile(sourceFile)
        .rowCount(rowCount)
        .startedAt(LocalDateTime.now())
        .status("RUNNING")
        .createdBy(createdBy)
        .build();
    return repo.save(ia);
  }

  @Transactional
  public Optional<ImportAudit> finishImport(String importId, String status, String checksum, String notes) {
    Optional<ImportAudit> opt = repo.findByImportId(importId);
    if (opt.isPresent()) {
      ImportAudit ia = opt.get();
      ia.setFinishedAt(LocalDateTime.now());
      ia.setStatus(status);
      ia.setChecksum(checksum);
      ia.setNotes(notes);
      repo.save(ia);
    }
    return opt;
  }
}
