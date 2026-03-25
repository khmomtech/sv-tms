package com.svtrucking.telematics.service;

import com.svtrucking.telematics.dto.SpoofingAlertDto;
import com.svtrucking.telematics.model.SpoofingAlert;
import com.svtrucking.telematics.repository.SpoofingAlertRepository;
import java.time.LocalDateTime;
import java.time.ZoneOffset;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;

@Service
@RequiredArgsConstructor
@Slf4j
public class SpoofingAlertService {

    private final SpoofingAlertRepository spoofingAlertRepository;

    public SpoofingAlert record(SpoofingAlertDto dto) {
        LocalDateTime alertTime = dto.getTimestamp() != null
                ? LocalDateTime.ofInstant(dto.getTimestamp(), ZoneOffset.UTC)
                : LocalDateTime.now(ZoneOffset.UTC);

        SpoofingAlert alert = SpoofingAlert.builder()
                .driverId(dto.getDriverId())
                .dispatchId(dto.getDispatchId())
                .sessionId(dto.getSessionId())
                .deviceId(dto.getDeviceId())
                .alertType(dto.getAlertType() != null ? dto.getAlertType() : "MOCK_LOCATION")
                .latitude(dto.getLatitude())
                .longitude(dto.getLongitude())
                .speedKmh(dto.getSpeed() != null ? dto.getSpeed() * 3.6 : null)
                .distanceMeters(dto.getDistanceMeters())
                .timeDeltaMs(dto.getTimeDeltaMs())
                .detail(buildDetail(dto))
                .createdAt(alertTime)
                .build();

        SpoofingAlert saved = spoofingAlertRepository.save(alert);
        log.warn("[spoofing] Saved alert id={} driverId={} type={} reason={}",
                saved.getId(), dto.getDriverId(), saved.getAlertType(), dto.getReason());
        return saved;
    }

    private String buildDetail(SpoofingAlertDto dto) {
        StringBuilder sb = new StringBuilder();
        if (dto.getReason() != null)
            sb.append("reason=").append(dto.getReason());
        if (dto.getIsMocked() != null) {
            if (sb.length() > 0)
                sb.append("; ");
            sb.append("isMocked=").append(dto.getIsMocked());
        }
        if (dto.getAccuracy() != null) {
            if (sb.length() > 0)
                sb.append("; ");
            sb.append("accuracy=").append(dto.getAccuracy()).append("m");
        }
        if (dto.getDetail() != null && !dto.getDetail().isBlank()) {
            if (sb.length() > 0)
                sb.append("; ");
            sb.append(dto.getDetail());
        }
        return sb.length() > 0 ? sb.toString() : null;
    }
}
