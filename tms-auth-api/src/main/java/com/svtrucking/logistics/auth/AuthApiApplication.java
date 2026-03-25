package com.svtrucking.logistics.auth;

import com.svtrucking.logistics.controller.AuthController;
import com.svtrucking.logistics.controller.AuthPasswordResetController;
import com.svtrucking.logistics.controller.ReviewerAuthController;
import com.svtrucking.logistics.auth.controller.DeviceAuthMobileController;
import com.svtrucking.logistics.config.LocalizationConfig;
import com.svtrucking.logistics.config.PasswordEncoderConfig;
import com.svtrucking.logistics.repository.DeviceRegisterRepository;
import com.svtrucking.logistics.repository.DriverRepository;
import com.svtrucking.logistics.repository.PasswordResetTokenRepository;
import com.svtrucking.logistics.repository.PermissionRepository;
import com.svtrucking.logistics.repository.RefreshTokenRepository;
import com.svtrucking.logistics.repository.RoleRepository;
import com.svtrucking.logistics.repository.UserRepository;
import com.svtrucking.logistics.security.ApiKeyFilter;
import com.svtrucking.logistics.security.JwtAuthFilter;
import com.svtrucking.logistics.security.JwtUtil;
import com.svtrucking.logistics.service.CustomUserDetailsService;
import com.svtrucking.logistics.service.DeviceRegistrationService;
import com.svtrucking.logistics.service.PasswordResetService;
import com.svtrucking.logistics.service.RefreshTokenService;
import com.svtrucking.logistics.service.UserPermissionService;
import com.svtrucking.logistics.service.LocalizedMessageService;
import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.context.annotation.Import;
import org.springframework.context.annotation.PropertySource;
import org.springframework.data.jpa.repository.config.EnableJpaRepositories;
import org.springframework.boot.autoconfigure.domain.EntityScan;

@SpringBootApplication(scanBasePackages = "com.svtrucking.logistics.auth")
@EntityScan(basePackages = "com.svtrucking.logistics")
@PropertySource("classpath:application-uploads.properties")
@EnableJpaRepositories(basePackageClasses = {
    UserRepository.class,
    RoleRepository.class,
    DriverRepository.class,
    DeviceRegisterRepository.class,
    RefreshTokenRepository.class,
    PermissionRepository.class,
    PasswordResetTokenRepository.class
})
@Import({
    AuthController.class,
    AuthPasswordResetController.class,
    ReviewerAuthController.class,
    DeviceAuthMobileController.class,
    LocalizationConfig.class,
    PasswordEncoderConfig.class,
    LocalizedMessageService.class,
    JwtUtil.class,
    JwtAuthFilter.class,
    ApiKeyFilter.class,
    CustomUserDetailsService.class,
    DeviceRegistrationService.class,
    RefreshTokenService.class,
    UserPermissionService.class,
    PasswordResetService.class
})
public class AuthApiApplication {
  public static void main(String[] args) {
    SpringApplication.run(AuthApiApplication.class, args);
  }
}
