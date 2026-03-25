package com.svtrucking.logistics.dto.attendance;

import com.fasterxml.jackson.annotation.JsonIgnoreProperties;

@JsonIgnoreProperties(ignoreUnknown = true)
public class AttendanceRequest {
  private String date; // yyyy-MM-dd
  private String status; // PRESENT, ABSENT, LATE, ON_LEAVE, OFF_DUTY
  private String checkInTime; // HH:mm (optional)
  private String checkOutTime; // HH:mm (optional)
  private Double hoursWorked; // optional
  private String notes; // optional

  public String getDate() { return date; }
  public void setDate(String date) { this.date = date; }
  public String getStatus() { return status; }
  public void setStatus(String status) { this.status = status; }
  public String getCheckInTime() { return checkInTime; }
  public void setCheckInTime(String checkInTime) { this.checkInTime = checkInTime; }
  public String getCheckOutTime() { return checkOutTime; }
  public void setCheckOutTime(String checkOutTime) { this.checkOutTime = checkOutTime; }
  public Double getHoursWorked() { return hoursWorked; }
  public void setHoursWorked(Double hoursWorked) { this.hoursWorked = hoursWorked; }
  public String getNotes() { return notes; }
  public void setNotes(String notes) { this.notes = notes; }
}
