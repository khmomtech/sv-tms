package com.svtrucking.logistics.controller.admin;

import com.svtrucking.logistics.core.ApiResponse;
import com.svtrucking.logistics.dto.HomeLayoutSectionDto;
import com.svtrucking.logistics.dto.HomeLayoutSectionRequest;
import com.svtrucking.logistics.service.HomeLayoutSectionService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;

/**
 * Admin API for managing home screen layout configuration
 */
@Slf4j
@RestController
@RequestMapping("/api/admin/home-layout")
@CrossOrigin(origins = "*")
@RequiredArgsConstructor
public class HomeLayoutController {

    private final HomeLayoutSectionService service;

    /**
     * Get all layout sections (admin view)
     */
    @GetMapping
    public ResponseEntity<ApiResponse<List<HomeLayoutSectionDto>>> getAllSections() {
        try {
            List<HomeLayoutSectionDto> sections = service.getAllSections();
            return ResponseEntity.ok(ApiResponse.success("Layout sections retrieved successfully", sections));
        } catch (Exception e) {
            log.error("Error retrieving layout sections: {}", e.getMessage(), e);
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                    .body(ApiResponse.fail("Failed to retrieve layout sections: " + e.getMessage()));
        }
    }

    /**
     * Get section by ID
     */
    @GetMapping("/{id}")
    public ResponseEntity<ApiResponse<HomeLayoutSectionDto>> getSectionById(@PathVariable Long id) {
        try {
            HomeLayoutSectionDto section = service.getSectionById(id);
            return ResponseEntity.ok(ApiResponse.success("Section retrieved", section));
        } catch (Exception e) {
            log.error("Error retrieving section {}: {}", id, e.getMessage(), e);
            return ResponseEntity.status(HttpStatus.NOT_FOUND)
                    .body(ApiResponse.fail("Section not found: " + e.getMessage()));
        }
    }

    /**
     * Get section by key
     */
    @GetMapping("/key/{sectionKey}")
    public ResponseEntity<ApiResponse<HomeLayoutSectionDto>> getSectionByKey(@PathVariable String sectionKey) {
        try {
            HomeLayoutSectionDto section = service.getSectionByKey(sectionKey);
            return ResponseEntity.ok(ApiResponse.success("Section retrieved", section));
        } catch (Exception e) {
            log.error("Error retrieving section with key {}: {}", sectionKey, e.getMessage(), e);
            return ResponseEntity.status(HttpStatus.NOT_FOUND)
                    .body(ApiResponse.fail("Section not found: " + e.getMessage()));
        }
    }

    /**
     * Create new section
     */
    @PostMapping
    public ResponseEntity<ApiResponse<HomeLayoutSectionDto>> createSection(
            @Valid @RequestBody HomeLayoutSectionRequest request,
            Authentication authentication) {
        try {
            String username = authentication != null ? authentication.getName() : "system";
            HomeLayoutSectionDto created = service.createSection(request, username);
            return ResponseEntity.status(HttpStatus.CREATED)
                    .body(ApiResponse.success("Section created successfully", created));
        } catch (Exception e) {
            log.error("Error creating section: {}", e.getMessage(), e);
            return ResponseEntity.status(HttpStatus.BAD_REQUEST)
                    .body(ApiResponse.fail("Failed to create section: " + e.getMessage()));
        }
    }

    /**
     * Update existing section
     */
    @PutMapping("/{id}")
    public ResponseEntity<ApiResponse<HomeLayoutSectionDto>> updateSection(
            @PathVariable Long id,
            @Valid @RequestBody HomeLayoutSectionRequest request,
            Authentication authentication) {
        try {
            String username = authentication != null ? authentication.getName() : "system";
            HomeLayoutSectionDto updated = service.updateSection(id, request, username);
            return ResponseEntity.ok(ApiResponse.success("Section updated successfully", updated));
        } catch (Exception e) {
            log.error("Error updating section {}: {}", id, e.getMessage(), e);
            return ResponseEntity.status(HttpStatus.BAD_REQUEST)
                    .body(ApiResponse.fail("Failed to update section: " + e.getMessage()));
        }
    }

    /**
     * Delete section
     */
    @DeleteMapping("/{id}")
    public ResponseEntity<ApiResponse<String>> deleteSection(@PathVariable Long id) {
        try {
            service.deleteSection(id);
            return ResponseEntity.ok(ApiResponse.success("Section deleted successfully"));
        } catch (Exception e) {
            log.error("Error deleting section {}: {}", id, e.getMessage(), e);
            return ResponseEntity.status(HttpStatus.BAD_REQUEST)
                    .body(ApiResponse.fail("Failed to delete section: " + e.getMessage()));
        }
    }

    /**
     * Toggle section visibility
     */
    @PatchMapping("/{id}/toggle-visibility")
    public ResponseEntity<ApiResponse<HomeLayoutSectionDto>> toggleVisibility(
            @PathVariable Long id,
            Authentication authentication) {
        try {
            String username = authentication != null ? authentication.getName() : "system";
            HomeLayoutSectionDto updated = service.toggleVisibility(id, username);
            return ResponseEntity.ok(ApiResponse.success("Section visibility toggled", updated));
        } catch (Exception e) {
            log.error("Error toggling visibility for section {}: {}", id, e.getMessage(), e);
            return ResponseEntity.status(HttpStatus.BAD_REQUEST)
                    .body(ApiResponse.fail("Failed to toggle visibility: " + e.getMessage()));
        }
    }

    /**
     * Reorder sections
     * Request body: {"orderedIds": [3, 1, 2, 5, 4]}
     */
    @PatchMapping("/reorder")
    public ResponseEntity<ApiResponse<List<HomeLayoutSectionDto>>> reorderSections(
            @RequestBody Map<String, List<Long>> request,
            Authentication authentication) {
        try {
            List<Long> orderedIds = request.get("orderedIds");
            if (orderedIds == null || orderedIds.isEmpty()) {
                return ResponseEntity.status(HttpStatus.BAD_REQUEST)
                        .body(ApiResponse.fail("orderedIds is required"));
            }

            String username = authentication != null ? authentication.getName() : "system";
            List<HomeLayoutSectionDto> reordered = service.reorderSections(orderedIds, username);
            return ResponseEntity.ok(ApiResponse.success("Sections reordered successfully", reordered));
        } catch (Exception e) {
            log.error("Error reordering sections: {}", e.getMessage(), e);
            return ResponseEntity.status(HttpStatus.BAD_REQUEST)
                    .body(ApiResponse.fail("Failed to reorder sections: " + e.getMessage()));
        }
    }

    /**
     * Initialize default sections (admin utility)
     */
    @PostMapping("/initialize-defaults")
    public ResponseEntity<ApiResponse<String>> initializeDefaults() {
        try {
            service.initializeDefaultSections();
            return ResponseEntity.ok(ApiResponse.success("Default sections initialized"));
        } catch (Exception e) {
            log.error("Error initializing default sections: {}", e.getMessage(), e);
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                    .body(ApiResponse.fail("Failed to initialize defaults: " + e.getMessage()));
        }
    }
}
