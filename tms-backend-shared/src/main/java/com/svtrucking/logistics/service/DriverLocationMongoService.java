package com.svtrucking.logistics.service;

import com.svtrucking.logistics.dto.LocationHistoryDto;
import com.svtrucking.logistics.model.LocationHistory;
import com.svtrucking.logistics.mongo.document.DriverLocationHistoryDocument;
import com.svtrucking.logistics.mongo.repository.DriverLocationHistoryMongoRepository;
import java.time.Instant;
import java.time.ZoneOffset;
import java.util.List;
import java.util.Objects;
import java.util.stream.Collectors;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.boot.autoconfigure.condition.ConditionalOnBean;
import org.springframework.data.domain.PageRequest;
import org.springframework.stereotype.Service;

@Service
@Slf4j
@ConditionalOnBean(DriverLocationHistoryMongoRepository.class)
@RequiredArgsConstructor
public class DriverLocationMongoService {
  private final DriverLocationHistoryMongoRepository repo;

  public boolean trySaveAll(List<LocationHistory> batch) {
    if (batch == null || batch.isEmpty()) return true;
    try {
      List<DriverLocationHistoryDocument> docs =
          batch.stream().map(this::toDoc).filter(Objects::nonNull).toList();
      if (!docs.isEmpty()) {
        repo.saveAll(docs);
      }
      return true;
    } catch (Exception e) {
      log.warn("Mongo dual-write failed for {} point(s): {}", batch.size(), e.toString());
      return false;
    }
  }

  public void saveAll(List<LocationHistory> batch) {
    trySaveAll(batch);
  }

  public List<LocationHistoryDto> findByDriver(Long driverId, int page, int size) {
    List<DriverLocationHistoryDocument> docs =
        repo.findByDriverIdOrderByEventTimeDesc(driverId, PageRequest.of(page, size));
    return docs.stream().map(this::toDto).collect(Collectors.toList());
  }

  public List<LocationHistoryDto> findByDriver(Long driverId) {
    return repo.findByDriverIdOrderByEventTimeDesc(driverId).stream()
        .map(this::toDto)
        .collect(Collectors.toList());
  }

  private DriverLocationHistoryDocument toDoc(LocationHistory h) {
    if (h == null) return null;
    try {
      return DriverLocationHistoryDocument.builder()
          .driverId(h.getDriver() != null ? h.getDriver().getId() : null)
          .dispatchId(h.getDispatch() != null ? h.getDispatch().getId() : null)
          .latitude(h.getLatitude())
          .longitude(h.getLongitude())
          .accuracyMeters(h.getAccuracyMeters())
          .heading(h.getHeading())
          .speed(h.getSpeed())
          .clientSpeedKmh(h.getSpeed() != null ? h.getSpeed() : null)
          .locationName(h.getLocationName())
          .locationSource(h.getLocationSource())
          .netType(h.getNetType())
          .source(h.getSource())
          .batteryLevel(h.getBatteryLevel())
          .appVersionCode(h.getAppVersionCode())
          .isOnline(h.getIsOnline())
          .eventTime(h.getEventTime() != null ? h.getEventTime().toInstant(ZoneOffset.UTC) : null)
          .timestamp(h.getTimestamp() != null ? h.getTimestamp().toInstant(ZoneOffset.UTC) : null)
          .createdAt(Instant.now())
          .build();
    } catch (Exception e) {
      log.warn("Failed to map LocationHistory to Mongo document: {}", e.toString());
      return null;
    }
  }

  private LocationHistoryDto toDto(DriverLocationHistoryDocument doc) {
    return LocationHistoryDto.builder()
        .driverId(doc.getDriverId())
        .dispatchId(doc.getDispatchId())
        .latitude(doc.getLatitude())
        .longitude(doc.getLongitude())
        .locationName(doc.getLocationName())
        .timestamp(
            doc.getTimestamp() != null
                ? doc.getTimestamp().atOffset(ZoneOffset.UTC).toLocalDateTime()
                : null)
        .isOnline(doc.getIsOnline())
        .batteryLevel(doc.getBatteryLevel())
        .speed(doc.getSpeed())
        .source(doc.getSource())
        .build();
  }
}
