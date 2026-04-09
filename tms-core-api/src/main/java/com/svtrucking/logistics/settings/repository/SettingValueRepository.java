package com.svtrucking.logistics.settings.repository;

import com.svtrucking.logistics.settings.entity.SettingValue;
import com.svtrucking.logistics.settings.enums.SettingScope;
import java.util.Optional;
import org.springframework.data.jpa.repository.JpaRepository;

public interface SettingValueRepository extends JpaRepository<SettingValue, Long> {
  // Correct Spring Data path (def.id) — note the underscore after def
  @SuppressWarnings("checkstyle:MethodName")
  Optional<SettingValue> findTopByDef_IdAndScopeAndScopeRefOrderByVersionDesc(
      Long defId, SettingScope scope, String scopeRef);

  // Alias to match your current service call (without underscore)
  default Optional<SettingValue> findTopByDefIdAndScopeAndScopeRefOrderByVersionDesc(
      Long defId, SettingScope scope, String scopeRef) {
    return findTopByDef_IdAndScopeAndScopeRefOrderByVersionDesc(defId, scope, scopeRef);
  }
}
