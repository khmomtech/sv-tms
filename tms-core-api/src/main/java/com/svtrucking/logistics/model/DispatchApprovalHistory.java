package com.svtrucking.logistics.model;

import com.svtrucking.logistics.enums.DispatchApprovalStatus;
import jakarta.persistence.*;
import lombok.*;
import org.hibernate.annotations.CreationTimestamp;

import java.time.LocalDateTime;

/**
 * Audit trail for dispatch approval decisions.
 * Records every approval/rejection action with user, timestamp, and remarks.
 * 
 * Enables compliance tracking, dispute resolution, and SLA measurement.
 */
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
@Entity
@Table(name = "dispatch_approval_history", indexes = {
        @Index(name = "idx_approval_history_dispatch", columnList = "dispatch_id"),
        @Index(name = "idx_approval_history_action", columnList = "action"),
        @Index(name = "idx_approval_history_created", columnList = "created_at")
})
public class DispatchApprovalHistory {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "dispatch_id", nullable = false)
    private Dispatch dispatch;

    @Enumerated(EnumType.STRING)
    @Column(name = "from_status", nullable = false, length = 50)
    private DispatchApprovalStatus fromStatus;

    @Enumerated(EnumType.STRING)
    @Column(name = "to_status", nullable = false, length = 50)
    private DispatchApprovalStatus toStatus;

    @Enumerated(EnumType.STRING)
    @Column(name = "action", nullable = false, length = 20)
    private ApprovalAction action;

    @Column(name = "approval_remarks", columnDefinition = "TEXT")
    private String approvalRemarks;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "reviewed_by", nullable = false)
    private User reviewedBy;

    @CreationTimestamp
    @Column(name = "created_at", nullable = false, updatable = false)
    private LocalDateTime createdAt;

    /**
     * Enum for approval actions
     */
    public enum ApprovalAction {
        APPROVED("Dispatch approved for closure"),
        REJECTED("Dispatch rejected - needs resubmission"),
        ON_HOLD("Dispatch placed on hold for investigation");

        private final String description;

        ApprovalAction(String description) {
            this.description = description;
        }

        public String getDescription() {
            return description;
        }
    }
}
