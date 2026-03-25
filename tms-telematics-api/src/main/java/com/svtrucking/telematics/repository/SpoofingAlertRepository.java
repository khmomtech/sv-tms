package com.svtrucking.telematics.repository;

import com.svtrucking.telematics.model.SpoofingAlert;
import java.time.LocalDateTime;
import java.util.List;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

@Repository
public interface SpoofingAlertRepository extends JpaRepository<SpoofingAlert, Long> {

        List<SpoofingAlert> findByDriverIdOrderByCreatedAtDesc(Long driverId, Pageable pageable);

        List<SpoofingAlert> findByDriverIdAndCreatedAtAfterOrderByCreatedAtDesc(
                        Long driverId, LocalDateTime after);

        List<SpoofingAlert> findByAlertTypeAndCreatedAtAfterOrderByCreatedAtDesc(
                        String alertType, LocalDateTime after);
}
