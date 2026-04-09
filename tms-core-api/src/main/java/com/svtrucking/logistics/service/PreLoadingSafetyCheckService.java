package com.svtrucking.logistics.service;

import com.svtrucking.logistics.dto.PreLoadingSafetyCheckRequest;
import com.svtrucking.logistics.dto.PreLoadingSafetyCheckResponse;

public interface PreLoadingSafetyCheckService {
  PreLoadingSafetyCheckResponse submitSafetyCheck(PreLoadingSafetyCheckRequest request);

  PreLoadingSafetyCheckResponse getLatestByDispatch(Long dispatchId);

  java.util.List<PreLoadingSafetyCheckResponse> getHistory(Long dispatchId);
}
