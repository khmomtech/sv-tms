package com.svtrucking.logistics.controller;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.io.File;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.util.HashMap;
import java.util.Map;

/**
 * Health Check Controller
 * Provides health check endpoints for monitoring system status
 */
@RestController
@RequestMapping("/api/health")
public class HealthController {

    @Value("${file.upload.base-dir:uploads}")
    private String uploadBaseDir;

    /**
     * Basic health check endpoint
     * @return Health status
     */
    @GetMapping
    public ResponseEntity<Map<String, Object>> health() {
        Map<String, Object> response = new HashMap<>();
        response.put("status", "UP");
        response.put("timestamp", System.currentTimeMillis());
        response.put("service", "sv-tms-backend");

        return ResponseEntity.ok(response);
    }

    /**
     * Detailed health check including uploads directory status
     * @return Detailed health status
     */
    @GetMapping("/detailed")
    public ResponseEntity<Map<String, Object>> detailedHealth() {
        Map<String, Object> response = new HashMap<>();
        response.put("status", "UP");
        response.put("timestamp", System.currentTimeMillis());
        response.put("service", "sv-tms-backend");

        // Check uploads directory health
        Map<String, Object> uploadsHealth = checkUploadsHealth();
        response.put("uploads", uploadsHealth);

        // Determine overall status
        if ("DOWN".equals(uploadsHealth.get("status"))) {
            response.put("status", "DEGRADED");
        }

        return ResponseEntity.ok(response);
    }

    /**
     * Check uploads directory health
     * @return Uploads health status
     */
    private Map<String, Object> checkUploadsHealth() {
        Map<String, Object> uploadsHealth = new HashMap<>();

        try {
            Path uploadPath = Paths.get(uploadBaseDir);

            // Check if directory exists
            if (!Files.exists(uploadPath)) {
                uploadsHealth.put("status", "DOWN");
                uploadsHealth.put("message", "Uploads directory does not exist: " + uploadBaseDir);
                return uploadsHealth;
            }

            // Check if it's a directory
            if (!Files.isDirectory(uploadPath)) {
                uploadsHealth.put("status", "DOWN");
                uploadsHealth.put("message", "Uploads path is not a directory: " + uploadBaseDir);
                return uploadsHealth;
            }

            // Check if directory is readable
            if (!Files.isReadable(uploadPath)) {
                uploadsHealth.put("status", "DOWN");
                uploadsHealth.put("message", "Uploads directory is not readable: " + uploadBaseDir);
                return uploadsHealth;
            }

            // Check if directory is writable
            if (!Files.isWritable(uploadPath)) {
                uploadsHealth.put("status", "DOWN");
                uploadsHealth.put("message", "Uploads directory is not writable: " + uploadBaseDir);
                return uploadsHealth;
            }

            // Get directory information
            File uploadDir = uploadPath.toFile();
            long totalSpace = uploadDir.getTotalSpace();
            long freeSpace = uploadDir.getFreeSpace();
            long usableSpace = uploadDir.getUsableSpace();

            // Get file count (basic)
            String[] files = uploadDir.list();
            int fileCount = files != null ? files.length : 0;

            uploadsHealth.put("status", "UP");
            uploadsHealth.put("path", uploadBaseDir);
            uploadsHealth.put("absolutePath", uploadPath.toAbsolutePath().toString());
            uploadsHealth.put("fileCount", fileCount);
            uploadsHealth.put("totalSpace", totalSpace);
            uploadsHealth.put("freeSpace", freeSpace);
            uploadsHealth.put("usableSpace", usableSpace);
            uploadsHealth.put("readable", true);
            uploadsHealth.put("writable", true);

        } catch (Exception e) {
            uploadsHealth.put("status", "DOWN");
            uploadsHealth.put("message", "Error checking uploads directory: " + e.getMessage());
            uploadsHealth.put("error", e.getClass().getSimpleName());
        }

        return uploadsHealth;
    }
}
