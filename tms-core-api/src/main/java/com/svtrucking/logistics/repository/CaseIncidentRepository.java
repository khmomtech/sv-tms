package com.svtrucking.logistics.repository;

import com.svtrucking.logistics.model.CaseIncident;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;
import java.util.List;
import java.util.Optional;

@Repository
public interface CaseIncidentRepository extends JpaRepository<CaseIncident, Long> {

  List<CaseIncident> findByCaseEntityId(Long caseId);

  List<CaseIncident> findByIncidentId(Long incidentId);

  Optional<CaseIncident> findByCaseEntityIdAndIncidentId(Long caseId, Long incidentId);

  boolean existsByCaseEntityIdAndIncidentId(Long caseId, Long incidentId);

  @Query("SELECT COUNT(ci) FROM CaseIncident ci WHERE ci.caseEntity.id = :caseId")
  long countByCaseId(@Param("caseId") Long caseId);

  @Query("SELECT COUNT(ci) FROM CaseIncident ci WHERE ci.incident.id = :incidentId")
  long countByIncidentId(@Param("incidentId") Long incidentId);

  void deleteByCaseEntityIdAndIncidentId(Long caseId, Long incidentId);
}
