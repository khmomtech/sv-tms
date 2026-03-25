package com.svtrucking.logistics.repository;

import com.svtrucking.logistics.model.DispatchFlowTemplateVersion;
import java.util.List;
import java.util.Optional;
import org.springframework.data.jpa.repository.EntityGraph;
import org.springframework.data.jpa.repository.JpaRepository;

public interface DispatchFlowTemplateVersionRepository
    extends JpaRepository<DispatchFlowTemplateVersion, Long> {

  @EntityGraph(attributePaths = {"template"})
  List<DispatchFlowTemplateVersion> findByTemplateIdOrderByVersionNoDesc(Long templateId);

  @EntityGraph(attributePaths = {"template"})
  Optional<DispatchFlowTemplateVersion> findByTemplateIdAndActivePublishedTrue(Long templateId);
}
