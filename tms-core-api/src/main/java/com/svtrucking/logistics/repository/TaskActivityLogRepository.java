package com.svtrucking.logistics.repository;

import com.svtrucking.logistics.model.TaskActivityLog;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;

@Repository
public interface TaskActivityLogRepository extends JpaRepository<TaskActivityLog, Long> {

  // Find logs by task
  List<TaskActivityLog> findByTaskIdOrderByCreatedAtDesc(Long taskId);
  Optional<TaskActivityLog> findFirstByTaskIdOrderByCreatedAtDesc(Long taskId);

  Page<TaskActivityLog> findByTaskId(Long taskId, Pageable pageable);

  // Find logs by user
  List<TaskActivityLog> findByUserIdOrderByCreatedAtDesc(Long userId);

  // Find logs by action type
  List<TaskActivityLog> findByActionOrderByCreatedAtDesc(String action);

  // Find logs by task and action
  List<TaskActivityLog> findByTaskIdAndActionOrderByCreatedAtDesc(Long taskId, String action);

  // Find recent logs
  List<TaskActivityLog> findByCreatedAtAfterOrderByCreatedAtDesc(LocalDateTime since);

  // Find logs for multiple tasks
  List<TaskActivityLog> findByTaskIdInOrderByCreatedAtDesc(List<Long> taskIds);
}
