package com.svtrucking.telematics.repository;

import com.svtrucking.telematics.model.TelematicsIngestReceipt;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

@Repository
public interface TelematicsIngestReceiptRepository extends JpaRepository<TelematicsIngestReceipt, Long> {
    boolean existsByDriverIdAndPointId(Long driverId, String pointId);

    boolean existsByDriverIdAndSessionIdAndSeq(Long driverId, String sessionId, Long seq);
}
