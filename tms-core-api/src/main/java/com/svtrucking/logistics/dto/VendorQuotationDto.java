package com.svtrucking.logistics.dto;

import com.svtrucking.logistics.enums.VendorQuotationStatus;
import com.svtrucking.logistics.model.VendorQuotation;
import jakarta.validation.constraints.DecimalMin;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;
import java.math.BigDecimal;
import java.time.LocalDateTime;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class VendorQuotationDto {
  private Long id;

  @NotNull(message = "Work order ID is required")
  private Long workOrderId;

  @NotNull(message = "Vendor ID is required")
  private Long vendorId;

  private String vendorName;

  @Size(max = 100, message = "Quotation number cannot exceed 100 characters")
  private String quotationNumber;

  @NotNull(message = "Amount is required")
  @DecimalMin(value = "0.0", inclusive = true, message = "Amount must be >= 0")
  private BigDecimal amount;

  private VendorQuotationStatus status;
  private String notes;

  private LocalDateTime createdAt;
  private LocalDateTime approvedAt;
  private Long approvedById;
  private String approvedByName;
  private String rejectionReason;

  public static VendorQuotationDto fromEntity(VendorQuotation q) {
    if (q == null) return null;
    return VendorQuotationDto.builder()
        .id(q.getId())
        .workOrderId(q.getWorkOrder() != null ? q.getWorkOrder().getId() : null)
        .vendorId(q.getVendor() != null ? q.getVendor().getId() : null)
        .vendorName(
            q.getVendor() != null && q.getVendor().getPartnerCompany() != null
                ? q.getVendor().getPartnerCompany().getCompanyName()
                : null)
        .quotationNumber(q.getQuotationNumber())
        .amount(q.getAmount())
        .status(q.getStatus())
        .notes(q.getNotes())
        .createdAt(q.getCreatedAt())
        .approvedAt(q.getApprovedAt())
        .approvedById(q.getApprovedBy() != null ? q.getApprovedBy().getId() : null)
        .approvedByName(q.getApprovedBy() != null ? q.getApprovedBy().getUsername() : null)
        .rejectionReason(q.getRejectionReason())
        .build();
  }
}

