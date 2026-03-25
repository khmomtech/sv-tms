package com.svtrucking.logistics.enums;

/**
 * Customer lifecycle stages for tracking customer journey
 * from lead to long-term customer or churn.
 */
public enum CustomerLifecycleStage {
    /**
     * Initial contact or inquiry, not yet qualified
     */
    LEAD,
    
    /**
     * Qualified lead, potential customer showing interest
     */
    PROSPECT,
    
    /**
     * Qualified prospect ready for conversion
     */
    QUALIFIED,
    
    /**
     * Active customer with at least one order
     */
    CUSTOMER,
    
    /**
     * Customer showing signs of churn (no orders recently)
     */
    AT_RISK,
    
    /**
     * Inactive customer, no recent activity
     */
    DORMANT,
    
    /**
     * Lost customer, churned
     */
    CHURNED
}
