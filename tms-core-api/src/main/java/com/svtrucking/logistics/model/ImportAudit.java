package com.svtrucking.logistics.model;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import java.time.LocalDateTime;
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
@Entity
@Table(name = "import_audit")
public class ImportAudit {

  @Id
  @GeneratedValue(strategy = GenerationType.IDENTITY)
  private Long id;

  @Column(name = "import_id", nullable = false, unique = true)
  private String importId;

  @Column(name = "source_file")
  private String sourceFile;

  @Column(name = "row_count")
  private Integer rowCount;

  @Column(name = "started_at")
  private LocalDateTime startedAt;

  @Column(name = "finished_at")
  private LocalDateTime finishedAt;

  @Column(name = "checksum")
  private String checksum;

  @Column(name = "status")
  private String status;

  @Column(name = "created_by")
  private String createdBy;

  @Column(name = "notes", columnDefinition = "TEXT")
  private String notes;
}
