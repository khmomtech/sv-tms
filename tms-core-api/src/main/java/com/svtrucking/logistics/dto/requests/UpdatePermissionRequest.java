package com.svtrucking.logistics.dto.requests;

import jakarta.validation.constraints.NotBlank;
import lombok.Data;

@Data
public class UpdatePermissionRequest {
    
    @NotBlank(message = "Description is required")
    private String description;
    
    @NotBlank(message = "Resource type is required")
    private String resourceType;
    
    @NotBlank(message = "Action type is required")
    private String actionType;
}