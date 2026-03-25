package com.svtrucking.logistics.service;

import java.time.LocalDateTime;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import com.svtrucking.logistics.repository.RefreshTokenRepository;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Service;

@Service
@RequiredArgsConstructor
@Slf4j
public class RefreshTokenCleanupService {

  private final RefreshTokenRepository repository;
  
  @org.springframework.beans.factory.annotation.Value("${spring.task.scheduling.enabled:true}")
  private boolean schedulingEnabled;

  // Run daily at 03:00 server time
  @Scheduled(cron = "0 0 3 * * *")
  public void cleanupExpiredTokens() {
    if (!schedulingEnabled) {
      log.info("Skipping refresh-token cleanup because scheduling is disabled (export profile)");
      return;
    }
    LocalDateTime now = LocalDateTime.now();
    try {
      int deleted = repository.deleteByExpiresAtBefore(now);
      if (deleted > 0) log.info("Cleaned up {} expired refresh tokens", deleted);
    } catch (Exception e) {
      log.error("Failed to cleanup expired refresh tokens: {}", e.toString(), e);
    }
  }
}
