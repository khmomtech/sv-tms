package com.svtrucking.logistics.dto;

import com.fasterxml.jackson.annotation.JsonIgnoreProperties;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;

/**
 * DTO for Banner entity
 */
@JsonIgnoreProperties(ignoreUnknown = true)
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class BannerDto {

    private Long id;
    private String title;
    private String titleKh;
    private String subtitle;
    private String subtitleKh;
    private String imageUrl;
    private String category;
    private String targetUrl;
    private Integer displayOrder;

    // Accept old frontend compatibility field without storing it
    @com.fasterxml.jackson.annotation.JsonProperty("svgImage")
    private void acceptSvgImage(@SuppressWarnings("unused") String svgImageValue) {
        // intentionally consumed and ignored in backend
    }

    @com.fasterxml.jackson.annotation.JsonIgnore
    public boolean isSvgImage() {
        return imageUrl != null && imageUrl.toLowerCase().endsWith(".svg");
    }

    @com.fasterxml.jackson.annotation.JsonIgnore
    public String getImageType() {
        if (imageUrl == null) return "unknown";
        String lower = imageUrl.toLowerCase();
        if (lower.endsWith(".svg")) return "svg";
        if (lower.endsWith(".png")) return "png";
        if (lower.endsWith(".jpg") || lower.endsWith(".jpeg")) return "jpg";
        if (lower.endsWith(".webp")) return "webp";
        if (lower.endsWith(".gif")) return "gif";
        return "unknown";
    }

    @com.fasterxml.jackson.annotation.JsonFormat(pattern = "yyyy-MM-dd'T'HH:mm:ss")
    private LocalDateTime startDate;

    @com.fasterxml.jackson.annotation.JsonFormat(pattern = "yyyy-MM-dd'T'HH:mm:ss")
    private LocalDateTime endDate;

    private Boolean active;
    private Integer clickCount;
    private Integer viewCount;
    private String createdBy;
    private LocalDateTime createdAt;
    private LocalDateTime updatedAt;
}

