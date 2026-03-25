package com.svtrucking.logistics.repository;

import com.svtrucking.logistics.model.LoadingDocument;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface LoadingDocumentRepository extends JpaRepository<LoadingDocument, Long> {

  List<LoadingDocument> findByDispatchId(Long dispatchId);

  List<LoadingDocument> findByLoadingSessionId(Long sessionId);
}
