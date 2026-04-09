package com.svtrucking.logistics.repository;

import com.svtrucking.logistics.model.AboutAppInfo;
import org.springframework.data.jpa.repository.JpaRepository;

public interface AboutAppInfoRepository extends JpaRepository<AboutAppInfo, Long> {
  // No custom methods needed now; basic CRUD is enough
}
