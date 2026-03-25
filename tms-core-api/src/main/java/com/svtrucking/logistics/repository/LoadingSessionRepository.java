package com.svtrucking.logistics.repository;

import com.svtrucking.logistics.model.LoadingSession;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.Optional;

public interface LoadingSessionRepository extends JpaRepository<LoadingSession, Long> {

  Optional<LoadingSession> findByDispatchId(Long dispatchId);

  Optional<LoadingSession> findByQueueId(Long queueId);
}
