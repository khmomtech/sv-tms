package com.svtrucking.logistics.repository;

import com.svtrucking.logistics.model.Mechanic;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

@Repository
public interface MechanicRepository extends JpaRepository<Mechanic, Long> {

  java.util.Optional<Mechanic> findByFullNameIgnoreCase(String fullName);

  @Query(
      "SELECT m FROM Mechanic m WHERE (:active IS NULL OR m.active = :active) "
          + "AND (:search IS NULL OR LOWER(m.fullName) LIKE LOWER(CONCAT('%', :search, '%')) "
          + "OR LOWER(m.phone) LIKE LOWER(CONCAT('%', :search, '%')))")
  Page<Mechanic> search(@Param("search") String search, @Param("active") Boolean active, Pageable pageable);
}
