package com.svtrucking.logistics.controller.driver;

import com.svtrucking.logistics.core.ApiResponse;
import com.svtrucking.logistics.dto.BannerDto;
import com.svtrucking.logistics.service.BannerService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

/**
 * Driver-facing API for banners/carousel
 */
@Slf4j
@RestController
@RequestMapping("/api/driver/banners")
@CrossOrigin(origins = "*")
@RequiredArgsConstructor
public class DriverBannerController {

    private final BannerService bannerService;

    /**
     * Get active banners for carousel display
     */
    @GetMapping("/active")
    public ResponseEntity<ApiResponse<List<BannerDto>>> getActiveBanners() {
        try {
            List<BannerDto> banners = bannerService.getActiveBanners();
            return ResponseEntity.ok(ApiResponse.success("Active banners retrieved", banners));
        } catch (Exception e) {
            log.error("Error fetching active banners: {}", e.getMessage(), e);
            return ResponseEntity.ok(ApiResponse.fail("Failed to fetch banners: " + e.getMessage()));
        }
    }

    /**
     * Get active banners by category
     */
    @GetMapping("/category/{category}")
    public ResponseEntity<ApiResponse<List<BannerDto>>> getActiveBannersByCategory(@PathVariable String category) {
        try {
            List<BannerDto> banners = bannerService.getActiveBannersByCategory(category);
            return ResponseEntity.ok(ApiResponse.success("Category banners retrieved", banners));
        } catch (Exception e) {
            log.error("Error fetching banners by category: {}", e.getMessage(), e);
            return ResponseEntity.ok(ApiResponse.fail("Failed to fetch banners: " + e.getMessage()));
        }
    }

    /**
     * Track banner click (uses silent fail method for better UX)
     */
    @PostMapping("/{id}/click")
    public ResponseEntity<ApiResponse<String>> trackClick(@PathVariable Long id) {
        try {
            // Use incrementClickCount which has silent fail behavior
            bannerService.incrementClickCount(id);
            return ResponseEntity.ok(ApiResponse.success("Click tracked"));
        } catch (Exception e) {
            // Silent fail - don't disrupt UX for analytics
            log.debug("Failed to track banner click for banner {}: {}", id, e.getMessage());
            return ResponseEntity.ok(ApiResponse.success("OK"));
        }
    }
}
