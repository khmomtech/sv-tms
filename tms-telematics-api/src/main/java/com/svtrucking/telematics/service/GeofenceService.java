package com.svtrucking.telematics.service;

import com.svtrucking.telematics.dto.GeofenceDto;
import com.svtrucking.telematics.dto.requests.GeofenceRequest;
import com.svtrucking.telematics.model.Geofence;
import com.svtrucking.telematics.repository.GeofenceRepository;
import java.util.List;
import java.util.stream.Collectors;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
@RequiredArgsConstructor
public class GeofenceService {

    private final GeofenceRepository geofenceRepository;

    public List<GeofenceDto> findByCompany(Long companyId) {
        return geofenceRepository.findByCompanyId(companyId)
                .stream()
                .map(GeofenceDto::from)
                .collect(Collectors.toList());
    }

    public GeofenceDto findById(Long id) {
        return geofenceRepository.findById(id)
                .map(GeofenceDto::from)
                .orElseThrow(() -> new jakarta.persistence.EntityNotFoundException(
                        "Geofence not found: " + id));
    }

    @Transactional
    public GeofenceDto create(GeofenceRequest req, String createdBy) {
        Geofence g = Geofence.builder()
                .companyId(req.getPartnerCompanyId())
                .name(req.getName())
                .description(req.getDescription())
                .type(Geofence.Type.valueOf(req.getType().toUpperCase()))
                .centerLatitude(req.getCenterLatitude())
                .centerLongitude(req.getCenterLongitude())
                .radiusMeters(req.getRadiusMeters())
                .geoJsonCoordinates(req.getGeoJsonCoordinates())
                .alertType(req.getAlertType() != null
                        ? Geofence.AlertType.valueOf(req.getAlertType().toUpperCase())
                        : Geofence.AlertType.NONE)
                .speedLimitKmh(req.getSpeedLimitKmh())
                .active(req.getActive() != null ? req.getActive() : true)
                .tags(req.getTags())
                .createdBy(createdBy)
                .build();
        return GeofenceDto.from(geofenceRepository.save(g));
    }

    @Transactional
    public GeofenceDto update(Long id, GeofenceRequest req) {
        Geofence g = geofenceRepository.findById(id)
                .orElseThrow(() -> new jakarta.persistence.EntityNotFoundException(
                        "Geofence not found: " + id));
        g.setName(req.getName());
        g.setDescription(req.getDescription());
        g.setType(Geofence.Type.valueOf(req.getType().toUpperCase()));
        g.setCenterLatitude(req.getCenterLatitude());
        g.setCenterLongitude(req.getCenterLongitude());
        g.setRadiusMeters(req.getRadiusMeters());
        g.setGeoJsonCoordinates(req.getGeoJsonCoordinates());
        if (req.getAlertType() != null) {
            g.setAlertType(Geofence.AlertType.valueOf(req.getAlertType().toUpperCase()));
        }
        if (req.getSpeedLimitKmh() != null) {
            g.setSpeedLimitKmh(req.getSpeedLimitKmh());
        }
        if (req.getActive() != null) {
            g.setActive(req.getActive());
        }
        if (req.getTags() != null) {
            g.setTags(req.getTags());
        }
        return GeofenceDto.from(geofenceRepository.save(g));
    }

    @Transactional
    public void delete(Long id) {
        if (!geofenceRepository.existsById(id)) {
            throw new jakarta.persistence.EntityNotFoundException("Geofence not found: " + id);
        }
        geofenceRepository.deleteById(id);
    }
}
