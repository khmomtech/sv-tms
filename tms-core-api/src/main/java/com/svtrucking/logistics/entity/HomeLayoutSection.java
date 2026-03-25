package com.svtrucking.logistics.entity;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.PrePersist;
import jakarta.persistence.PreUpdate;
import jakarta.persistence.Table;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

import java.time.LocalDateTime;

/**
 * Entity for managing driver app home screen layout configuration
 * Allows admin to control visibility and order of home screen sections
 */
@Entity
@Table(name = "home_layout_sections")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class HomeLayoutSection {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    /**
     * Unique identifier for the section (e.g., "header", "shift_status", "safety_status")
     */
    @Column(name = "section_key", nullable = false, unique = true, length = 50)
    private String sectionKey;

    /**
     * Display name for admin UI (English)
     */
    @Column(name = "section_name", nullable = false, length = 100)
    private String sectionName;

    /**
     * Display name for admin UI (Khmer)
     */
    @Column(name = "section_name_kh", length = 100)
    private String sectionNameKh;

    /**
     * Description of what this section does
     */
    @Column(length = 500)
    private String description;

    /**
     * Description in Khmer
     */
    @Column(name = "description_kh", length = 500)
    private String descriptionKh;

    /**
     * Display order (lower numbers appear first)
     */
    @Column(name = "display_order", nullable = false)
    @Builder.Default
    private Integer displayOrder = 0;

    /**
     * Whether this section is visible to drivers
     */
    @Column(nullable = false)
    @Builder.Default
    private Boolean visible = true;

    /**
     * Whether this section can be hidden by admin
     * Some sections like header might be mandatory
     */
    @Column(name = "is_mandatory", nullable = false)
    @Builder.Default
    private Boolean isMandatory = false;

    /**
     * Icon name for admin UI (e.g., "home", "safety", "trip")
     */
    @Column(length = 50)
    private String icon;

    /**
     * Category for grouping sections in admin UI
     */
    @Column(length = 50)
    @Builder.Default
    private String category = "general";

    /**
     * Configuration JSON for section-specific settings
     * e.g., {"refreshInterval": 30, "itemLimit": 5}
     */
    @Column(name = "config_json", columnDefinition = "TEXT")
    private String configJson;

    @Column(name = "created_by", length = 100)
    private String createdBy;

    @Column(name = "created_at", nullable = false, updatable = false)
    private LocalDateTime createdAt;

    @Column(name = "updated_by", length = 100)
    private String updatedBy;

    @Column(name = "updated_at", nullable = false)
    private LocalDateTime updatedAt;

    @PrePersist
    protected void onCreate() {
        createdAt = LocalDateTime.now();
        updatedAt = LocalDateTime.now();
    }

    @PreUpdate
    protected void onUpdate() {
        updatedAt = LocalDateTime.now();
    }
}
