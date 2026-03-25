package com.svtrucking.logistics.repository;

import com.svtrucking.logistics.model.DriverMonthlyPerformance;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface DriverMonthlyPerformanceRepository extends JpaRepository<DriverMonthlyPerformance, Long> {

  /**
   * Find performance record for a specific driver and month
   */
  Optional<DriverMonthlyPerformance> findByDriverIdAndYearAndMonth(Long driverId, Integer year, Integer month);

  /**
   * Find all performance records for a driver, ordered by year/month descending
   */
  List<DriverMonthlyPerformance> findByDriverIdOrderByYearDescMonthDesc(Long driverId);

  /**
   * Find current month performance for a driver
   */
  @Query("SELECT dmp FROM DriverMonthlyPerformance dmp " +
         "WHERE dmp.driver.id = :driverId " +
         "ORDER BY dmp.year DESC, dmp.month DESC " +
         "LIMIT 1")
  Optional<DriverMonthlyPerformance> findCurrentMonthPerformance(Long driverId);

  /**
   * Find all drivers ranked by performance score for a specific month
   */
  @Query("SELECT dmp FROM DriverMonthlyPerformance dmp " +
         "WHERE dmp.year = :year AND dmp.month = :month " +
         "ORDER BY dmp.performanceScore DESC, dmp.onTimePercent DESC")
  List<DriverMonthlyPerformance> findLeaderboardForMonth(Integer year, Integer month);

  /**
   * Find top N performers for a specific month
   */
  @Query("SELECT dmp FROM DriverMonthlyPerformance dmp " +
         "WHERE dmp.year = :year AND dmp.month = :month " +
         "ORDER BY dmp.performanceScore DESC, dmp.onTimePercent DESC " +
         "LIMIT :limit")
  List<DriverMonthlyPerformance> findTopPerformers(Integer year, Integer month, Integer limit);

  /**
   * Find performance history for last N months for a driver
   */
  @Query("SELECT dmp FROM DriverMonthlyPerformance dmp " +
         "WHERE dmp.driver.id = :driverId " +
         "ORDER BY dmp.year DESC, dmp.month DESC " +
         "LIMIT :months")
  List<DriverMonthlyPerformance> findRecentMonthsPerformance(Long driverId, Integer months);

  /**
   * Check if performance record exists for driver and month
   */
  boolean existsByDriverIdAndYearAndMonth(Long driverId, Integer year, Integer month);

  /**
   * Find all finalized performance records for a month
   */
  List<DriverMonthlyPerformance> findByYearAndMonthAndIsFinalizedTrue(Integer year, Integer month);

  /**
   * Find all non-finalized performance records
   */
  List<DriverMonthlyPerformance> findByIsFinalizedFalse();
}
