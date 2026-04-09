package com.svtrucking.logistics.repository;

import com.svtrucking.logistics.model.AppVersion;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

@Repository
public interface AppVersionRepository extends JpaRepository<AppVersion, Long> {
  AppVersion findTopByOrderByLastUpdatedDesc();

  java.util.List<AppVersion> findAllByOrderByLastUpdatedDesc();
}
