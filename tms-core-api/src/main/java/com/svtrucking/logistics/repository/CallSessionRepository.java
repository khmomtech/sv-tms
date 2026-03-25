package com.svtrucking.logistics.repository;

import com.svtrucking.logistics.model.CallSession;
import com.svtrucking.logistics.model.CallSession.Status;
import java.util.List;
import java.util.Optional;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

@Repository
public interface CallSessionRepository extends JpaRepository<CallSession, Long> {

  Optional<CallSession> findByChannelName(String channelName);

  /** Find the latest active/ringing session for a driver. */
  @Query("SELECT c FROM CallSession c WHERE c.driverId = :driverId "
      + "AND c.status IN ('RINGING','ACTIVE') ORDER BY c.startedAt DESC")
  List<CallSession> findActiveByDriverId(@Param("driverId") Long driverId);

  /** Check if a driver has any call currently in RINGING or ACTIVE state. */
  boolean existsByDriverIdAndStatusIn(Long driverId, List<Status> statuses);

  List<CallSession> findByDriverIdOrderByStartedAtDesc(Long driverId);
}
