package com.svtrucking.logistics.repository;

import com.svtrucking.logistics.model.DriverGroup;
import java.util.List;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

@Repository
public interface DriverGroupRepository extends JpaRepository<DriverGroup, Long> {
  List<DriverGroup> findByActiveTrueOrderByNameAsc();
}
