package com.svtrucking.logistics.dto;

import java.time.LocalDateTime;

import com.svtrucking.logistics.model.CustomerContact;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class CustomerContactDto {
    
    private Long id;
    private Long customerId;
    private String customerName;
    private String fullName;
    private String email;
    private String phone;
    private String position;
    private Boolean isPrimary;
    private Boolean isActive;
    private LocalDateTime lastLogin;
    private String notes;
    private LocalDateTime createdAt;
    private LocalDateTime updatedAt;

    /**
     * Convert entity to DTO
     */
    public static CustomerContactDto fromEntity(CustomerContact contact) {
        if (contact == null) {
            return null;
        }
        
        return CustomerContactDto.builder()
            .id(contact.getId())
            .customerId(contact.getCustomer() != null ? contact.getCustomer().getId() : null)
            .customerName(contact.getCustomer() != null ? contact.getCustomer().getName() : null)
            .fullName(contact.getFullName())
            .email(contact.getEmail())
            .phone(contact.getPhone())
            .position(contact.getPosition())
            .isPrimary(contact.getIsPrimary())
            .isActive(contact.getIsActive())
            .lastLogin(contact.getLastLogin())
            .notes(contact.getNotes())
            .createdAt(contact.getCreatedAt())
            .updatedAt(contact.getUpdatedAt())
            .build();
    }
}
