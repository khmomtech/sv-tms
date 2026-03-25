package com.svtrucking.logistics.dto.attendance;

public class AttendanceDto {
  private Long id;
  private Long driverId;
  private String driverName;
  private String truckPlateNo;
  private String date; // yyyy-MM-dd
  private String status;
  private String checkInTime;
  private String checkOutTime;
  private Double hoursWorked;
  private String notes;

  public Long getId() { return id; }
  public void setId(Long id) { this.id = id; }
  public Long getDriverId() { return driverId; }
  public void setDriverId(Long driverId) { this.driverId = driverId; }
  public String getDriverName() { return driverName; }
  public void setDriverName(String driverName) { this.driverName = driverName; }
  public String getTruckPlateNo() { return truckPlateNo; }
  public void setTruckPlateNo(String truckPlateNo) { this.truckPlateNo = truckPlateNo; }
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
