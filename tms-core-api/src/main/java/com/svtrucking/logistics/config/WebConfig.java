package com.svtrucking.logistics.config;

import com.svtrucking.logistics.interceptor.AuditTrailInterceptor;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Configuration;
import org.springframework.web.servlet.config.annotation.InterceptorRegistry;
import org.springframework.web.servlet.config.annotation.ResourceHandlerRegistry;
import org.springframework.web.servlet.config.annotation.WebMvcConfigurer;

@Configuration
public class WebConfig implements WebMvcConfigurer {

  private final AuditTrailInterceptor auditTrailInterceptor;

  // Read upload path from application.properties
  @Value("${file.upload.base-dir:uploads/}")
  private String uploadBaseDir;

  public WebConfig(AuditTrailInterceptor auditTrailInterceptor) {
    this.auditTrailInterceptor = auditTrailInterceptor;
  }

  @Override
  public void addInterceptors(InterceptorRegistry registry) {
    registry
        .addInterceptor(auditTrailInterceptor)
        .addPathPatterns("/api/**")
        .excludePathPatterns("/api/auth/**", "/api/public/**", "/api/device/request-approval", "/api/device/register");
  }

  @Override
  public void addResourceHandlers(ResourceHandlerRegistry registry) {
    String location = "file:" + (uploadBaseDir.endsWith("/") ? uploadBaseDir : uploadBaseDir + "/");
    registry.addResourceHandler("/uploads/**").addResourceLocations(location);
  }
}
