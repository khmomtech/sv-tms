package com.svtrucking.logistics.service;

import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import org.springframework.web.multipart.MultipartFile;

import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.nio.file.StandardCopyOption;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.*;
import java.util.stream.Collectors;

/**
 * Service for managing application images (banners, logos, etc.)
 */
@Slf4j
@Service
@RequiredArgsConstructor
public class ImageManagementService {

    @Value("${app.upload.images.path:uploads/images}")
    private String imagesBasePath;

    private static final Set<String> ALLOWED_EXTENSIONS = Set.of("jpg", "jpeg", "png", "gif", "webp", "svg");
    private static final long MAX_FILE_SIZE = 5 * 1024 * 1024; // 5MB

    /**
     * Get all managed images
     */
    public List<Map<String, Object>> getAllImages() {
        try {
            Path imagesPath = Paths.get(imagesBasePath);
            if (!Files.exists(imagesPath)) {
                Files.createDirectories(imagesPath);
                return new ArrayList<>();
            }

            return Files.walk(imagesPath)
                .filter(Files::isRegularFile)
                .filter(path -> isImageFile(path))
                .map(this::createImageInfo)
                .collect(Collectors.toList());
        } catch (IOException e) {
            log.error("Error listing images: {}", e.getMessage(), e);
            throw new RuntimeException("Failed to list images", e);
        }
    }

    /**
     * Upload a new image
     */
    public Map<String, Object> uploadImage(MultipartFile file, String category, String description) {
        validateImageFile(file);

        try {
            // Create category directory if it doesn't exist
            Path categoryPath = Paths.get(imagesBasePath, category);
            Files.createDirectories(categoryPath);

            // Generate unique filename
            String originalFilename = file.getOriginalFilename();
            String extension = getFileExtension(originalFilename);
            String timestamp = LocalDateTime.now().format(DateTimeFormatter.ofPattern("yyyyMMdd_HHmmss"));
            String uniqueFilename = timestamp + "_" + UUID.randomUUID().toString().substring(0, 8) + "." + extension;
            Path targetPath = categoryPath.resolve(uniqueFilename);

            // Save file
            Files.copy(file.getInputStream(), targetPath, StandardCopyOption.REPLACE_EXISTING);

            // Create image info
            Map<String, Object> imageInfo = new HashMap<>();
            imageInfo.put("id", uniqueFilename);
            imageInfo.put("filename", uniqueFilename);
            imageInfo.put("originalFilename", originalFilename);
            imageInfo.put("category", category);
            imageInfo.put("description", description != null ? description : "");
            imageInfo.put("size", file.getSize());
            imageInfo.put("uploadDate", LocalDateTime.now());
            imageInfo.put("url", "/uploads/images/" + category + "/" + uniqueFilename);

            log.info("Image uploaded successfully: {}", uniqueFilename);
            return imageInfo;

        } catch (IOException e) {
            log.error("Error uploading image: {}", e.getMessage(), e);
            throw new RuntimeException("Failed to upload image", e);
        }
    }

    /**
     * Delete an image
     */
    public void deleteImage(String imageId) {
        try {
            // Find the image file
            Path imagesPath = Paths.get(imagesBasePath);
            Optional<Path> imagePath = Files.walk(imagesPath)
                .filter(Files::isRegularFile)
                .filter(path -> path.getFileName().toString().equals(imageId))
                .findFirst();

            if (imagePath.isPresent()) {
                Files.delete(imagePath.get());
                log.info("Image deleted successfully: {}", imageId);
            } else {
                throw new RuntimeException("Image not found: " + imageId);
            }
        } catch (IOException e) {
            log.error("Error deleting image {}: {}", imageId, e.getMessage(), e);
            throw new RuntimeException("Failed to delete image", e);
        }
    }

    /**
     * Update image metadata
     */
    public Map<String, Object> updateImageMetadata(String imageId, Map<String, Object> metadata) {
        try {
            // Find the image file
            Path imagesPath = Paths.get(imagesBasePath);
            Optional<Path> imagePath = Files.walk(imagesPath)
                .filter(Files::isRegularFile)
                .filter(path -> path.getFileName().toString().equals(imageId))
                .findFirst();

            if (imagePath.isPresent()) {
                Map<String, Object> imageInfo = createImageInfo(imagePath.get());

                // Update metadata
                if (metadata.containsKey("category")) {
                    imageInfo.put("category", metadata.get("category"));
                }
                if (metadata.containsKey("description")) {
                    imageInfo.put("description", metadata.get("description"));
                }

                log.info("Image metadata updated: {}", imageId);
                return imageInfo;
            } else {
                throw new RuntimeException("Image not found: " + imageId);
            }
        } catch (Exception e) {
            log.error("Error updating image metadata {}: {}", imageId, e.getMessage(), e);
            throw new RuntimeException("Failed to update image metadata", e);
        }
    }

    /**
     * Get images by category
     */
    public List<Map<String, Object>> getImagesByCategory(String category) {
        try {
            Path categoryPath = Paths.get(imagesBasePath, category);
            if (!Files.exists(categoryPath)) {
                return new ArrayList<>();
            }

            return Files.walk(categoryPath)
                .filter(Files::isRegularFile)
                .filter(path -> isImageFile(path))
                .map(this::createImageInfo)
                .collect(Collectors.toList());
        } catch (IOException e) {
            log.error("Error listing images by category {}: {}", category, e.getMessage(), e);
            throw new RuntimeException("Failed to list images by category", e);
        }
    }

    private void validateImageFile(MultipartFile file) {
        if (file.isEmpty()) {
            throw new IllegalArgumentException("File cannot be empty");
        }

        String filename = file.getOriginalFilename();
        if (filename == null || filename.trim().isEmpty()) {
            throw new IllegalArgumentException("Filename cannot be empty");
        }

        String extension = getFileExtension(filename).toLowerCase();
        if (!ALLOWED_EXTENSIONS.contains(extension)) {
            throw new IllegalArgumentException("Invalid file type. Allowed types: " + ALLOWED_EXTENSIONS);
        }

        if (file.getSize() > MAX_FILE_SIZE) {
            throw new IllegalArgumentException("File size exceeds maximum allowed size of 5MB");
        }
    }

    private boolean isImageFile(Path path) {
        String filename = path.getFileName().toString().toLowerCase();
        return ALLOWED_EXTENSIONS.stream().anyMatch(ext -> filename.endsWith("." + ext));
    }

    private String getFileExtension(String filename) {
        int lastDotIndex = filename.lastIndexOf('.');
        if (lastDotIndex == -1 || lastDotIndex == filename.length() - 1) {
            return "";
        }
        return filename.substring(lastDotIndex + 1);
    }

    private Map<String, Object> createImageInfo(Path imagePath) {
        try {
            Map<String, Object> info = new HashMap<>();
            String filename = imagePath.getFileName().toString();
            Path relativePath = Paths.get(imagesBasePath).relativize(imagePath);
            String category = relativePath.getNameCount() > 1 ? relativePath.getParent().toString() : "general";

            info.put("id", filename);
            info.put("filename", filename);
            info.put("category", category);
            info.put("size", Files.size(imagePath));
            info.put("url", "/uploads/images/" + relativePath.toString().replace("\\", "/"));
            info.put("uploadDate", Files.getLastModifiedTime(imagePath).toMillis());

            return info;
        } catch (IOException e) {
            log.error("Error creating image info for {}: {}", imagePath, e.getMessage());
            return new HashMap<>();
        }
    }
}
