package com.svtrucking.logistics.dto.attendance;

import java.util.Map;

public class AttendanceSummaryDto {
  private Long driverId;
  private int year;
  private int month;
  private Map<String, Long> byStatus; // e.g., {"ON_LEAVE": 2, "OFF_DUTY": 1}

  public Long getDriverId() { return driverId; }
  public void setDriverId(Long driverId) { this.driverId = driverId; }
  public int getYear() { return year; }
  public void setYear(int year) { this.year = year; }
  public int getMonth() { return month; }
  public void setMonth(int month) { this.month = month; }
  public Map<String, Long> getByStatus() { return byStatus; }
  public void setByStatus(Map<String, Long> byStatus) { this.byStatus = byStatus; }
}
