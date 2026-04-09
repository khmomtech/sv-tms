package com.svtrucking.logistics.settings.repository;

import com.svtrucking.logistics.settings.entity.SettingDef;
import java.util.Optional;
import org.springframework.data.jpa.repository.JpaRepository;

public interface SettingDefRepository extends JpaRepository<SettingDef, Long> {
  // Correct Spring Data path (group.code)
  Optional<SettingDef> findByGroupCodeAndKeyCode(String groupCode, String keyCode);
}
