package com.svtrucking.logistics.settings.dto;

import com.fasterxml.jackson.annotation.JsonInclude;

@JsonInclude(JsonInclude.Include.NON_NULL)
public record SettingWriteRequest(
    String groupCode,
    String keyCode,
    String scope, // GLOBAL / TENANT / SITE
    String scopeRef, // null for GLOBAL
    Object value, // any JSON value
    String reason // required for audit
    ) {}
