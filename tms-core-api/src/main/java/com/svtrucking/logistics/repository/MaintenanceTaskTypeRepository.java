package com.svtrucking.logistics.repository;

import com.svtrucking.logistics.model.MaintenanceTaskType;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;

public interface MaintenanceTaskTypeRepository extends JpaRepository<MaintenanceTaskType, Long> {
  Page<MaintenanceTaskType> findByNameContainingIgnoreCase(String name, Pageable pageable);
}
