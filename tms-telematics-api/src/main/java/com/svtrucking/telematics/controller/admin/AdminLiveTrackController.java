package com.svtrucking.telematics.controller.admin;

import com.svtrucking.telematics.dto.LiveDriverDto;
import com.svtrucking.telematics.dto.LocationHistoryDto;
import com.svtrucking.telematics.repository.LocationHistoryRepository;
import com.svtrucking.telematics.service.LiveDriverQueryService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import java.time.LocalDateTime;
import java.util.List;
import java.util.stream.Collectors;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

/**
 * Admin live-track query controller.
 * All endpoints require ROLE_API_USER (set from a valid access-token JWT).
 */
@RestController
@RequestMapping("/api/admin/telematics")
@RequiredArgsConstructor
@Tag(name = "Admin Live Track", description = "Admin live-driver query endpoints")
public class AdminLiveTrackController {

        private final LiveDriverQueryService liveDriverQueryService;
        private final LocationHistoryRepository locationHistoryRepository;

        /**
         * List all drivers with recent GPS updates.
         */
        @GetMapping("/live-drivers")
        @Operation(summary = "Get live driver positions", description = "Returns all drivers with GPS data. Optionally filter by online status and bounding box.")
        public ResponseEntity<List<LiveDriverDto>> getLiveDrivers(
                        @RequestParam(required = false) Boolean online,
                        @RequestParam(required = false) Integer onlineSeconds,
                        @RequestParam(required = false) Double south,
                        @RequestParam(required = false) Double west,
                        @RequestParam(required = false) Double north,
                        @RequestParam(required = false) Double east) {

                List<LiveDriverDto> drivers = liveDriverQueryService.getLiveDrivers(
                                online, onlineSeconds, south, west, north, east);
                return ResponseEntity.ok(drivers);
        }

        /**
         * Get the latest location for a single driver.
         */
        @GetMapping("/driver/{driverId}/location")
        @Operation(summary = "Get latest location for driver")
        public ResponseEntity<?> getDriverLocation(@PathVariable Long driverId) {
                return liveDriverQueryService.getLatestForDriver(driverId)
                                .<ResponseEntity<?>>map(ResponseEntity::ok)
                                .orElse(ResponseEntity.notFound().build());
        }

        /**
         * Get location history for a single driver with optional date range and
         * pagination.
         * Points are ordered oldest-first so the frontend can animate them in sequence.
         *
         * @param driverId driver to query
         * @param from     ISO-8601 start datetime (inclusive), e.g. 2024-01-15T00:00:00
         * @param to       ISO-8601 end datetime (inclusive), e.g. 2024-01-15T23:59:59
         * @param page     zero-based page index (default 0)
         * @param size     page size, capped at 2000 (default 500)
         */
        @GetMapping("/driver/{driverId}/history")
        @Operation(summary = "Get location history for a driver", description = "Returns GPS history ordered oldest-first. Use from/to for a time window.")
        public ResponseEntity<List<LocationHistoryDto>> getDriverHistory(
                        @PathVariable Long driverId,
                        @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE_TIME) LocalDateTime from,
                        @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE_TIME) LocalDateTime to,
                        @RequestParam(defaultValue = "0") int page,
                        @RequestParam(defaultValue = "500") int size) {

                if (size > 2000)
                        size = 2000;
                Pageable pageable = PageRequest.of(page, size);

                Page<?> pageResult;
                if (from != null && to != null) {
                        pageResult = locationHistoryRepository
                                        .findByDriverIdAndTimestampBetweenOrderByTimestampDesc(
                                                        driverId, from, to, pageable);
                } else {
                        pageResult = locationHistoryRepository
                                        .findByDriverIdOrderByTimestampDesc(driverId, pageable);
                }

                List<LocationHistoryDto> result = pageResult.getContent().stream()
                                .map(lh -> LocationHistoryDto
                                                .from((com.svtrucking.telematics.model.LocationHistory) lh))
                                // Reverse to oldest-first for playback animation
                                .collect(Collectors.collectingAndThen(
                                                Collectors.toList(),
                                                list -> {
                                                        java.util.Collections.reverse(list);
                                                        return list;
                                                }));

                return ResponseEntity.ok(result);
        }
}
