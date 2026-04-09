package com.svtrucking.logistics.settings.repository;

import com.svtrucking.logistics.settings.entity.SettingGroup;
import java.util.Optional;
import org.springframework.data.jpa.repository.JpaRepository;

public interface SettingGroupRepository extends JpaRepository<SettingGroup, Long> {
  Optional<SettingGroup> findByCode(String code);
}
