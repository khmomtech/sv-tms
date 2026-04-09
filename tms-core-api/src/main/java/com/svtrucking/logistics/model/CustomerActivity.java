package com.svtrucking.logistics.model;

import com.svtrucking.logistics.core.BaseEntity;
import com.svtrucking.logistics.enums.ActivityType;
import jakarta.persistence.*;
import lombok.*;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
@Entity
@Table(name = "customer_activities", indexes = {
    @Index(name = "idx_customer_created", columnList = "customer_id,created_at"),
    @Index(name = "idx_activity_type", columnList = "type")
})
public class CustomerActivity extends BaseEntity {

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "customer_id", nullable = false)
    private Customer customer;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 50)
    private ActivityType type;

    @Column(nullable = false, length = 255)
    private String title;

    @Column(columnDefinition = "TEXT")
    private String description;

    @Column(name = "metadata", columnDefinition = "TEXT")
    private String metadata; // Store JSON as string

    @Column(name = "related_entity_id")
    private Long relatedEntityId;

    @Column(name = "related_entity_type", length = 50)
    private String relatedEntityType; // e.g., "ORDER", "PAYMENT", "DISPATCH"

    @Column(name = "created_by_name", length = 100)
    private String createdByName;
}
