package com.svtrucking.logistics.dto.response;

import com.svtrucking.logistics.enums.CustomerType;
import com.svtrucking.logistics.enums.Status;
import com.svtrucking.logistics.model.Customer;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

/**
 * Response DTO for Customer entity - full details.
 * Used for single customer retrieval (GET /customers/{id}).
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class CustomerResponse {
    
    private Long id;
    private String customerCode;
    private String name;
    private CustomerType type;
    private String phone;
    private String email;
    private String address;
    private Status status;
    
    // User account information (if customer has login)
    private Long userId;
    private String username;
    private Boolean hasAccount;

    /**
     * Converts Customer entity to CustomerResponse DTO.
     */
    public static CustomerResponse fromEntity(Customer customer) {
        if (customer == null) {
            return null;
        }

        return CustomerResponse.builder()
                .id(customer.getId())
                .customerCode(customer.getCustomerCode())
                .name(customer.getName())
                .type(customer.getType())
                .phone(customer.getPhone())
                .email(customer.getEmail())
                .address(customer.getAddress())
                .status(customer.getStatus())
                .userId(customer.getUser() != null ? customer.getUser().getId() : null)
                .username(customer.getUser() != null ? customer.getUser().getUsername() : null)
                .hasAccount(customer.getUser() != null)
                .build();
    }
}
