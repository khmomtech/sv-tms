package com.svtrucking.logistics.config;

import com.svtrucking.logistics.service.SystemInitializationService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.boot.CommandLineRunner;
import org.springframework.context.annotation.Profile;
import org.springframework.stereotype.Component;

/**
 * Enhanced dev initializer that uses SystemInitializationService to set up
 * a complete permission system with all roles, permissions, and users.
 */
@Component
@Profile({"dev", "local"})
@RequiredArgsConstructor
@Slf4j
public class DevDataInitializer implements CommandLineRunner {

  private final SystemInitializationService systemInitializationService;

  @Override
  public void run(String... args) throws Exception {
    log.info("🚀 Starting development environment initialization...");
    
    try {
      // Use the comprehensive system initialization service
      systemInitializationService.initializeCompleteSystem();
      
      log.info("Development environment initialization completed successfully!");
      log.info("📋 Default users created:");
      log.info("   - superadmin / super123 (SUPERADMIN role)");
      log.info("   - admin / admin123 (ADMIN role)");
      log.info("   - manager / manager123 (MANAGER role)");
      log.info("   - driver1 / driver123 (DRIVER role)");
      log.info("   - customer1 / customer123 (CUSTOMER role)");
      
    } catch (Exception e) {
      log.error("❌ Failed to initialize development environment", e);
      throw e;
    }
  }
}
