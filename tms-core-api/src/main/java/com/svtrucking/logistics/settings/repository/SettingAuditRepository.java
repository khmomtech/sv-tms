package com.svtrucking.logistics.settings.repository;

import com.svtrucking.logistics.settings.entity.SettingAudit;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

public interface SettingAuditRepository extends JpaRepository<SettingAudit, Long> {

  /** All audit records, newest first. */
  Page<SettingAudit> findAllByOrderByUpdatedAtDesc(Pageable pageable);

  /** Filter by group only. */
  @Query("SELECT a FROM SettingAudit a WHERE a.def.group.code = :groupCode ORDER BY a.updatedAt DESC")
  Page<SettingAudit> findByGroupCode(@Param("groupCode") String groupCode, Pageable pageable);

  /** Filter by group + key. */
  @Query("SELECT a FROM SettingAudit a "
      + "WHERE a.def.group.code = :groupCode AND a.def.keyCode = :keyCode "
      + "ORDER BY a.updatedAt DESC")
  Page<SettingAudit> findByGroupAndKey(
      @Param("groupCode") String groupCode,
      @Param("keyCode")   String keyCode,
      Pageable pageable);
}
