package com.svtrucking.logistics.repository;

import com.svtrucking.logistics.model.DriverAttendance;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.time.LocalDate;
import java.util.List;
import java.util.Optional;

public interface DriverAttendanceRepository extends JpaRepository<DriverAttendance, Long> {

  @Query("select a from DriverAttendance a where a.driver.id = :driverId and YEAR(a.date) = :year and MONTH(a.date) = :month order by a.date desc")
  List<DriverAttendance> findByDriverAndMonth(@Param("driverId") Long driverId,
                                              @Param("year") int year,
                                              @Param("month") int month);

  // Paged variants
  @Query("select a from DriverAttendance a where a.driver.id = :driverId and YEAR(a.date) = :year and MONTH(a.date) = :month order by a.date desc")
  Page<DriverAttendance> findByDriverAndMonth(@Param("driverId") Long driverId,
                                              @Param("year") int year,
                                              @Param("month") int month,
                                              Pageable pageable);

  @Query("select a from DriverAttendance a where a.driver.id = :driverId and YEAR(a.date) = :year and MONTH(a.date) = :month and upper(a.status) in ('ON_LEAVE','OFF_DUTY') order by a.date desc")
  Page<DriverAttendance> findPermissionOnlyByDriverAndMonth(@Param("driverId") Long driverId,
                                                            @Param("year") int year,
                                                            @Param("month") int month,
                                                            Pageable pageable);

  @Query("select a from DriverAttendance a where a.driver.id = :driverId and a.date = :date")
  Optional<DriverAttendance> findByDriverAndDate(@Param("driverId") Long driverId, @Param("date") LocalDate date);

  @Query("select a from DriverAttendance a where YEAR(a.date) = :year and MONTH(a.date) = :month order by a.date desc")
  List<DriverAttendance> findByMonth(@Param("year") int year,
                                     @Param("month") int month);

  @Query("select a from DriverAttendance a where YEAR(a.date) = :year and MONTH(a.date) = :month order by a.date desc")
  Page<DriverAttendance> findByMonth(@Param("year") int year,
                                     @Param("month") int month,
                                     Pageable pageable);

  @Query("select a from DriverAttendance a where YEAR(a.date) = :year and MONTH(a.date) = :month and upper(a.status) in ('ON_LEAVE','OFF_DUTY') order by a.date desc")
  Page<DriverAttendance> findPermissionOnlyByMonth(@Param("year") int year,
                                                   @Param("month") int month,
                                                   Pageable pageable);

  // Date range variants (inclusive)
  @Query("select a from DriverAttendance a where a.driver.id = :driverId and a.date between :from and :to order by a.date desc")
  Page<DriverAttendance> findByDriverBetween(@Param("driverId") Long driverId,
                                             @Param("from") LocalDate from,
                                             @Param("to") LocalDate to,
                                             Pageable pageable);

  @Query("select a from DriverAttendance a where a.driver.id = :driverId and a.date between :from and :to and upper(a.status) in ('ON_LEAVE','OFF_DUTY') order by a.date desc")
  Page<DriverAttendance> findPermissionOnlyByDriverBetween(@Param("driverId") Long driverId,
                                                           @Param("from") LocalDate from,
                                                           @Param("to") LocalDate to,
                                                           Pageable pageable);

  @Query("select a from DriverAttendance a where a.date between :from and :to order by a.date desc")
  Page<DriverAttendance> findByBetween(@Param("from") LocalDate from,
                                       @Param("to") LocalDate to,
                                       Pageable pageable);

  @Query("select a from DriverAttendance a where a.date between :from and :to and upper(a.status) in ('ON_LEAVE','OFF_DUTY') order by a.date desc")
  Page<DriverAttendance> findPermissionOnlyByBetween(@Param("from") LocalDate from,
                                                     @Param("to") LocalDate to,
                                                     Pageable pageable);
}
