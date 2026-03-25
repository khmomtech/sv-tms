package com.svtrucking.logistics.settings.config;

import org.springframework.context.annotation.Configuration;
import org.springframework.security.config.annotation.method.configuration.EnableMethodSecurity;

@Configuration
@EnableMethodSecurity
public class SettingsSecurity {
  // Method-level security via @PreAuthorize in controller/service
}
