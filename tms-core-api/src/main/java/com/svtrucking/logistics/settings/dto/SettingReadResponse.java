package com.svtrucking.logistics.settings.dto;

import com.fasterxml.jackson.annotation.JsonInclude;

@JsonInclude(JsonInclude.Include.NON_NULL)
public record SettingReadResponse(
    String groupCode,
    String keyCode,
    String type,
    Object value,
    String scope,
    String scopeRef,
    Integer version,
    String updatedBy,
    String updatedAt) {}
