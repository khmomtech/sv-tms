package com.svtrucking.logistics.service;

/**
 * Cache statistics data class.
 * Contains information about cache performance and memory usage.
 */
public class CacheStats {
  public final long entryCount;
  public final long memoryUsageBytes;

  public CacheStats(long entryCount, long memoryUsageBytes) {
    this.entryCount = entryCount;
    this.memoryUsageBytes = memoryUsageBytes;
  }

  public double getMemoryUsageMB() {
    return memoryUsageBytes / (1024.0 * 1024.0);
  }
}
