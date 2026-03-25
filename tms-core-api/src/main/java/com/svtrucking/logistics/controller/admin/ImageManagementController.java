package com.svtrucking.logistics.controller.admin;

import com.svtrucking.logistics.core.ApiResponse;
import com.svtrucking.logistics.service.ImageManagementService;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

import java.util.List;
import java.util.Map;

/**
 * Admin controller for managing application images (banners, logos, etc.)
 */
@Slf4j
@RestController
@RequestMapping("/api/admin/images")
@CrossOrigin(origins = "*")
public class ImageManagementController {

    private final ImageManagementService imageManagementService;

    public ImageManagementController(ImageManagementService imageManagementService) {
        this.imageManagementService = imageManagementService;
    }

    /**
     * Get all managed images
     */
    @GetMapping
    @PreAuthorize("@authorizationService.hasPermission(T(com.svtrucking.logistics.security.PermissionNames).IMAGE_READ)")
    public ResponseEntity<ApiResponse<List<Map<String, Object>>>> getAllImages() {
        try {
            List<Map<String, Object>> images = imageManagementService.getAllImages();
            return ResponseEntity.ok(ApiResponse.success("Images retrieved successfully", images));
        } catch (Exception e) {
            log.error("Error retrieving images: {}", e.getMessage(), e);
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                .body(ApiResponse.fail("Failed to retrieve images: " + e.getMessage()));
        }
    }

    /**
     * Upload a new image
     */
    @PostMapping(value = "/upload", consumes = MediaType.MULTIPART_FORM_DATA_VALUE)
    @PreAuthorize("@authorizationService.hasPermission(T(com.svtrucking.logistics.security.PermissionNames).IMAGE_CREATE)")
    public ResponseEntity<ApiResponse<Map<String, Object>>> uploadImage(
            @RequestParam("file") MultipartFile file,
            @RequestParam(value = "category", defaultValue = "general") String category,
            @RequestParam(value = "description", required = false) String description) {
        try {
            if (file.isEmpty()) {
                return ResponseEntity.badRequest()
                    .body(ApiResponse.fail("File cannot be empty"));
            }

            Map<String, Object> imageInfo = imageManagementService.uploadImage(file, category, description);
            return ResponseEntity.ok(ApiResponse.success("Image uploaded successfully", imageInfo));
        } catch (Exception e) {
            log.error("Error uploading image: {}", e.getMessage(), e);
            return ResponseEntity.status(HttpStatus.BAD_REQUEST)
                .body(ApiResponse.fail("Upload failed: " + e.getMessage()));
        }
    }

    /**
     * Delete an image
     */
    @DeleteMapping("/{imageId}")
    @PreAuthorize("@authorizationService.hasPermission(T(com.svtrucking.logistics.security.PermissionNames).IMAGE_DELETE)")
    public ResponseEntity<ApiResponse<String>> deleteImage(@PathVariable String imageId) {
        try {
            imageManagementService.deleteImage(imageId);
            return ResponseEntity.ok(ApiResponse.success("Image deleted successfully"));
        } catch (Exception e) {
            log.error("Error deleting image {}: {}", imageId, e.getMessage(), e);
            return ResponseEntity.status(HttpStatus.BAD_REQUEST)
                .body(ApiResponse.fail("Delete failed: " + e.getMessage()));
        }
    }

    /**
     * Update image metadata
     */
    @PutMapping("/{imageId}")
    @PreAuthorize("@authorizationService.hasPermission(T(com.svtrucking.logistics.security.PermissionNames).IMAGE_UPDATE)")
    public ResponseEntity<ApiResponse<Map<String, Object>>> updateImageMetadata(
            @PathVariable String imageId,
            @RequestBody Map<String, Object> metadata) {
        try {
            Map<String, Object> updatedImage = imageManagementService.updateImageMetadata(imageId, metadata);
            return ResponseEntity.ok(ApiResponse.success("Image metadata updated successfully", updatedImage));
        } catch (Exception e) {
            log.error("Error updating image metadata {}: {}", imageId, e.getMessage(), e);
            return ResponseEntity.status(HttpStatus.BAD_REQUEST)
                .body(ApiResponse.fail("Update failed: " + e.getMessage()));
        }
    }

    /**
     * Get images by category
     */
    @GetMapping("/category/{category}")
    @PreAuthorize("@authorizationService.hasPermission(T(com.svtrucking.logistics.security.PermissionNames).IMAGE_READ)")
    public ResponseEntity<ApiResponse<List<Map<String, Object>>>> getImagesByCategory(@PathVariable String category) {
        try {
            List<Map<String, Object>> images = imageManagementService.getImagesByCategory(category);
            return ResponseEntity.ok(ApiResponse.success("Images retrieved successfully", images));
        } catch (Exception e) {
            log.error("Error retrieving images by category {}: {}", category, e.getMessage(), e);
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                .body(ApiResponse.fail("Failed to retrieve images: " + e.getMessage()));
        }
    }
}
