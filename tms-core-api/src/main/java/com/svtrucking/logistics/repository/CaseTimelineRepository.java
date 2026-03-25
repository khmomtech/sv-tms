package com.svtrucking.logistics.repository;

import com.svtrucking.logistics.enums.TimelineEntryType;
import com.svtrucking.logistics.model.CaseTimeline;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import java.util.List;

@Repository
public interface CaseTimelineRepository extends JpaRepository<CaseTimeline, Long> {

  List<CaseTimeline> findByCaseEntityIdOrderByCreatedAtDesc(Long caseId);

  List<CaseTimeline> findByCaseEntityIdAndEntryTypeOrderByCreatedAtDesc(Long caseId, TimelineEntryType entryType);

  List<CaseTimeline> findByCaseEntityIdOrderByCreatedAtAsc(Long caseId);
}
