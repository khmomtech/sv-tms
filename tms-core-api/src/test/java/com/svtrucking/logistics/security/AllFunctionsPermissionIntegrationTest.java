package com.svtrucking.logistics.security;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.svtrucking.logistics.enums.RoleType;
import com.svtrucking.logistics.model.Permission;
import com.svtrucking.logistics.model.Role;
import com.svtrucking.logistics.model.User;
import com.svtrucking.logistics.repository.PermissionRepository;
import com.svtrucking.logistics.repository.RefreshTokenRepository;
import com.svtrucking.logistics.repository.RoleRepository;
import com.svtrucking.logistics.repository.UserRepository;
import com.svtrucking.logistics.repository.EmployeeRepository;
import jakarta.persistence.EntityManager;
import jakarta.persistence.PersistenceContext;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.context.annotation.Import;
import org.springframework.http.MediaType;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.transaction.annotation.Transactional;

import com.svtrucking.logistics.config.TestRedisConfig;

import java.util.HashSet;

import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

/**
 * Integration test to verify that users with 'all_functions' permission
 * can access ALL endpoints across the entire system.
 * 
 * This test ensures SUPERADMIN has universal access regardless of specific permissions.
 */
@SpringBootTest
@AutoConfigureMockMvc
@ActiveProfiles("test")
@Import(TestRedisConfig.class)
@Transactional
public class AllFunctionsPermissionIntegrationTest {

  @Autowired private MockMvc mvc;
  @Autowired private ObjectMapper mapper;
  @Autowired private UserRepository userRepository;
  @Autowired private RoleRepository roleRepository;
  @Autowired private PermissionRepository permissionRepository;
  @Autowired private RefreshTokenRepository refreshTokenRepository;
  @Autowired private EmployeeRepository employeeRepository;
  @Autowired private PasswordEncoder passwordEncoder;
  @PersistenceContext private EntityManager entityManager;

  private String superadminToken;
  private String regularAdminToken;

  @BeforeEach
  public void setup() throws Exception {
    // Start from a clean slate to avoid unique constraint issues from import.sql + runners
    // Note: user_permissions table was dropped by migration V29; skip its deletion
    // safeDelete("user_permissions");
    safeDelete("role_permissions");
    safeDelete("user_roles");
    refreshTokenRepository.deleteAll();
    employeeRepository.deleteAll();
    userRepository.deleteAll();
    roleRepository.deleteAll();
    permissionRepository.deleteAll();

    // Ensure all_functions permission exists
    Permission allFunctions = permissionRepository.findByName("all_functions")
        .orElseGet(() -> {
          Permission p = new Permission();
          p.setName("all_functions");
          p.setActionType("*");
          p.setResourceType("Global");
          p.setDescription("Wildcard permission for superadmin");
          return permissionRepository.save(p);
        });

    // Create SUPERADMIN role with all_functions
    Role superadminRole = roleRepository.findByName(RoleType.SUPERADMIN)
        .orElseGet(() -> {
          Role r = new Role();
          r.setName(RoleType.SUPERADMIN);
          r.setDescription("Super Administrator");
          r.setPermissions(new HashSet<>());
          return roleRepository.save(r);
        });
    
    if (!superadminRole.getPermissions().contains(allFunctions)) {
      superadminRole.getPermissions().add(allFunctions);
      roleRepository.save(superadminRole);
    }

    // Create ADMIN role WITHOUT all_functions (for comparison)
    Role adminRole = roleRepository.findByName(RoleType.ADMIN)
        .orElseGet(() -> {
          Role r = new Role();
          r.setName(RoleType.ADMIN);
          r.setDescription("Administrator");
          r.setPermissions(new HashSet<>());
          return roleRepository.save(r);
        });

    // Create SUPERADMIN user
    User superadmin = userRepository.findByUsername("test-superadmin")
        .orElseGet(() -> {
          User u = new User();
          u.setUsername("test-superadmin");
          u.setEmail("test-superadmin@test.com");
          u.setPassword(passwordEncoder.encode("test-pass"));
          u.setRoles(new HashSet<>());
          return u;
        });
    superadmin.getRoles().clear();
    superadmin.getRoles().add(superadminRole);
    userRepository.save(superadmin);

    // Create regular ADMIN user (without all_functions)
    User admin = userRepository.findByUsername("test-admin")
        .orElseGet(() -> {
          User u = new User();
          u.setUsername("test-admin");
          u.setEmail("test-admin@test.com");
          u.setPassword(passwordEncoder.encode("test-pass"));
          u.setRoles(new HashSet<>());
          return u;
        });
    admin.getRoles().clear();
    admin.getRoles().add(adminRole);
    userRepository.save(admin);

    // Login as SUPERADMIN
    superadminToken = login("test-superadmin", "test-pass");
    
    // Login as regular ADMIN
    regularAdminToken = login("test-admin", "test-pass");
  }

  private void safeDelete(String table) {
    try {
      entityManager.createNativeQuery("DELETE FROM " + table).executeUpdate();
    } catch (Exception ignored) {
      // Table may not exist in the current schema
    }
  }

  private String login(String username, String password) throws Exception {
    String loginJson = String.format("{\"username\":\"%s\",\"password\":\"%s\"}", username, password);
    String response = mvc.perform(post("/api/auth/login")
            .contentType(MediaType.APPLICATION_JSON)
            .content(loginJson))
        .andExpect(status().isOk())
        .andReturn().getResponse().getContentAsString();

    JsonNode root = mapper.readTree(response);
    return root.path("data").path("token").asText();
  }

  // ==================== DEVICE MANAGEMENT TESTS ====================

  @Test
  public void superadmin_canAccessAllDevices() throws Exception {
    mvc.perform(get("/api/driver/device/all")
            .header("Authorization", "Bearer " + superadminToken))
        .andExpect(status().isOk())
        .andExpect(jsonPath("$.success").value(true));
  }

  @Test
  public void superadmin_canAccessDeviceById() throws Exception {
    // Even if device doesn't exist, should get proper error (not 403)
    mvc.perform(get("/api/driver/device/999")
            .header("Authorization", "Bearer " + superadminToken))
        .andExpect(status().isNotFound()); // Not forbidden!
  }

  @Test
  public void superadmin_canFilterDevices() throws Exception {
    mvc.perform(get("/api/driver/device/filter")
            .param("status", "APPROVED")
            .header("Authorization", "Bearer " + superadminToken))
        .andExpect(status().isOk());
  }

  @Test
  public void superadmin_canApproveDevice() throws Exception {
    // Even if device doesn't exist, should get proper error (not 403)
    mvc.perform(put("/api/driver/device/approve/999")
            .header("Authorization", "Bearer " + superadminToken))
        .andExpect(status().isNotFound()); // Not forbidden!
  }

  @Test
  public void superadmin_canBlockDevice() throws Exception {
    mvc.perform(put("/api/driver/device/block/999")
            .header("Authorization", "Bearer " + superadminToken))
        .andExpect(status().isNotFound()); // Not forbidden!
  }

  @Test
  public void superadmin_canDeleteDevice() throws Exception {
    mvc.perform(delete("/api/driver/device/999")
            .header("Authorization", "Bearer " + superadminToken))
        .andExpect(status().isNotFound()); // Not forbidden!
  }

  // ==================== USER MANAGEMENT TESTS ====================

  @Test
  public void superadmin_canAccessUsers() throws Exception {
    mvc.perform(get("/api/users")
            .header("Authorization", "Bearer " + superadminToken))
        .andExpect(status().isOk());
  }

  @Test
  public void superadmin_canCreateUser() throws Exception {
    String userJson = """
        {
          "username": "new-test-user",
          "email": "new-test@test.com",
          "password": "test123",
          "roles": ["USER"]
        }
        """;
    
    mvc.perform(post("/api/users")
            .header("Authorization", "Bearer " + superadminToken)
            .contentType(MediaType.APPLICATION_JSON)
            .content(userJson))
        .andExpect(status().isOk());
  }

  // ==================== DRIVER MANAGEMENT TESTS ====================

  @Test
  public void superadmin_canAccessDrivers() throws Exception {
    mvc.perform(get("/api/drivers")
            .header("Authorization", "Bearer " + superadminToken))
        .andExpect(status().isOk());
  }

  @Test
  public void superadmin_canAccessDriverById() throws Exception {
    mvc.perform(get("/api/drivers/999")
            .header("Authorization", "Bearer " + superadminToken))
        .andExpect(status().isNotFound()); // Not forbidden!
  }

  // ==================== VEHICLE MANAGEMENT TESTS ====================

  @Test
  public void superadmin_canAccessVehicles() throws Exception {
    mvc.perform(get("/api/vehicles")
            .header("Authorization", "Bearer " + superadminToken))
        .andExpect(status().isOk());
  }

  // ==================== DISPATCH MANAGEMENT TESTS ====================

  @Test
  public void superadmin_canAccessDispatches() throws Exception {
    mvc.perform(get("/api/admin/dispatches")
            .header("Authorization", "Bearer " + superadminToken))
        .andExpect(status().isOk());
  }

  // ==================== ROLE & PERMISSION MANAGEMENT TESTS ====================

  @Test
  public void superadmin_canAccessRoles() throws Exception {
    mvc.perform(get("/api/roles")
            .header("Authorization", "Bearer " + superadminToken))
        .andExpect(status().isOk());
  }

  @Test
  public void superadmin_canAccessPermissions() throws Exception {
    mvc.perform(get("/api/permissions")
            .header("Authorization", "Bearer " + superadminToken))
        .andExpect(status().isOk());
  }

  // ==================== COMPARISON TESTS (SUPERADMIN vs ADMIN) ====================

  @Test
  public void superadmin_hasAllFunctionsInLoginResponse() throws Exception {
    String loginJson = "{\"username\":\"test-superadmin\",\"password\":\"test-pass\"}";
    String response = mvc.perform(post("/api/auth/login")
            .contentType(MediaType.APPLICATION_JSON)
            .content(loginJson))
        .andExpect(status().isOk())
        .andReturn().getResponse().getContentAsString();

    JsonNode root = mapper.readTree(response);
    JsonNode permissions = root.path("data").path("user").path("permissions");
    
    // Verify all_functions is in the permissions list
    boolean hasAllFunctions = false;
    for (JsonNode perm : permissions) {
      if ("all_functions".equals(perm.asText())) {
        hasAllFunctions = true;
        break;
      }
    }
    
    assert hasAllFunctions : "SUPERADMIN should have 'all_functions' permission";
  }

  @Test
  public void regularAdmin_doesNotHaveAllFunctions() throws Exception {
    String loginJson = "{\"username\":\"test-admin\",\"password\":\"test-pass\"}";
    String response = mvc.perform(post("/api/auth/login")
            .contentType(MediaType.APPLICATION_JSON)
            .content(loginJson))
        .andExpect(status().isOk())
        .andReturn().getResponse().getContentAsString();

    JsonNode root = mapper.readTree(response);
    JsonNode permissions = root.path("data").path("user").path("permissions");
    
    // Verify all_functions is NOT in the permissions list
    boolean hasAllFunctions = false;
    for (JsonNode perm : permissions) {
      if ("all_functions".equals(perm.asText())) {
        hasAllFunctions = true;
        break;
      }
    }
    
    assert !hasAllFunctions : "Regular ADMIN should NOT have 'all_functions' permission";
  }

  // ==================== AUTHORIZATION SERVICE TESTS ====================

  @Test
  public void authorizationService_grantsAccessWithAllFunctions() throws Exception {
    // This endpoint uses @PreAuthorize("@authorizationService.hasPermission('...')")
    // SUPERADMIN with all_functions should bypass specific permission checks
    
    mvc.perform(get("/api/driver/device/all")
            .header("Authorization", "Bearer " + superadminToken))
        .andExpect(status().isOk())
        .andExpect(jsonPath("$.success").value(true));
  }

  @Test
  public void regularAdmin_mayNotAccessRestrictedEndpoints() throws Exception {
    // Regular ADMIN without specific permissions should get 403
    // (This tests that all_functions is actually doing something special)
    
    mvc.perform(get("/api/driver/device/all")
            .header("Authorization", "Bearer " + regularAdminToken))
        .andExpect(status().isForbidden()); // Should be forbidden without all_functions
  }

  // ==================== SYSTEM ENDPOINTS TESTS ====================

  @Test
  public void superadmin_canAccessSystemEndpoints() throws Exception {
    // Test endpoints that explicitly require all_functions
    mvc.perform(get("/api/system/health")
            .header("Authorization", "Bearer " + superadminToken))
        .andExpect(status().isOk());
  }

  // ==================== COMPREHENSIVE PERMISSION MATRIX TEST ====================

  @Test
  public void superadmin_hasAccessToAllEndpointCategories() throws Exception {
    // This test ensures SUPERADMIN can access at least one endpoint from each major category
    
    String[][] endpointCategories = {
        {"Devices", "/api/driver/device/all"},
        {"Users", "/api/users"},
        {"Drivers", "/api/drivers"},
        {"Vehicles", "/api/vehicles"},
        {"Dispatches", "/api/admin/dispatches"},
        {"Roles", "/api/roles"},
        {"Permissions", "/api/permissions"}
    };

    for (String[] category : endpointCategories) {
      String categoryName = category[0];
      String endpoint = category[1];
      
      mvc.perform(get(endpoint)
              .header("Authorization", "Bearer " + superadminToken))
          .andExpect(status().isOk())
          .andExpect(jsonPath("$.success").value(true));
      
      System.out.println("SUPERADMIN has access to " + categoryName + ": " + endpoint);
    }
  }
}
