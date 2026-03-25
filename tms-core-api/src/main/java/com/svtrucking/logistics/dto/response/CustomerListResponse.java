package com.svtrucking.logistics.dto.response;

import com.svtrucking.logistics.enums.CustomerType;
import com.svtrucking.logistics.enums.Status;
import com.svtrucking.logistics.model.Customer;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

/**
 * Lightweight Response DTO for Customer entity - list view.
 * Used for customer lists (GET /customers) to reduce payload size.
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class CustomerListResponse {
    
    private Long id;
    private String customerCode;
    private String name;
    private CustomerType type;
    private String phone;
    private String email;
    private Status status;
    private Boolean hasAccount;

    /**
     * Converts Customer entity to lightweight CustomerListResponse DTO.
     */
    public static CustomerListResponse fromEntity(Customer customer) {
        if (customer == null) {
            return null;
        }

        return CustomerListResponse.builder()
                .id(customer.getId())
                .customerCode(customer.getCustomerCode())
                .name(customer.getName())
                .type(customer.getType())
                .phone(customer.getPhone())
                .email(customer.getEmail())
                .status(customer.getStatus())
                .hasAccount(customer.getUser() != null)
                .build();
    }
}
