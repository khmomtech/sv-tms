package com.svtrucking.logistics.mongo.repository;

import com.svtrucking.logistics.mongo.document.DriverLocationHistoryDocument;
import java.util.List;
import org.springframework.data.domain.Pageable;
import org.springframework.data.mongodb.repository.MongoRepository;
import org.springframework.stereotype.Repository;

@Repository
public interface DriverLocationHistoryMongoRepository
    extends MongoRepository<DriverLocationHistoryDocument, String> {
  List<DriverLocationHistoryDocument> findByDriverIdOrderByEventTimeDesc(Long driverId);

  List<DriverLocationHistoryDocument> findByDriverIdOrderByEventTimeDesc(
      Long driverId, Pageable pageable);
}
