package com.svtrucking.logistics.dto.requests;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Pattern;
import lombok.Data;

@Data
public class CreatePermissionRequest {
    
    @NotBlank(message = "Permission name is required")
    @Pattern(regexp = "^(all_functions|[a-zA-Z][a-zA-Z0-9_]*:[a-zA-Z][a-zA-Z0-9_]*)$", 
             message = "Permission name must follow format 'resource:action' or be 'all_functions'")
    private String name;
    
    @NotBlank(message = "Description is required")
    private String description;
    
    @NotBlank(message = "Resource type is required")
    private String resourceType;
    
    @NotBlank(message = "Action type is required")
    private String actionType;
}