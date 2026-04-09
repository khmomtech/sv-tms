package com.svtrucking.logistics.repository;

import com.svtrucking.logistics.model.AuditTrail;
import java.time.LocalDateTime;
import java.util.List;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

@Repository
public interface AuditTrailRepository extends JpaRepository<AuditTrail, Long> {

  List<AuditTrail> findByUserIdOrderByTimestampDesc(Long userId);

  List<AuditTrail> findByUsernameOrderByTimestampDesc(String username);

  List<AuditTrail> findByActionOrderByTimestampDesc(String action);

  List<AuditTrail> findByResourceTypeOrderByTimestampDesc(String resourceType);

  @Query(
      "SELECT a FROM AuditTrail a WHERE a.timestamp BETWEEN :startDate AND :endDate ORDER BY a.timestamp DESC")
  List<AuditTrail> findByTimestampBetweenOrderByTimestampDesc(
      @Param("startDate") LocalDateTime startDate, @Param("endDate") LocalDateTime endDate);

  @Query(
      "SELECT a FROM AuditTrail a WHERE a.username = :username AND a.action = :action ORDER BY a.timestamp DESC")
  List<AuditTrail> findByUsernameAndActionOrderByTimestampDesc(
      @Param("username") String username, @Param("action") String action);
}
