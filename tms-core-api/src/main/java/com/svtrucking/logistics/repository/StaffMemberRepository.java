package com.svtrucking.logistics.repository;

import com.svtrucking.logistics.model.StaffMember;
import java.util.Optional;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

public interface StaffMemberRepository extends JpaRepository<StaffMember, Long> {

  Optional<StaffMember> findByUserId(Long userId);

  @Query(
      "SELECT s FROM StaffMember s "
          + "WHERE (:active IS NULL OR s.active = :active) "
          + "AND (:search IS NULL OR LOWER(s.fullName) LIKE LOWER(CONCAT('%', :search, '%')) "
          + "OR LOWER(s.email) LIKE LOWER(CONCAT('%', :search, '%')) "
          + "OR LOWER(s.phone) LIKE LOWER(CONCAT('%', :search, '%')) "
          + "OR LOWER(s.jobTitle) LIKE LOWER(CONCAT('%', :search, '%')) "
          + "OR LOWER(s.department) LIKE LOWER(CONCAT('%', :search, '%')))")
  Page<StaffMember> search(
      @Param("search") String search, @Param("active") Boolean active, Pageable pageable);
}
