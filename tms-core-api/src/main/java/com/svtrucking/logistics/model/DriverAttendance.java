package com.svtrucking.logistics.model;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.FetchType;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.Index;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.ManyToOne;
import jakarta.persistence.PreUpdate;
import jakarta.persistence.Table;
import java.time.LocalDate;
import java.time.LocalTime;
import java.time.OffsetDateTime;

@Entity
@Table(name = "driver_attendance",
    indexes = {
        @Index(name = "idx_attendance_driver_date", columnList = "driver_id,attendance_date")
    })
public class DriverAttendance {
  @Id
  @GeneratedValue(strategy = GenerationType.IDENTITY)
  private Long id;

  @ManyToOne(fetch = FetchType.LAZY, optional = false)
  @JoinColumn(name = "driver_id", nullable = false)
  private Driver driver;

  @Column(name = "attendance_date", nullable = false)
  private LocalDate date;

  @Column(name = "status", nullable = false, length = 32)
  private String status; // PRESENT, ABSENT, LATE, ON_LEAVE, OFF_DUTY

  @Column(name = "check_in_time")
  private LocalTime checkInTime;

  @Column(name = "check_out_time")
  private LocalTime checkOutTime;

  @Column(name = "hours_worked")
  private Double hoursWorked;

  @Column(name = "notes", length = 2000)
  private String notes;

  @Column(name = "created_at", nullable = false)
  private OffsetDateTime createdAt = OffsetDateTime.now();

  @Column(name = "updated_at")
  private OffsetDateTime updatedAt;

  @PreUpdate
  public void onUpdate() {
    this.updatedAt = OffsetDateTime.now();
  }

  // Getters and setters
  public Long getId() { return id; }
  public void setId(Long id) { this.id = id; }
  public Driver getDriver() { return driver; }
  public void setDriver(Driver driver) { this.driver = driver; }
  public LocalDate getDate() { return date; }
  public void setDate(LocalDate date) { this.date = date; }
  public String getStatus() { return status; }
  public void setStatus(String status) { this.status = status; }
  public LocalTime getCheckInTime() { return checkInTime; }
  public void setCheckInTime(LocalTime checkInTime) { this.checkInTime = checkInTime; }
  public LocalTime getCheckOutTime() { return checkOutTime; }
  public void setCheckOutTime(LocalTime checkOutTime) { this.checkOutTime = checkOutTime; }
  public Double getHoursWorked() { return hoursWorked; }
  public void setHoursWorked(Double hoursWorked) { this.hoursWorked = hoursWorked; }
  public String getNotes() { return notes; }
  public void setNotes(String notes) { this.notes = notes; }
  public OffsetDateTime getCreatedAt() { return createdAt; }
  public void setCreatedAt(OffsetDateTime createdAt) { this.createdAt = createdAt; }
  public OffsetDateTime getUpdatedAt() { return updatedAt; }
  public void setUpdatedAt(OffsetDateTime updatedAt) { this.updatedAt = updatedAt; }
}
