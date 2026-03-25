package com.svtrucking.logistics.service;

import com.svtrucking.logistics.repository.LocationHistoryRepository;
import java.time.LocalDateTime;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Service;

@Service
@Slf4j
@RequiredArgsConstructor
public class LocationHistoryMysqlPurgeService {

  private final LocationHistoryRepository locationHistoryRepository;

  @Value("${app.scheduling.location.enabled:true}")
  private boolean schedulingEnabled;

  @Value("${location.history.mysql.purge.enabled:false}")
  private boolean purgeEnabled;

  @Value("${location.history.mysql.purge.retention-days:1}")
  private int retentionDays;

  @Value("${location.history.mysql.purge.batch-size:5000}")
  private int batchSize;

  @Scheduled(fixedDelayString = "${location.history.mysql.purge.interval-ms:60000}")
  public void purgeOldRows() {
    if (!schedulingEnabled || !purgeEnabled) {
      return;
    }

    LocalDateTime cutoff = LocalDateTime.now().minusDays(Math.max(0, retentionDays));
    int safeBatchSize = Math.max(100, batchSize);

    try {
      int deleted = locationHistoryRepository.deleteOldHistoryBatch(cutoff, safeBatchSize);
      if (deleted > 0) {
        long remaining = locationHistoryRepository.countByEventTimeBefore(cutoff);
        log.warn(
            "Purged {} MySQL location_history rows (cutoff={} retentionDays={}). Remaining old rows={}",
            deleted,
            cutoff,
            retentionDays,
            remaining);
      }
    } catch (Exception e) {
      log.error("MySQL location_history purge failed: {}", e.toString(), e);
    }
  }
}
