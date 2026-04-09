package com.svtrucking.logistics.controller.admin;

import com.svtrucking.logistics.core.ApiResponse;
import com.svtrucking.logistics.dto.BannerDto;
import com.svtrucking.logistics.service.BannerService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

import java.util.List;

/**
 * Admin API for managing banners/announcements
 */
@Slf4j
@RestController
@RequestMapping("/api/admin/banners")
@CrossOrigin(origins = "*")
@RequiredArgsConstructor
public class BannerController {

    private final BannerService bannerService;

    /**
     * Get all banners (admin view)
     */
    @GetMapping
    public ResponseEntity<ApiResponse<List<BannerDto>>> getAllBanners() {
        try {
            List<BannerDto> banners = bannerService.getAllBanners();
            return ResponseEntity.ok(ApiResponse.success("Banners retrieved successfully", banners));
        } catch (Exception e) {
            log.error("Error retrieving banners: {}", e.getMessage(), e);
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                    .body(ApiResponse.fail("Failed to retrieve banners: " + e.getMessage()));
        }
    }

    /**
     * Get banner by ID
     */
    @GetMapping("/{id}")
    public ResponseEntity<ApiResponse<BannerDto>> getBannerById(@PathVariable Long id) {
        try {
            BannerDto banner = bannerService.getBannerById(id);
            return ResponseEntity.ok(ApiResponse.success("Banner retrieved", banner));
        } catch (Exception e) {
            log.error("Error retrieving banner {}: {}", id, e.getMessage(), e);
            return ResponseEntity.status(HttpStatus.NOT_FOUND)
                    .body(ApiResponse.fail("Banner not found: " + e.getMessage()));
        }
    }

    /**
     * Create new banner
     */
    @PostMapping
    public ResponseEntity<ApiResponse<BannerDto>> createBanner(
            @RequestBody BannerDto bannerDto,
            Authentication authentication) {
        try {
            String username = authentication != null ? authentication.getName() : "system";
            BannerDto created = bannerService.createBanner(bannerDto, username);
            return ResponseEntity.status(HttpStatus.CREATED)
                    .body(ApiResponse.success("Banner created successfully", created));
        } catch (Exception e) {
            log.error("Error creating banner: {}", e.getMessage(), e);
            return ResponseEntity.status(HttpStatus.BAD_REQUEST)
                    .body(ApiResponse.fail("Failed to create banner: " + e.getMessage()));
        }
    }

    /**
     * Update existing banner
     */
    @PutMapping("/{id}")
    public ResponseEntity<ApiResponse<BannerDto>> updateBanner(
            @PathVariable Long id,
            @RequestBody BannerDto bannerDto) {
        try {
            BannerDto updated = bannerService.updateBanner(id, bannerDto);
            return ResponseEntity.ok(ApiResponse.success("Banner updated successfully", updated));
        } catch (Exception e) {
            log.error("Error updating banner {}: {}", id, e.getMessage(), e);
            return ResponseEntity.status(HttpStatus.BAD_REQUEST)
                    .body(ApiResponse.fail("Failed to update banner: " + e.getMessage()));
        }
    }

    /**
     * Delete banner
     */
    @DeleteMapping("/{id}")
    public ResponseEntity<ApiResponse<String>> deleteBanner(@PathVariable Long id) {
        try {
            bannerService.deleteBanner(id);
            return ResponseEntity.ok(ApiResponse.success("Banner deleted successfully"));
        } catch (Exception e) {
            log.error("Error deleting banner {}: {}", id, e.getMessage(), e);
            return ResponseEntity.status(HttpStatus.BAD_REQUEST)
                    .body(ApiResponse.fail("Failed to delete banner: " + e.getMessage()));
        }
    }
}
