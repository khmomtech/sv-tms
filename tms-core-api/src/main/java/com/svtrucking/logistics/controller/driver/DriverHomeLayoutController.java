package com.svtrucking.logistics.controller.driver;

import com.svtrucking.logistics.core.ApiResponse;
import com.svtrucking.logistics.dto.HomeLayoutSectionDto;
import com.svtrucking.logistics.service.HomeLayoutSectionService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

/**
 * Driver API for fetching home screen layout configuration
 */
@Slf4j
@RestController
@RequestMapping("/api/driver/home-layout")
@CrossOrigin(origins = "*")
@RequiredArgsConstructor
public class DriverHomeLayoutController {

    private final HomeLayoutSectionService service;

    /**
     * Get visible sections for driver app
     * Returns minimal data (only what drivers need)
     */
    @GetMapping("/sections")
    public ResponseEntity<ApiResponse<List<HomeLayoutSectionDto>>> getVisibleSections() {
        try {
            List<HomeLayoutSectionDto> sections = service.getVisibleSections();
            log.debug("Driver fetched {} visible home layout sections", sections.size());
            return ResponseEntity.ok(ApiResponse.success("Layout configuration retrieved", sections));
        } catch (Exception e) {
            log.error("Error retrieving driver home layout: {}", e.getMessage(), e);
            // Return success with empty list to avoid breaking the app
            return ResponseEntity.ok(ApiResponse.success("Layout configuration retrieved", List.of()));
        }
    }
}
