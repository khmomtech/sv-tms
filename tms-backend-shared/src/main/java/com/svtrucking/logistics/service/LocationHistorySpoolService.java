package com.svtrucking.logistics.service;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.svtrucking.logistics.model.Dispatch;
import com.svtrucking.logistics.model.Driver;
import com.svtrucking.logistics.model.LocationHistory;
import io.micrometer.core.instrument.MeterRegistry;
import java.io.IOException;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.StandardOpenOption;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.List;
import java.util.stream.Collectors;
import java.util.stream.Stream;
import lombok.Data;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;

@Service
@Slf4j
@RequiredArgsConstructor
public class LocationHistorySpoolService {

  private static final DateTimeFormatter DAY_FMT = DateTimeFormatter.ofPattern("yyyy-MM-dd");
  private static final DateTimeFormatter HOUR_FMT = DateTimeFormatter.ofPattern("HH");

  private final ObjectMapper objectMapper;
  @Autowired(required = false)
  private MeterRegistry meterRegistry;

  @Value("${location.history.spool.enabled:true}")
  private boolean spoolEnabled;

  @Value("${location.history.spool.dir:spool/location-history}")
  private String spoolDir;

  @Value("${location.history.spool.max-disk-mb:2048}")
  private long maxDiskMb;

  public void appendBatch(List<LocationHistory> batch) {
    if (!spoolEnabled || batch == null || batch.isEmpty()) {
      return;
    }
    try {
      Path file = resolveCurrentSpoolFile();
      List<String> lines = batch.stream().map(this::toRecord).map(this::safeJson).toList();
      Files.write(
          file,
          lines,
          StandardCharsets.UTF_8,
          StandardOpenOption.CREATE,
          StandardOpenOption.APPEND);
      if (meterRegistry != null) {
        meterRegistry.counter("location.history.spool.appended.records").increment(batch.size());
      }
      enforceDiskBudget();
    } catch (Exception e) {
      log.error(
          "Failed to append {} location history records to spool: {}",
          batch.size(),
          e.toString(),
          e);
    }
  }

  public int replayToMongo(int maxRecords, DriverLocationMongoService mongoService) {
    if (!spoolEnabled || maxRecords <= 0 || mongoService == null) {
      return 0;
    }

    int replayed = 0;
    try {
      List<Path> files = listSpoolFilesOldestFirst();
      for (Path file : files) {
        if (replayed >= maxRecords) {
          break;
        }
        int allowance = maxRecords - replayed;
        int n = replaySingleFile(file, allowance, mongoService);
        replayed += n;
        if (n > 0 && meterRegistry != null) {
          meterRegistry.counter("location.history.spool.replayed.records").increment(n);
        }
      }
    } catch (Exception e) {
      log.warn("Spool replay failed: {}", e.toString());
    }
    return replayed;
  }

  public long currentSpoolBytes() {
    try {
      return listSpoolFilesOldestFirst().stream().mapToLong(this::safeFileSize).sum();
    } catch (Exception e) {
      return 0L;
    }
  }

  public long oldestPendingAgeSeconds() {
    try {
      List<Path> files = listSpoolFilesOldestFirst();
      if (files.isEmpty()) {
        return 0L;
      }
      long oldestMs = safeLastModified(files.get(0));
      if (oldestMs == Long.MAX_VALUE) {
        return 0L;
      }
      return Math.max(0L, (System.currentTimeMillis() - oldestMs) / 1000L);
    } catch (Exception e) {
      return 0L;
    }
  }

  private int replaySingleFile(Path file, int maxRecords, DriverLocationMongoService mongoService)
      throws IOException {
    List<String> lines = Files.readAllLines(file, StandardCharsets.UTF_8);
    if (lines.isEmpty()) {
      Files.deleteIfExists(file);
      return 0;
    }

    List<LocationHistory> batch = new ArrayList<>();
    List<String> rest = new ArrayList<>();

    int consumed = 0;
    for (String line : lines) {
      if (line == null || line.isBlank()) {
        continue;
      }
      if (consumed < maxRecords) {
        SpoolRecord rec = safeParse(line);
        if (rec != null) {
          batch.add(toLocationHistory(rec));
          consumed++;
        }
      } else {
        rest.add(line);
      }
    }

    if (batch.isEmpty()) {
      Files.deleteIfExists(file);
      return 0;
    }

    boolean ok = mongoService.trySaveAll(batch);
    if (!ok) {
      return 0;
    }

    if (rest.isEmpty()) {
      Files.deleteIfExists(file);
    } else {
      Files.write(
          file,
          rest,
          StandardCharsets.UTF_8,
          StandardOpenOption.TRUNCATE_EXISTING,
          StandardOpenOption.CREATE);
    }
    return batch.size();
  }

  private Path resolveCurrentSpoolFile() throws IOException {
    LocalDateTime now = LocalDateTime.now();
    Path dayDir = Path.of(spoolDir, DAY_FMT.format(now));
    Files.createDirectories(dayDir);
    return dayDir.resolve("history-" + HOUR_FMT.format(now) + ".jsonl");
  }

  private List<Path> listSpoolFilesOldestFirst() throws IOException {
    Path root = Path.of(spoolDir);
    if (!Files.exists(root)) {
      return List.of();
    }
    try (Stream<Path> s = Files.walk(root)) {
      return s.filter(Files::isRegularFile)
          .filter(p -> p.getFileName().toString().endsWith(".jsonl"))
          .sorted(Comparator.comparing(this::safeLastModified))
          .collect(Collectors.toList());
    }
  }

  private void enforceDiskBudget() {
    long maxBytes = maxDiskMb * 1024L * 1024L;
    if (maxBytes <= 0) {
      return;
    }
    try {
      List<Path> files = listSpoolFilesOldestFirst();
      long total = files.stream().mapToLong(this::safeFileSize).sum();
      if (total <= maxBytes) {
        return;
      }

      long target = (long) (maxBytes * 0.8);
      int deleted = 0;
      for (Path file : files) {
        if (total <= target) {
          break;
        }
        long size = safeFileSize(file);
        Files.deleteIfExists(file);
        total -= size;
        deleted++;
      }
      if (deleted > 0) {
        log.error(
            "Spool disk threshold exceeded. Deleted {} oldest spool files to recover space.",
            deleted);
        if (meterRegistry != null) {
          meterRegistry.counter("location.history.spool.deleted.files").increment(deleted);
        }
      }
    } catch (Exception e) {
      log.warn("Failed to enforce spool disk budget: {}", e.toString());
    }
  }

  private SpoolRecord toRecord(LocationHistory h) {
    SpoolRecord r = new SpoolRecord();
    r.setDriverId(h.getDriver() != null ? h.getDriver().getId() : null);
    r.setDispatchId(h.getDispatch() != null ? h.getDispatch().getId() : null);
    r.setLatitude(h.getLatitude());
    r.setLongitude(h.getLongitude());
    r.setLocationName(h.getLocationName());
    r.setEventTime(h.getEventTime());
    r.setTimestamp(h.getTimestamp());
    r.setUpdatedAt(h.getUpdatedAt());
    r.setIsOnline(h.getIsOnline());
    r.setSpeed(h.getSpeed());
    r.setBatteryLevel(h.getBatteryLevel());
    r.setSource(h.getSource());
    r.setHeading(h.getHeading());
    r.setAccuracyMeters(h.getAccuracyMeters());
    r.setLocationSource(h.getLocationSource());
    r.setNetType(h.getNetType());
    r.setAppVersionCode(h.getAppVersionCode());
    r.setPointId(h.getPointId());
    r.setSeq(h.getSeq());
    r.setSessionId(h.getSessionId());
    return r;
  }

  private LocationHistory toLocationHistory(SpoolRecord r) {
    LocationHistory h = new LocationHistory();
    if (r.getDriverId() != null) {
      Driver d = new Driver();
      d.setId(r.getDriverId());
      h.setDriver(d);
    }
    if (r.getDispatchId() != null) {
      Dispatch d = new Dispatch();
      d.setId(r.getDispatchId());
      h.setDispatch(d);
    }
    h.setLatitude(r.getLatitude());
    h.setLongitude(r.getLongitude());
    h.setLocationName(r.getLocationName());
    h.setEventTime(r.getEventTime());
    h.setTimestamp(r.getTimestamp());
    h.setUpdatedAt(r.getUpdatedAt());
    h.setIsOnline(r.getIsOnline());
    h.setSpeed(r.getSpeed());
    h.setBatteryLevel(r.getBatteryLevel());
    h.setSource(r.getSource());
    h.setHeading(r.getHeading());
    h.setAccuracyMeters(r.getAccuracyMeters());
    h.setLocationSource(r.getLocationSource());
    h.setNetType(r.getNetType());
    h.setAppVersionCode(r.getAppVersionCode());
    h.setPointId(r.getPointId());
    h.setSeq(r.getSeq());
    h.setSessionId(r.getSessionId());
    return h;
  }

  private String safeJson(SpoolRecord r) {
    try {
      return objectMapper.writeValueAsString(r);
    } catch (JsonProcessingException e) {
      throw new IllegalStateException("Failed to serialize spool record", e);
    }
  }

  private SpoolRecord safeParse(String line) {
    try {
      return objectMapper.readValue(line, SpoolRecord.class);
    } catch (Exception e) {
      log.warn("Skip invalid spool line: {}", e.toString());
      return null;
    }
  }

  private long safeFileSize(Path p) {
    try {
      return Files.size(p);
    } catch (Exception e) {
      return 0L;
    }
  }

  private long safeLastModified(Path p) {
    try {
      return Files.getLastModifiedTime(p).toMillis();
    } catch (Exception e) {
      return Long.MAX_VALUE;
    }
  }

  @Data
  private static class SpoolRecord {
    private Long driverId;
    private Long dispatchId;
    private Double latitude;
    private Double longitude;
    private String locationName;
    private LocalDateTime eventTime;
    private LocalDateTime timestamp;
    private LocalDateTime updatedAt;
    private Boolean isOnline;
    private Double speed;
    private Integer batteryLevel;
    private String source;
    private Double heading;
    private Double accuracyMeters;
    private String locationSource;
    private String netType;
    private Long appVersionCode;
    private String pointId;
    private Long seq;
    private String sessionId;
  }
}
