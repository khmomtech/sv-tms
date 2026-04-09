package com.svtrucking.logistics.service;

import com.svtrucking.logistics.dto.DriverIssueDto;
import com.svtrucking.logistics.model.Dispatch;
import com.svtrucking.logistics.model.Driver;
import com.svtrucking.logistics.model.DriverIssue;
import com.svtrucking.logistics.repository.DispatchRepository;
import com.svtrucking.logistics.repository.DriverIssueRepository;
import com.svtrucking.logistics.repository.DriverRepository;
import com.svtrucking.logistics.enums.IssueSeverity;
import com.svtrucking.logistics.enums.IssueStatus;
import java.io.InputStream;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.StandardCopyOption;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.*;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageImpl;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.util.StringUtils;
import org.springframework.web.multipart.MultipartFile;

@Service
@RequiredArgsConstructor
@Transactional
public class DriverIssueService {

  private static final Set<String> ALLOWED_STATUSES =
      Set.of("OPEN", "IN_PROGRESS", "RESOLVED", "CLOSED");
  private static final long MAX_FILE_BYTES = 10 * 1024 * 1024; // 10 MB
  private static final String UPLOAD_ROOT = "uploads";
  private static final String ISSUE_FOLDER = "issues";

  private final DriverIssueRepository issueRepo;
  private final DriverRepository driverRepo;
  private final DispatchRepository dispatchRepo;

  public DriverIssueDto submitIssue(
      Long driverId,
      Long dispatchId,
      String title,
      String description,
      List<MultipartFile> images) {

    if (!StringUtils.hasText(title)) {
      throw new IllegalArgumentException("Title must not be blank");
    }
    if (!StringUtils.hasText(description)) {
      throw new IllegalArgumentException("Description must not be blank");
    }

    Driver driver =
        driverRepo
            .findById(driverId)
            .orElseThrow(() -> new NoSuchElementException("Driver not found: " + driverId));

    Dispatch dispatch = null;
    if (dispatchId != null) {
      dispatch =
          dispatchRepo
              .findById(dispatchId)
              .orElseThrow(() -> new NoSuchElementException("Dispatch not found: " + dispatchId));
    }

    Set<String> imagePaths = new LinkedHashSet<>();
    if (images != null) {
      for (MultipartFile file : images) {
        if (file == null || file.isEmpty()) continue;
        imagePaths.add(storeImageFile(file, ISSUE_FOLDER));
      }
    }

    DriverIssue issue =
        DriverIssue.builder()
            .driver(driver)
            .dispatch(dispatch)
            .title(title.trim())
            .description(description.trim())
            .severity(IssueSeverity.MEDIUM) // default until severity selection is added in UI
            .status(com.svtrucking.logistics.enums.IssueStatus.OPEN)
            .createdAt(LocalDateTime.now())
            .images(imagePaths)
            .build();

    issue = issueRepo.save(issue);
    return DriverIssueDto.fromEntity(issue);
  }

  /** Legacy method (no ownership checks). Prefer updateStatusOwnedByDriver. */
  public DriverIssueDto updateStatus(Long id, String status) {
    IssueStatus statusEnum = parseRequiredStatus(status);
    DriverIssue issue =
        issueRepo
            .findById(id)
            .orElseThrow(() -> new NoSuchElementException("Issue not found: " + id));
    issue.setStatus(statusEnum);
    issueRepo.save(issue);
    return DriverIssueDto.fromEntity(issue);
  }

  /** Ownership-safe status update. */
  public DriverIssueDto updateStatusOwnedByDriver(Long id, Long driverId, String status) {
    IssueStatus statusEnum = parseRequiredStatus(status);
    DriverIssue issue = requireOwnedIssue(id, driverId);
    issue.setStatus(statusEnum);
    issueRepo.save(issue);
    return DriverIssueDto.fromEntity(issue);
  }

  /** Legacy get (no ownership checks). Prefer getByIdOwnedByCurrentDriver. */
  public DriverIssueDto getById(Long id) {
    DriverIssue issue =
        issueRepo
            .findById(id)
            .orElseThrow(() -> new NoSuchElementException("Issue not found: " + id));
    return DriverIssueDto.fromEntity(issue);
  }

  /** Ownership-safe get. */
  public DriverIssueDto getByIdOwnedByCurrentDriver(Long id, Long driverId) {
    DriverIssue issue = requireOwnedIssue(id, driverId);
    return DriverIssueDto.fromEntity(issue);
  }

  /**
   * Paged list by driver, optional status filter. NOTE: For additional filters (type, dates), add
   * repository queries and extend this method.
   */
  @Transactional(readOnly = true)
  public Page<DriverIssueDto> getDriverIssues(Long driverId, String status, Pageable pageable) {
    if (driverId == null) {
      throw new IllegalArgumentException("driverId is required");
    }
    Pageable safePageable = pageable == null ? Pageable.unpaged() : pageable;

    IssueStatus statusEnum = parseOptionalStatus(status);
    Page<DriverIssue> page =
        (statusEnum == null)
            ? issueRepo.findByDriverIdAndIsDeletedFalse(driverId, safePageable)
            : issueRepo.findByDriverIdAndStatusAndIsDeletedFalse(driverId, statusEnum, safePageable);

    return page.map(DriverIssueDto::fromEntity);
  }

  /**
   * Overloaded: supports optional type and date range filters expected by the controller. NOTE:
   * This applies in-memory filtering on the page content. For large datasets, move these filters to
   * the repository layer (Specifications/Query methods).
   */
  @Transactional(readOnly = true)
  public Page<DriverIssueDto> getDriverIssues(
      Long driverId,
      String status,
      String type,
      LocalDate fromDate,
      LocalDate toDate,
      Pageable pageable) {
    // Reuse existing repository-backed paging and status filter
    Page<DriverIssueDto> base =
        getDriverIssues(driverId, status, pageable == null ? Pageable.unpaged() : pageable);

    // Optional in-memory refine by type (case-insensitive match on title or severity) and date range
    final boolean hasType = StringUtils.hasText(type);
    List<DriverIssueDto> filtered = new ArrayList<>();
    for (DriverIssueDto dto : base.getContent()) {
      boolean ok = true;

      if (hasType) {
        final String t = type.trim().toLowerCase(Locale.ROOT);
        // "incident" is the generic bucket for driver issues; ignore the filter to avoid hiding data.
        if (!t.equals("incident")) {
          final String title = dto.getTitle() == null ? "" : dto.getTitle().toLowerCase(Locale.ROOT);
          final String severity =
              dto.getSeverity() == null ? "" : dto.getSeverity().name().toLowerCase(Locale.ROOT);
          final String description =
              dto.getDescription() == null ? "" : dto.getDescription().toLowerCase(Locale.ROOT);
          ok &= (title.contains(t) || description.contains(t) || severity.equals(t));
        }
      }

      if (fromDate != null || toDate != null) {
        LocalDate created = null;
        if (dto.getCreatedAt() != null) {
          created = dto.getCreatedAt().toLocalDate();
        }
        if (created == null) {
          ok = false;
        } else {
          if (fromDate != null && created.isBefore(fromDate)) ok = false;
          if (toDate != null && created.isAfter(toDate)) ok = false;
        }
      }

      if (ok) filtered.add(dto);
    }

    // Keep paging metadata consistent with original page (totalElements/last/etc.)
    return new PageImpl<>(filtered, pageable, base.getTotalElements());
  }

  /** Legacy delete (no ownership checks). Prefer deleteIssueOwnedByDriver. */
  public void deleteIssue(Long id) {
    if (!issueRepo.existsById(id)) {
      throw new NoSuchElementException("Issue not found: " + id);
    }
    issueRepo.deleteById(id);
  }

  /** Ownership-safe delete. */
  public void deleteIssueOwnedByDriver(Long id, Long driverId) {
    DriverIssue issue = requireOwnedIssue(id, driverId);
    issueRepo.delete(issue);
  }

  /** Legacy update (no ownership checks). Prefer updateIssueOwnedByDriver. */
  public DriverIssueDto updateIssue(Long id, DriverIssueDto request) {
    DriverIssue issue =
        issueRepo
            .findById(id)
            .orElseThrow(() -> new NoSuchElementException("Issue not found: " + id));
    issue.setTitle(safeTrim(request.getTitle()));
    issue.setDescription(safeTrim(request.getDescription()));
    issue = issueRepo.save(issue);
    return DriverIssueDto.fromEntity(issue);
  }

  /** Ownership-safe update title/description. */
  public DriverIssueDto updateIssueOwnedByDriver(
      Long id, Long driverId, String title, String description) {
    if (!StringUtils.hasText(title) || !StringUtils.hasText(description)) {
      throw new IllegalArgumentException("Title and description are required");
    }
    DriverIssue issue = requireOwnedIssue(id, driverId);
    issue.setTitle(title.trim());
    issue.setDescription(description.trim());
    issue = issueRepo.save(issue);
    return DriverIssueDto.fromEntity(issue);
  }

  // ----------------------- helpers -----------------------

  private DriverIssue requireOwnedIssue(Long id, Long driverId) {
    DriverIssue issue =
        issueRepo
            .findById(id)
            .orElseThrow(() -> new NoSuchElementException("Issue not found: " + id));
    if (issue.getDriver() == null || !Objects.equals(issue.getDriver().getId(), driverId)) {
      throw new SecurityException("Issue does not belong to the current driver");
    }
    return issue;
  }

  private IssueStatus parseRequiredStatus(String status) {
    if (!StringUtils.hasText(status)) {
      throw new IllegalArgumentException("Status must not be blank");
    }
    String normalized = status.trim().toUpperCase(Locale.ROOT);
    if (!ALLOWED_STATUSES.contains(normalized)) {
      throw new IllegalArgumentException("Unsupported status: " + status);
    }
    return IssueStatus.valueOf(normalized);
  }

  private IssueStatus parseOptionalStatus(String status) {
    return StringUtils.hasText(status) ? parseRequiredStatus(status) : null;
  }

  private String safeTrim(String s) {
    return s == null ? null : s.trim();
  }

  private String storeImageFile(MultipartFile file, String folder) {
    try {
      String contentType = file.getContentType();
      if (contentType == null || !contentType.startsWith("image/")) {
        throw new IllegalArgumentException("Only image uploads are allowed");
      }
      if (file.getSize() > MAX_FILE_BYTES) {
        throw new IllegalArgumentException("File too large (max 10MB)");
      }

      String original =
          StringUtils.cleanPath(Optional.ofNullable(file.getOriginalFilename()).orElse("image"));
      String ext = extractExtension(original, contentType);
      String filename = UUID.randomUUID().toString() + ext;

      Path dir = Path.of(UPLOAD_ROOT, folder, LocalDate.now().toString());
      Files.createDirectories(dir);
      Path target = dir.resolve(filename);

      try (InputStream in = file.getInputStream()) {
        Files.copy(in, target, StandardCopyOption.REPLACE_EXISTING);
      }

      // return path relative to /uploads mapping (e.g. issues/2025-08-28/uuid.jpg)
      return Path.of(folder, LocalDate.now().toString(), filename).toString().replace("\\", "/");
    } catch (Exception e) {
      throw new RuntimeException("Failed to store file", e);
    }
  }

  private String extractExtension(String originalName, String contentType) {
    String lowered = originalName.toLowerCase(Locale.ROOT);
    String ext = "";
    int dot = lowered.lastIndexOf('.');
    if (dot != -1 && dot < lowered.length() - 1) {
      ext = lowered.substring(dot);
    } else if ("image/jpeg".equals(contentType)) {
      ext = ".jpg";
    } else if ("image/png".equals(contentType)) {
      ext = ".png";
    } else if ("image/webp".equals(contentType)) {
      ext = ".webp";
    } else {
      ext = ".img";
    }
    // basic sanitization of weird extensions
    if (ext.contains("/") || ext.contains("\\")) ext = ".img";
    return ext;
  }
}
