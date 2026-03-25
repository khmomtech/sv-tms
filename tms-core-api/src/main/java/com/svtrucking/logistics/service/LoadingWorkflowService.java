package com.svtrucking.logistics.service;

import com.svtrucking.logistics.dto.LoadingDocumentDto;
import com.svtrucking.logistics.dto.LoadingDispatchDetailResponse;
import com.svtrucking.logistics.dto.LoadingGateUpdateRequest;
import com.svtrucking.logistics.dto.LoadingQueueRequest;
import com.svtrucking.logistics.dto.LoadingQueueResponse;
import com.svtrucking.logistics.dto.LoadingSessionCompleteRequest;
import com.svtrucking.logistics.dto.LoadingSessionResponse;
import com.svtrucking.logistics.dto.LoadingSessionStartRequest;
import com.svtrucking.logistics.enums.LoadingDocumentType;
import com.svtrucking.logistics.enums.WarehouseCode;
import org.springframework.web.multipart.MultipartFile;

import java.util.List;

public interface LoadingWorkflowService {

  LoadingQueueResponse enqueue(LoadingQueueRequest request);

  LoadingQueueResponse callToBay(Long queueId, String bay, String remarks);

  LoadingQueueResponse updateGateInfo(Long queueId, LoadingGateUpdateRequest request);

  LoadingSessionResponse startLoading(LoadingSessionStartRequest request);

  LoadingSessionResponse completeLoading(LoadingSessionCompleteRequest request);

  List<LoadingQueueResponse> getQueueByWarehouse(WarehouseCode warehouseCode);

  LoadingQueueResponse getQueueForDispatch(Long dispatchId);

  LoadingSessionResponse getSessionForDispatch(Long dispatchId);

  LoadingDispatchDetailResponse getDispatchDetail(Long dispatchId);

  LoadingDocumentDto uploadDocument(Long sessionId, LoadingDocumentType documentType, MultipartFile file);
}
