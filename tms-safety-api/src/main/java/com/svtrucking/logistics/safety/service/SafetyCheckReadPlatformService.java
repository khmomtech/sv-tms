package com.svtrucking.logistics.safety.service;

import com.svtrucking.logistics.dto.SafetyCheckDto;
import com.svtrucking.logistics.dto.SafetyCheckItemDto;
import com.svtrucking.logistics.dto.SafetyEligibilityDto;
import com.svtrucking.logistics.enums.DailySafetyCheckStatus;
import com.svtrucking.logistics.enums.SafetyRiskLevel;
import java.time.LocalDate;
import java.util.List;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;

/**
 * Fineract-style "ReadPlatformService" facade: controllers depend on an interface rather than the
 * concrete Spring service.
 *
 * <p>Keep this interface small and stable. Add methods only when a controller needs them.
 */
public interface SafetyCheckReadPlatformService {

  SafetyCheckDto getToday(Long driverId, Long vehicleId);

  SafetyCheckDto getPublicToday(String plate);

  List<SafetyCheckItemDto> getPublicMasterItems();

  List<SafetyCheckDto> getPublicHistory(String plate, LocalDate from, LocalDate to);

  SafetyCheckDto getPublicDetail(Long id, String plate);

  Page<SafetyCheckDto> getAdminList(
      String search,
      LocalDate from,
      LocalDate to,
      DailySafetyCheckStatus status,
      SafetyRiskLevel risk,
      Pageable pageable);

  byte[] exportAdminCsv(
      String search,
      LocalDate from,
      LocalDate to,
      DailySafetyCheckStatus status,
      SafetyRiskLevel risk);

  byte[] exportAdminExcel(
      String search,
      LocalDate from,
      LocalDate to,
      DailySafetyCheckStatus status,
      SafetyRiskLevel risk);

  SafetyCheckDto getAdminDetail(Long id);

  List<SafetyCheckDto> getHistory(Long driverId, LocalDate from, LocalDate to);

  SafetyEligibilityDto checkEligibility(Long driverId, Long vehicleId, LocalDate date);
}

