package com.svtrucking.logistics.dto.requests;

import jakarta.validation.constraints.NotBlank;
import lombok.Data;

@Data
public class CustomerDeviceTokenRequest {

    @NotBlank
    private String deviceToken;
}
