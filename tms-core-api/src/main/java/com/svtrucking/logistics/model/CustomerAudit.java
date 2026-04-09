package com.svtrucking.logistics.model;

import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;
import java.time.LocalDateTime;

/**
 * Audit trail entity for tracking all changes to Customer records.
 * Provides complete history of who changed what and when.
 */
@Entity
@Table(name = "customer_audit", indexes = {
    @Index(name = "idx_audit_customer_id", columnList = "customer_id"),
    @Index(name = "idx_audit_changed_at", columnList = "changed_at"),
    @Index(name = "idx_audit_action", columnList = "action")
})
@Data
@NoArgsConstructor
@AllArgsConstructor
public class CustomerAudit {
    
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;
    
    @Column(name = "customer_id", nullable = false)
    private Long customerId;
    
    @Column(nullable = false, length = 20)
    @Enumerated(EnumType.STRING)
    private AuditAction action;
    
    @Column(name = "changed_by", nullable = false, length = 100)
    private String changedBy;
    
    @Column(name = "changed_at", nullable = false)
    private LocalDateTime changedAt;
    
    @Column(name = "field_name", length = 100)
    private String fieldName;
    
    @Column(name = "old_value", columnDefinition = "TEXT")
    private String oldValue;
    
    @Column(name = "new_value", columnDefinition = "TEXT")
    private String newValue;
    
    @Column(columnDefinition = "TEXT")
    private String notes;
    
    /**
     * Audit action types
     */
    public enum AuditAction {
        CREATE,
        UPDATE,
        DELETE,
        RESTORE,
        STATUS_CHANGE,
        LIFECYCLE_CHANGE
    }
    
    /**
     * Factory method to create audit record for creation
     */
    public static CustomerAudit forCreate(Long customerId, String changedBy) {
        CustomerAudit audit = new CustomerAudit();
        audit.setCustomerId(customerId);
        audit.setAction(AuditAction.CREATE);
        audit.setChangedBy(changedBy);
        audit.setChangedAt(LocalDateTime.now());
        audit.setNotes("Customer created");
        return audit;
    }
    
    /**
     * Factory method to create audit record for field update
     */
    public static CustomerAudit forUpdate(Long customerId, String changedBy, 
                                          String fieldName, String oldValue, String newValue) {
        CustomerAudit audit = new CustomerAudit();
        audit.setCustomerId(customerId);
        audit.setAction(AuditAction.UPDATE);
        audit.setChangedBy(changedBy);
        audit.setChangedAt(LocalDateTime.now());
        audit.setFieldName(fieldName);
        audit.setOldValue(oldValue);
        audit.setNewValue(newValue);
        return audit;
    }
    
    /**
     * Factory method to create audit record for deletion
     */
    public static CustomerAudit forDelete(Long customerId, String changedBy) {
        CustomerAudit audit = new CustomerAudit();
        audit.setCustomerId(customerId);
        audit.setAction(AuditAction.DELETE);
        audit.setChangedBy(changedBy);
        audit.setChangedAt(LocalDateTime.now());
        audit.setNotes("Customer soft deleted");
        return audit;
    }
}
