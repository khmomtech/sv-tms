package com.svtrucking.logistics.model;

import com.fasterxml.jackson.annotation.JsonIgnore;
import com.fasterxml.jackson.annotation.JsonIgnoreProperties;
import com.svtrucking.logistics.core.BaseEntity;
import com.svtrucking.logistics.enums.CustomerType;
import com.svtrucking.logistics.enums.CustomerLifecycleStage;
import com.svtrucking.logistics.enums.Status;
import jakarta.persistence.CascadeType;
import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.FetchType;
import jakarta.persistence.Inheritance;
import jakarta.persistence.InheritanceType;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.ManyToOne;
import jakarta.persistence.OneToMany;
import jakarta.persistence.OneToOne;
import jakarta.persistence.Table;
import jakarta.persistence.Column;
import jakarta.persistence.Transient;
import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.List;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.EqualsAndHashCode;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;
import lombok.ToString;

@JsonIgnoreProperties({ "hibernateLazyInitializer", "handler" }) //
@ToString
@EqualsAndHashCode(callSuper = true)
@Setter
@Getter
@Data
@NoArgsConstructor
@AllArgsConstructor
@Entity
@Inheritance(strategy = InheritanceType.JOINED)
@Table(name = "customers")
public class Customer extends BaseEntity {

    private String customerCode; // <-- Add this line

    @Enumerated(EnumType.STRING)
    private CustomerType type;

    private String name;
    private String email;
    private String phone;
    private String address;

    @Enumerated(EnumType.STRING)
    private Status status = Status.ACTIVE;

    // ==================== Soft Delete Fields ====================
    @Column(name = "deleted_at")
    private LocalDateTime deletedAt;

    @Column(name = "deleted_by", length = 100)
    private String deletedBy;

    // ==================== Financial Fields ====================
    @Column(name = "credit_limit", precision = 15, scale = 2)
    private BigDecimal creditLimit = BigDecimal.ZERO;

    @Column(name = "payment_terms", length = 50)
    private String paymentTerms = "NET_30";

    @Column(length = 3)
    private String currency = "USD";

    @Column(name = "current_balance", precision = 15, scale = 2)
    private BigDecimal currentBalance = BigDecimal.ZERO;

    // ==================== Lifecycle & Business Metrics ====================
    @Enumerated(EnumType.STRING)
    @Column(name = "lifecycle_stage", length = 20)
    private CustomerLifecycleStage lifecycleStage = CustomerLifecycleStage.CUSTOMER;

    @Column(name = "last_order_date")
    private LocalDate lastOrderDate;

    @Column(name = "total_orders")
    private Integer totalOrders = 0;

    @Column(name = "total_revenue", precision = 15, scale = 2)
    private BigDecimal totalRevenue = BigDecimal.ZERO;

    @Column(name = "first_order_date")
    private LocalDate firstOrderDate;

    @Column(length = 50)
    private String segment;

    // ==================== Customer Segmentation & Health ====================
    @Column(columnDefinition = "JSON")
    private String tags; // JSON array of tag strings

    @Column(name = "customer_segment", length = 20)
    private String customerSegment; // VIP, REGULAR, HIGH_VALUE, AT_RISK, NEW, DORMANT

    @Column(name = "health_score")
    private Integer healthScore; // 0-100

    // ==================== Relationships ====================
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "account_manager_id")
    private User accountManager;

    /** Optional login account for customer portal access */
    @OneToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "user_id", unique = true)
    private User user;

    /** Optional link to partner company (for corporate customers) */
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "partner_company_id")
    private PartnerCompany partnerCompany;

    // LAZY by default; never serialize directly
    @OneToMany(mappedBy = "customer", cascade = CascadeType.ALL, orphanRemoval = true, fetch = FetchType.LAZY)
    @JsonIgnore // prevent Jackson from touching it on list endpoints
    @ToString.Exclude
    @EqualsAndHashCode.Exclude
    private List<Address> addresses;

    // ==================== Push Notifications ====================
    @Transient
    private String deviceToken;
}
