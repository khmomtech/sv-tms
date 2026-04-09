package com.svtrucking.logistics.model;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.FetchType;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.Index;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.ManyToOne;
import jakarta.persistence.Table;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;
import org.hibernate.annotations.CreationTimestamp;

import java.time.LocalDateTime;

/**
 * Individual safety check item for pre-entry safety inspection.
 * Breakdown of comprehensive safety check into specific categories and items.
 * 
 * Categories:
 * - TIRES: Condition, pressure, tread depth
 * - LIGHTS: Headlights, brake lights, turn signals
 * - LOAD: Securing, weight distribution, overflow
 * - DOCUMENTS: License, insurance, permits
 * - WEIGHT: Axle weight, overload
 * - BRAKES: Brake condition, responsiveness
 * - WINDSHIELD: Glass integrity, visibility
 */
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
@Entity
@Table(name = "pre_entry_safety_items", indexes = {
        @Index(name = "idx_pre_entry_item_check", columnList = "safety_check_id"),
        @Index(name = "idx_pre_entry_item_category", columnList = "category"),
        @Index(name = "idx_pre_entry_item_status", columnList = "status")
})
public class PreEntrySafetyItem {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "safety_check_id", nullable = false)
    private PreEntrySafetyCheck safetyCheck;

    @Enumerated(EnumType.STRING)
    @Column(name = "category", nullable = false, length = 50)
    private SafetyCategory category;

    @Column(name = "item_name", nullable = false, length = 255)
    private String itemName;

    @Enumerated(EnumType.STRING)
    @Column(name = "status", nullable = false, length = 50)
    private SafetyItemStatus status;

    @Column(name = "remarks", columnDefinition = "TEXT")
    private String remarks;

    @Column(name = "photo_path", length = 255)
    private String photoPath;

    @CreationTimestamp
    @Column(name = "created_at", nullable = false, updatable = false)
    private LocalDateTime createdAt;

    /**
     * Safety check item categories
     */
    public enum SafetyCategory {
        TIRES("Tires"),
        LIGHTS("Lights"),
        LOAD("Load & Securing"),
        DOCUMENTS("Documents"),
        WEIGHT("Weight"),
        BRAKES("Brakes"),
        WINDSHIELD("Windshield");

        private final String displayName;

        SafetyCategory(String displayName) {
            this.displayName = displayName;
        }

        public String getDisplayName() {
            return displayName;
        }
    }

    /**
     * Item-level safety status
     */
    public enum SafetyItemStatus {
        OK("Passed"),
        FAILED("Failed"),
        CONDITIONAL("Needs supervisor approval");

        private final String description;

        SafetyItemStatus(String description) {
            this.description = description;
        }

        public String getDescription() {
            return description;
        }
    }
}
