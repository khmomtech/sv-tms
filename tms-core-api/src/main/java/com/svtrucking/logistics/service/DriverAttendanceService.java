package com.svtrucking.logistics.service;

import com.svtrucking.logistics.dto.attendance.AttendanceDto;
import com.svtrucking.logistics.dto.attendance.AttendanceRequest;
import com.svtrucking.logistics.dto.attendance.AttendanceSummaryDto;
import com.svtrucking.logistics.model.Driver;
import com.svtrucking.logistics.model.DriverAttendance;
import com.svtrucking.logistics.repository.DriverAttendanceRepository;
import com.svtrucking.logistics.repository.DriverRepository;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDate;
import java.time.LocalTime;
import java.time.format.DateTimeFormatter;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.stream.Collectors;

@Service
public class DriverAttendanceService {
  private final DriverAttendanceRepository attendanceRepo;
  private final DriverRepository driverRepo;

  private static final DateTimeFormatter DATE_FMT = DateTimeFormatter.ofPattern("yyyy-MM-dd");
  private static final DateTimeFormatter TIME_FMT = DateTimeFormatter.ofPattern("HH:mm");

  public DriverAttendanceService(DriverAttendanceRepository attendanceRepo, DriverRepository driverRepo) {
    this.attendanceRepo = attendanceRepo;
    this.driverRepo = driverRepo;
  }

  @Transactional
  public AttendanceDto create(Long driverId, AttendanceRequest req) {
    Driver driver = driverRepo.findById(driverId)
        .orElseThrow(() -> new IllegalArgumentException("Driver not found: " + driverId));

    LocalDate date = LocalDate.parse(req.getDate(), DATE_FMT);
    Optional<DriverAttendance> existing = attendanceRepo.findByDriverAndDate(driverId, date);
    if (existing.isPresent()) {
      // For idempotency: update existing instead of failing hard
      return toDto(update(existing.get().getId(), req));
    }

    DriverAttendance a = new DriverAttendance();
    a.setDriver(driver);
    a.setDate(date);
    a.setStatus(req.getStatus());
    if (req.getCheckInTime() != null && !req.getCheckInTime().isBlank()) {
      a.setCheckInTime(LocalTime.parse(req.getCheckInTime(), TIME_FMT));
    }
    if (req.getCheckOutTime() != null && !req.getCheckOutTime().isBlank()) {
      a.setCheckOutTime(LocalTime.parse(req.getCheckOutTime(), TIME_FMT));
    }
    a.setHoursWorked(req.getHoursWorked());
    a.setNotes(req.getNotes());
    return toDto(attendanceRepo.save(a));
  }

  /**
   * Bulk create permission (ON_LEAVE / OFF_DUTY) attendance records across a date range (inclusive).
   * If a record for a given date already exists it will be updated to the requested status/notes (idempotent).
   * Guards: max 60 days, status must be permission type.
   */
  @Transactional
  public List<AttendanceDto> createPermissionRange(Long driverId, String status, String fromDate, String toDate, String notes) {
    if (status == null) throw new IllegalArgumentException("Status required");
    String upper = status.toUpperCase();
    if (!"ON_LEAVE".equals(upper) && !"OFF_DUTY".equals(upper)) {
      throw new IllegalArgumentException("Bulk permission range only supports ON_LEAVE or OFF_DUTY");
    }
    Driver driver = driverRepo.findById(driverId)
        .orElseThrow(() -> new IllegalArgumentException("Driver not found: " + driverId));
    LocalDate start = LocalDate.parse(fromDate, DATE_FMT);
    LocalDate end = LocalDate.parse(toDate, DATE_FMT);
    if (end.isBefore(start)) throw new IllegalArgumentException("toDate must be on or after fromDate");
    if (start.plusDays(60).isBefore(end)) throw new IllegalArgumentException("Date range too large (max 60 days)");

    LocalDate cursor = start;
    List<AttendanceDto> created = new java.util.ArrayList<>();
    while (!cursor.isAfter(end)) {
      Optional<DriverAttendance> existing = attendanceRepo.findByDriverAndDate(driverId, cursor);
      DriverAttendance a;
      if (existing.isPresent()) {
        a = existing.get();
        a.setStatus(upper);
        a.setNotes(notes);
      } else {
        a = new DriverAttendance();
        a.setDriver(driver);
        a.setDate(cursor);
        a.setStatus(upper);
        a.setNotes(notes);
      }
      created.add(toDto(attendanceRepo.save(a)));
      cursor = cursor.plusDays(1);
    }
    return created;
  }

  @Transactional
  public DriverAttendance update(Long id, AttendanceRequest req) {
    DriverAttendance a = attendanceRepo.findById(id)
        .orElseThrow(() -> new IllegalArgumentException("Attendance not found: " + id));
    if (req.getDate() != null && !req.getDate().isBlank()) {
      a.setDate(LocalDate.parse(req.getDate(), DATE_FMT));
    }
    if (req.getStatus() != null && !req.getStatus().isBlank()) {
      a.setStatus(req.getStatus());
    }
    if (req.getCheckInTime() != null) {
      a.setCheckInTime(req.getCheckInTime().isBlank() ? null : LocalTime.parse(req.getCheckInTime(), TIME_FMT));
    }
    if (req.getCheckOutTime() != null) {
      a.setCheckOutTime(req.getCheckOutTime().isBlank() ? null : LocalTime.parse(req.getCheckOutTime(), TIME_FMT));
    }
    a.setHoursWorked(req.getHoursWorked());
    a.setNotes(req.getNotes());
    return attendanceRepo.save(a);
  }

  @Transactional(readOnly = true)
  public List<AttendanceDto> list(Long driverId, int year, int month) {
    return attendanceRepo.findByDriverAndMonth(driverId, year, month)
        .stream().map(this::toDto).collect(Collectors.toList());
  }

  @Transactional(readOnly = true)
  public List<AttendanceDto> listAll(int year, int month, boolean permissionOnly, Long driverId) {
    List<DriverAttendance> list;
    if (driverId != null) {
      list = attendanceRepo.findByDriverAndMonth(driverId, year, month);
    } else {
      list = attendanceRepo.findByMonth(year, month);
    }

    if (permissionOnly) {
      list = list.stream()
          .filter(a -> {
            String s = a.getStatus() != null ? a.getStatus().toUpperCase() : "";
            return "ON_LEAVE".equals(s) || "OFF_DUTY".equals(s);
          })
          .collect(Collectors.toList());
    }

    return list.stream().map(this::toDto).collect(Collectors.toList());
  }

  @Transactional(readOnly = true)
  public Page<AttendanceDto> listAllPaged(Integer year, Integer month, boolean permissionOnly, Long driverId, int page, int size,
                                          String fromDate, String toDate) {
    int safePage = Math.max(page, 0);
    int safeSize = Math.min(Math.max(size, 1), 200);
    Pageable pageable = PageRequest.of(safePage, safeSize);

    Page<DriverAttendance> result;
    // Prefer explicit date range if provided
    if (fromDate != null && !fromDate.isBlank() && toDate != null && !toDate.isBlank()) {
      LocalDate from = LocalDate.parse(fromDate, DATE_FMT);
      LocalDate to = LocalDate.parse(toDate, DATE_FMT);
      if (to.isBefore(from)) {
        LocalDate tmp = from; from = to; to = tmp; // swap to keep inclusive ordering
      }
      if (driverId != null) {
        result = permissionOnly
            ? attendanceRepo.findPermissionOnlyByDriverBetween(driverId, from, to, pageable)
            : attendanceRepo.findByDriverBetween(driverId, from, to, pageable);
      } else {
        result = permissionOnly
            ? attendanceRepo.findPermissionOnlyByBetween(from, to, pageable)
            : attendanceRepo.findByBetween(from, to, pageable);
      }
    } else {
      // Fallback to year/month
      int y = year != null ? year : LocalDate.now().getYear();
      int m = month != null ? month : LocalDate.now().getMonthValue();
      if (driverId != null) {
        result = permissionOnly
            ? attendanceRepo.findPermissionOnlyByDriverAndMonth(driverId, y, m, pageable)
            : attendanceRepo.findByDriverAndMonth(driverId, y, m, pageable);
      } else {
        result = permissionOnly
            ? attendanceRepo.findPermissionOnlyByMonth(y, m, pageable)
            : attendanceRepo.findByMonth(y, m, pageable);
      }
    }

    return result.map(this::toDto);
  }

  @Transactional(readOnly = true)
  public AttendanceDto getByDate(Long driverId, LocalDate date) {
    return attendanceRepo.findByDriverAndDate(driverId, date)
        .map(this::toDto)
        .orElse(null);
  }

  @Transactional
  public void delete(Long id) {
    attendanceRepo.deleteById(id);
  }

  @Transactional(readOnly = true)
  public AttendanceSummaryDto summary(Long driverId, int year, int month) {
    List<DriverAttendance> list = attendanceRepo.findByDriverAndMonth(driverId, year, month);
    Map<String, Long> byStatus = list.stream().collect(Collectors.groupingBy(DriverAttendance::getStatus, Collectors.counting()));
    AttendanceSummaryDto dto = new AttendanceSummaryDto();
    dto.setDriverId(driverId);
    dto.setYear(year);
    dto.setMonth(month);
    dto.setByStatus(byStatus);
    return dto;
  }

  private AttendanceDto toDto(DriverAttendance a) {
    AttendanceDto dto = new AttendanceDto();
    dto.setId(a.getId());
    dto.setDriverId(a.getDriver() != null ? a.getDriver().getId() : null);
    if (a.getDriver() != null) {
      // Prefer display name if present, else build from first/last
      String name = a.getDriver().getName();
      if (name == null || name.isBlank()) {
        name = a.getDriver().getFullName();
      }
      dto.setDriverName(name);
      var v = a.getDriver().getCurrentAssignedVehicle();
      dto.setTruckPlateNo(v != null ? v.getLicensePlate() : null);
    }
    dto.setDate(a.getDate() != null ? a.getDate().format(DATE_FMT) : null);
    dto.setStatus(a.getStatus());
    dto.setCheckInTime(a.getCheckInTime() != null ? a.getCheckInTime().format(TIME_FMT) : null);
    dto.setCheckOutTime(a.getCheckOutTime() != null ? a.getCheckOutTime().format(TIME_FMT) : null);
    dto.setHoursWorked(a.getHoursWorked());
    dto.setNotes(a.getNotes());
    return dto;
  }
}
