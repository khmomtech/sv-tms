package com.svtrucking.logistics.repository;

import com.svtrucking.logistics.model.PMScheduleHistory;
import org.springframework.data.jpa.repository.JpaRepository;
import java.util.List;

public interface PMScheduleHistoryRepository extends JpaRepository<PMScheduleHistory, Long> {

  List<PMScheduleHistory> findByPmScheduleIdOrderByPerformedAtDesc(Long pmScheduleId);

  List<PMScheduleHistory> findByVehicleIdOrderByPerformedAtDesc(Long vehicleId);

  List<PMScheduleHistory> findByWorkOrderId(Long workOrderId);
}
