package com.svtrucking.logistics.service;

import com.svtrucking.logistics.dto.PreLoadingSafetyCheckRequest;
import com.svtrucking.logistics.enums.DispatchStatus;
import com.svtrucking.logistics.enums.SafetyResult;
import com.svtrucking.logistics.model.Dispatch;
import com.svtrucking.logistics.repository.DispatchRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.security.test.context.support.WithMockUser;
import org.springframework.test.annotation.Rollback;
import org.springframework.transaction.annotation.Transactional;

import static org.assertj.core.api.Assertions.assertThat;
import static org.junit.jupiter.api.Assertions.assertThrows;

@SpringBootTest
@Transactional
@Rollback
@WithMockUser(username = "admin", roles = {"ADMIN"})
class PreLoadingSafetyCheckServiceIT {

  @Autowired
  private PreLoadingSafetyCheckService safetyService;

  @Autowired
  private DispatchRepository dispatchRepository;

  private Dispatch dispatch;

  @BeforeEach
  void setup() {
    dispatch = new Dispatch();
    dispatch.setStatus(DispatchStatus.ASSIGNED);
    dispatch = dispatchRepository.save(dispatch);
  }

  @Test
  void submitSafetyCheck_pass_shouldSetStatusPassed() {
    PreLoadingSafetyCheckRequest req = buildReq(SafetyResult.PASS, null);

    safetyService.submitSafetyCheck(req);

    Dispatch reloaded = dispatchRepository.findById(dispatch.getId()).orElseThrow();
    assertThat(reloaded.getSafetyStatus()).isEqualTo(com.svtrucking.logistics.enums.SafetyCheckStatus.PASSED);
  }

  @Test
  void submitSafetyCheck_fail_shouldRequireReasonAndSetFailed() {
    // missing reason -> should throw
    assertThrows(IllegalArgumentException.class, () -> safetyService.submitSafetyCheck(buildReq(SafetyResult.FAIL, null)));

    // with reason -> status failed
    safetyService.submitSafetyCheck(buildReq(SafetyResult.FAIL, "Missing PPE"));
    Dispatch reloaded = dispatchRepository.findById(dispatch.getId()).orElseThrow();
    assertThat(reloaded.getSafetyStatus()).isEqualTo(com.svtrucking.logistics.enums.SafetyCheckStatus.FAILED);
  }

  private PreLoadingSafetyCheckRequest buildReq(SafetyResult result, String reason) {
    PreLoadingSafetyCheckRequest req = new PreLoadingSafetyCheckRequest();
    req.setDispatchId(dispatch.getId());
    req.setDriverPpeOk(true);
    req.setFireExtinguisherOk(true);
    req.setWheelChockOk(true);
    req.setTruckLeakageOk(true);
    req.setTruckCleanOk(true);
    req.setTruckConditionOk(true);
    req.setResult(result);
    req.setFailReason(reason);
    return req;
  }
}
