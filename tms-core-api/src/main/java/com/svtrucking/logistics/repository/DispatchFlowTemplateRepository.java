package com.svtrucking.logistics.repository;

import com.svtrucking.logistics.model.DispatchFlowTemplate;
import java.util.Optional;
import org.springframework.data.jpa.repository.JpaRepository;

public interface DispatchFlowTemplateRepository extends JpaRepository<DispatchFlowTemplate, Long> {
  Optional<DispatchFlowTemplate> findByCodeIgnoreCase(String code);

  boolean existsByCodeIgnoreCaseAndActiveTrue(String code);
}
