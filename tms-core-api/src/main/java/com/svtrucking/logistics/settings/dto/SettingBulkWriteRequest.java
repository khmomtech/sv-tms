package com.svtrucking.logistics.settings.dto;

import java.util.List;

public record SettingBulkWriteRequest(List<SettingWriteRequest> items, boolean dryRun) {}
