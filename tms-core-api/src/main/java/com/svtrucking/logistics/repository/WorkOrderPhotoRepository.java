package com.svtrucking.logistics.repository;

import com.svtrucking.logistics.model.WorkOrderPhoto;
import com.svtrucking.logistics.enums.PhotoType;
import org.springframework.data.jpa.repository.JpaRepository;
import java.util.List;
import java.util.Optional;

public interface WorkOrderPhotoRepository extends JpaRepository<WorkOrderPhoto, Long> {

  List<WorkOrderPhoto> findByWorkOrderId(Long workOrderId);

  List<WorkOrderPhoto> findByTaskId(Long taskId);

  boolean existsByTaskId(Long taskId);

  List<WorkOrderPhoto> findByWorkOrderIdAndPhotoType(Long workOrderId, PhotoType photoType);

  Optional<WorkOrderPhoto> findByIdAndWorkOrderId(Long id, Long workOrderId);

  void deleteByWorkOrderId(Long workOrderId);
}
