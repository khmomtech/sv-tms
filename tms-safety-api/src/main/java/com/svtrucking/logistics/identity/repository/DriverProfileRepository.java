package com.svtrucking.logistics.identity.repository;

import com.svtrucking.logistics.identity.domain.DriverProfile;
import java.util.List;
import java.util.Optional;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

@Repository
public interface DriverProfileRepository extends JpaRepository<DriverProfile, Long> {
    Optional<DriverProfile> findByUserId(Long userId);

    @Query("SELECT d FROM DriverProfile d WHERE d.userId = :userId")
    Optional<DriverProfile> findOneByUserId(@Param("userId") Long userId);

    Optional<DriverProfile> findTopByPhone(String phone);

    @Query("select d.id from DriverProfile d "
            + "where (:term is null or :term = '' or lower(d.full_name) like :term or lower(d.phone_number) like :term)")
    List<Long> searchIds(@Param("term") String term);
}
