package com.svtrucking.logistics.repository;

import com.svtrucking.logistics.model.FailureCode;
import java.util.List;
import java.util.Optional;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

public interface FailureCodeRepository extends JpaRepository<FailureCode, Long> {

  Optional<FailureCode> findByCode(String code);

  List<FailureCode> findByActiveTrueOrderByCodeAsc();

  @Query(
      "SELECT fc FROM FailureCode fc "
          + "WHERE (:active IS NULL OR fc.active = :active) "
          + "ORDER BY fc.code ASC")
  Page<FailureCode> findByActive(@Param("active") Boolean active, Pageable pageable);
}
