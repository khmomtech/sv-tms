package com.svtrucking.logistics.controller.admin;

import com.svtrucking.logistics.model.ImportAudit;
import com.svtrucking.logistics.service.ImportAuditService;
import java.util.Map;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/admin/imports")
public class ImportAuditController {

  private final ImportAuditService importAuditService;

  public ImportAuditController(ImportAuditService importAuditService) {
    this.importAuditService = importAuditService;
  }

  @PostMapping("/start")
  public ResponseEntity<?> start(@RequestBody Map<String, Object> body) {
    String importId = (String) body.get("importId");
    String sourceFile = (String) body.getOrDefault("sourceFile", null);
    Integer rowCount = body.get("rowCount") == null ? null : ((Number) body.get("rowCount")).intValue();
    String createdBy = (String) body.getOrDefault("createdBy", "automation");
    ImportAudit ia = importAuditService.startImport(importId, sourceFile, rowCount, createdBy);
    return ResponseEntity.ok(ia);
  }

  @PostMapping("/finish")
  public ResponseEntity<?> finish(@RequestBody Map<String, Object> body) {
    String importId = (String) body.get("importId");
    String status = (String) body.getOrDefault("status", "DONE");
    String checksum = (String) body.getOrDefault("checksum", null);
    String notes = (String) body.getOrDefault("notes", null);
    return importAuditService.finishImport(importId, status, checksum, notes)
        .map(ResponseEntity::ok)
        .orElse(ResponseEntity.notFound().build());
  }
}
