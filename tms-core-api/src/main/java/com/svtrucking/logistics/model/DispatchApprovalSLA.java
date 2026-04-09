package com.svtrucking.logistics.model;

import com.svtrucking.logistics.enums.DispatchApprovalStatus;
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
import jakarta.persistence.OneToOne;
import jakarta.persistence.Table;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;
import org.hibernate.annotations.CreationTimestamp;
import org.hibernate.annotations.UpdateTimestamp;

import java.time.LocalDateTime;

/**
 * SLA tracking for dispatch approval turnaround time.
 * Measures time from dispatch DELIVERED status to APPROVED status.
 * Helps identify slow approvals and measure dispatcher performance.
 * 
 * Default SLA target: 120 minutes (2 hours) from delivery to approval.
 * Configurable via feature toggle: closure-sla-target-minutes
 */
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
@Entity
@Table(name = "dispatch_approval_sla", indexes = {
        @Index(name = "idx_approval_sla_dispatch", columnList = "dispatch_id"),
        @Index(name = "idx_approval_sla_status", columnList = "status"),
        @Index(name = "idx_approval_sla_delivered_at", columnList = "delivered_at")
})
public class DispatchApprovalSLA {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @OneToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "dispatch_id", nullable = false, unique = true)
    private Dispatch dispatch;

    @Enumerated(EnumType.STRING)
    @Column(name = "status", nullable = false, length = 50)
    private DispatchApprovalStatus status;

    @Column(name = "delivered_at", nullable = false)
    private LocalDateTime deliveredAt;

    @Column(name = "approval_submitted_at")
    private LocalDateTime approvalSubmittedAt;

    @Column(name = "approved_at")
    private LocalDateTime approvedAt;

    @Column(name = "sla_target_minutes", nullable = false)
    private Integer slaTargetMinutes;

    @Column(name = "actual_minutes")
    private Integer actualMinutes;

    @Enumerated(EnumType.STRING)
    @Column(name = "sla_status", length = 20)
    private SLAStatus slaStatus;

    @CreationTimestamp
    @Column(name = "created_at", nullable = false, updatable = false)
    private LocalDateTime createdAt;

    @UpdateTimestamp
    @Column(name = "updated_at")
    private LocalDateTime updatedAt;

    /**
     * SLA compliance status
     */
    public enum SLAStatus {
        ON_TRACK("Within SLA target"),
        BREACHED("Exceeded SLA target"),
        PENDING("Waiting for approval completion");

        private final String description;

        SLAStatus(String description) {
            this.description = description;
        }

        public String getDescription() {
            return description;
        }
    }

    public void calculateActualMinutes() {
        if (approvedAt != null && deliveredAt != null) {
            this.actualMinutes = (int) java.time.temporal.ChronoUnit.MINUTES.between(deliveredAt, approvedAt);
            this.slaStatus = actualMinutes <= (slaTargetMinutes != null ? slaTargetMinutes : 120)
                    ? SLAStatus.ON_TRACK
                    : SLAStatus.BREACHED;
        } else {
            this.slaStatus = SLAStatus.PENDING;
        }
    }

    public boolean isSLABreached() {
        return actualMinutes != null && actualMinutes > (slaTargetMinutes != null ? slaTargetMinutes : 120);
    }
}
