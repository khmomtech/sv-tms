package com.svtrucking.telematics.dto.responses;

import lombok.Builder;
import lombok.Getter;

@Getter
@Builder
public class TrackingSessionResponse {
    private String sessionId;
    private String trackingToken;
    private String scope;
    private long expiresAtEpochMs;
}
