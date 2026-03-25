package com.svtrucking.logistics.controller;

import com.svtrucking.logistics.core.ApiResponse;
import com.svtrucking.logistics.dto.DriverMonthlyPerformanceDto;
import com.svtrucking.logistics.model.DriverMonthlyPerformance;
import com.svtrucking.logistics.repository.DriverMonthlyPerformanceRepository;
import com.svtrucking.logistics.repository.DriverRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDate;
import java.util.List;
import java.util.stream.Collectors;

@RestController
@RequestMapping("/api/driver/performance")
@RequiredArgsConstructor
public class DriverPerformanceController {

  private final DriverMonthlyPerformanceRepository performanceRepository;
  private final DriverRepository driverRepository;

  /**
   * Get current month performance for authenticated driver
   */
  @GetMapping("/current")
  @PreAuthorize("hasAnyAuthority('ROLE_DRIVER','ROLE_ADMIN','ROLE_SUPERADMIN')")
  public ResponseEntity<ApiResponse<DriverMonthlyPerformanceDto>> getCurrentMonthPerformance(
      Authentication auth) {
    String username = auth.getName();
    var driver = driverRepository.findByUsername(username)
        .orElseThrow(() -> new RuntimeException("Driver not found"));

    LocalDate now = LocalDate.now();
    var performance = performanceRepository.findByDriverIdAndYearAndMonth(
        driver.getId(), now.getYear(), now.getMonthValue())
        .orElse(null);

    if (performance == null) {
      return ResponseEntity.ok(
          ApiResponse.success("No performance data for current month", null));
    }

    return ResponseEntity.ok(
        ApiResponse.success("Current month performance", 
            DriverMonthlyPerformanceDto.fromEntity(performance)));
  }

  /**
   * Get performance history for authenticated driver
   */
  @GetMapping("/history")
  @PreAuthorize("hasAnyAuthority('ROLE_DRIVER','ROLE_ADMIN','ROLE_SUPERADMIN')")
  public ResponseEntity<ApiResponse<List<DriverMonthlyPerformanceDto>>> getPerformanceHistory(
      Authentication auth,
      @RequestParam(defaultValue = "6") Integer months) {
    String username = auth.getName();
    var driver = driverRepository.findByUsername(username)
        .orElseThrow(() -> new RuntimeException("Driver not found"));

    List<DriverMonthlyPerformance> history = 
        performanceRepository.findRecentMonthsPerformance(driver.getId(), months);

    List<DriverMonthlyPerformanceDto> dtos = history.stream()
        .map(DriverMonthlyPerformanceDto::fromEntity)
        .collect(Collectors.toList());

    return ResponseEntity.ok(
        ApiResponse.success("Performance history retrieved", dtos));
  }

  /**
   * Get specific month performance
   */
  @GetMapping("/{year}/{month}")
  @PreAuthorize("hasAnyAuthority('ROLE_DRIVER','ROLE_ADMIN','ROLE_SUPERADMIN')")
  public ResponseEntity<ApiResponse<DriverMonthlyPerformanceDto>> getMonthPerformance(
      Authentication auth,
      @PathVariable Integer year,
      @PathVariable Integer month) {
    String username = auth.getName();
    var driver = driverRepository.findByUsername(username)
        .orElseThrow(() -> new RuntimeException("Driver not found"));

    var performance = performanceRepository.findByDriverIdAndYearAndMonth(
        driver.getId(), year, month)
        .orElse(null);

    if (performance == null) {
      return ResponseEntity.ok(
          ApiResponse.success("No performance data for specified month", null));
    }

    return ResponseEntity.ok(
        ApiResponse.success("Monthly performance retrieved", 
            DriverMonthlyPerformanceDto.fromEntity(performance)));
  }

  /**
   * Get leaderboard for current month
   */
  @GetMapping("/leaderboard")
  @PreAuthorize("hasAnyAuthority('ROLE_DRIVER','ROLE_ADMIN','ROLE_SUPERADMIN')")
  public ResponseEntity<ApiResponse<List<DriverMonthlyPerformanceDto>>> getLeaderboard(
      @RequestParam(required = false) Integer year,
      @RequestParam(required = false) Integer month,
      @RequestParam(defaultValue = "50") Integer limit) {
    
    LocalDate now = LocalDate.now();
    int targetYear = year != null ? year : now.getYear();
    int targetMonth = month != null ? month : now.getMonthValue();

    List<DriverMonthlyPerformance> leaderboard = 
        performanceRepository.findTopPerformers(targetYear, targetMonth, limit);

    List<DriverMonthlyPerformanceDto> dtos = leaderboard.stream()
        .map(DriverMonthlyPerformanceDto::fromEntity)
        .collect(Collectors.toList());

    return ResponseEntity.ok(
        ApiResponse.success("Leaderboard retrieved", dtos));
  }
}
