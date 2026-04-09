package com.svtrucking.logistics.controller.admin;

import com.svtrucking.logistics.core.ApiResponse;
import com.svtrucking.logistics.dto.attendance.AttendanceDto;
import com.svtrucking.logistics.dto.attendance.AttendanceRequest;
import com.svtrucking.logistics.dto.attendance.AttendanceSummaryDto;
import com.svtrucking.logistics.dto.attendance.BulkPermissionRequest;
import com.svtrucking.logistics.model.DriverAttendance;
import com.svtrucking.logistics.service.DriverAttendanceService;
import org.springframework.data.domain.Page;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDate;
import java.time.format.DateTimeFormatter;
import java.util.List;

@RestController
@RequestMapping("/api/admin/drivers")
public class DriverAttendanceController {
  private final DriverAttendanceService attendanceService;

  private static final DateTimeFormatter DATE_FMT = DateTimeFormatter.ofPattern("yyyy-MM-dd");
  private static final DateTimeFormatter TIME_FMT = DateTimeFormatter.ofPattern("HH:mm");

  public DriverAttendanceController(DriverAttendanceService attendanceService) {
    this.attendanceService = attendanceService;
  }

  @PostMapping("/{driverId}/attendance")
  public ResponseEntity<ApiResponse<AttendanceDto>> create(@PathVariable Long driverId, @RequestBody AttendanceRequest req) {
    AttendanceDto dto = attendanceService.create(driverId, req);
    return ResponseEntity.ok(ApiResponse.ok("Attendance created", dto));
  }

  @PostMapping("/{driverId}/attendance/permission-range")
  public ResponseEntity<ApiResponse<List<AttendanceDto>>> bulkPermission(
      @PathVariable Long driverId,
      @RequestBody BulkPermissionRequest req
  ) {
    List<AttendanceDto> dtos = attendanceService.createPermissionRange(driverId, req.getStatus(), req.getFromDate(), req.getToDate(), req.getNotes());
    return ResponseEntity.ok(ApiResponse.ok("Permission range processed", dtos));
  }

  @PutMapping("/attendance/{id}")
  public ResponseEntity<ApiResponse<AttendanceDto>> update(@PathVariable Long id, @RequestBody AttendanceRequest req) {
    DriverAttendance updated = attendanceService.update(id, req);
    AttendanceDto dto = new AttendanceDto();
    dto.setId(updated.getId());
    dto.setDriverId(updated.getDriver() != null ? updated.getDriver().getId() : null);
    dto.setDate(updated.getDate() != null ? updated.getDate().format(DATE_FMT) : null);
    dto.setStatus(updated.getStatus());
  dto.setCheckInTime(updated.getCheckInTime() != null ? updated.getCheckInTime().format(TIME_FMT) : null);
  dto.setCheckOutTime(updated.getCheckOutTime() != null ? updated.getCheckOutTime().format(TIME_FMT) : null);
    dto.setHoursWorked(updated.getHoursWorked());
    dto.setNotes(updated.getNotes());
    return ResponseEntity.ok(ApiResponse.ok("Attendance updated", dto));
  }

  @GetMapping("/{driverId}/attendance")
  public ResponseEntity<ApiResponse<List<AttendanceDto>>> list(@PathVariable Long driverId,
                                                  @RequestParam int year,
                                                  @RequestParam int month) {
    return ResponseEntity.ok(ApiResponse.ok("Attendance list fetched", attendanceService.list(driverId, year, month)));
  }

  @GetMapping("/{driverId}/attendance/summary")
  public ResponseEntity<ApiResponse<AttendanceSummaryDto>> summary(@PathVariable Long driverId,
                                                      @RequestParam int year,
                                                      @RequestParam int month) {
    return ResponseEntity.ok(ApiResponse.ok("Attendance summary fetched", attendanceService.summary(driverId, year, month)));
  }

  @GetMapping("/{driverId}/attendance/date/{date}")
  public ResponseEntity<ApiResponse<AttendanceDto>> getByDate(@PathVariable Long driverId,
                                                 @PathVariable String date) {
    AttendanceDto dto = attendanceService.getByDate(driverId, LocalDate.parse(date, DATE_FMT));
    if (dto == null) return ResponseEntity.status(404).body(ApiResponse.fail("Attendance not found"));
    return ResponseEntity.ok(ApiResponse.ok("Attendance found", dto));
  }

  @DeleteMapping("/attendance/{id}")
  public ResponseEntity<ApiResponse<String>> delete(@PathVariable Long id) {
    attendanceService.delete(id);
    return ResponseEntity.ok(ApiResponse.success("Attendance record deleted"));
  }

  // Aggregated list across drivers (or specific driver if driverId provided)
  @GetMapping("/attendance")
  public ResponseEntity<ApiResponse<com.svtrucking.logistics.dto.requests.PageResponse<AttendanceDto>>> listAll(
      @RequestParam(required = false) Integer year,
      @RequestParam(required = false) Integer month,
      @RequestParam(required = false) Long driverId,
      @RequestParam(required = false, defaultValue = "true") boolean permissionOnly,
      @RequestParam(required = false) String fromDate,
      @RequestParam(required = false) String toDate,
      @RequestParam(defaultValue = "0") int page,
      @RequestParam(defaultValue = "20") int size
  ) {
    Page<AttendanceDto> data = attendanceService.listAllPaged(year, month, permissionOnly, driverId, page, size, fromDate, toDate);
    return ResponseEntity.ok(ApiResponse.ok("Attendance list fetched", new com.svtrucking.logistics.dto.requests.PageResponse<>(data)));
  }
}
