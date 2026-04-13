package com.svtrucking.logistics;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.svtrucking.logistics.config.TestRedisConfig;
import com.svtrucking.logistics.config.TestSecurityConfig;
import com.svtrucking.logistics.enums.DeviceStatus;
import com.svtrucking.logistics.enums.RoleType;
import com.svtrucking.logistics.model.DeviceRegister;
import com.svtrucking.logistics.model.Driver;
import com.svtrucking.logistics.model.Permission;
import com.svtrucking.logistics.model.Role;
import com.svtrucking.logistics.model.User;
import com.svtrucking.logistics.repository.DeviceRegisterRepository;
import com.svtrucking.logistics.repository.DriverRepository;
import com.svtrucking.logistics.repository.PermissionRepository;
import com.svtrucking.logistics.repository.RoleRepository;
import com.svtrucking.logistics.repository.UserRepository;
import java.time.LocalDateTime;
import java.util.HashSet;
import org.junit.jupiter.api.Assertions;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.context.annotation.Import;
import org.springframework.http.MediaType;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.context.TestPropertySource;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.transaction.annotation.Transactional;

import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@SpringBootTest
@AutoConfigureMockMvc
@ActiveProfiles("test")
@TestPropertySource(properties = {
    "app.driver.skip-device-check=false",
    "app.driver.login-bypass=false",
    "app.reviewer.bypass=false",
    "app.driver.require-approved-device-for-tracking=true"
})
@Import({TestRedisConfig.class, TestSecurityConfig.class})
public class AuthDeviceIntegrationTest {

  @Autowired private MockMvc mvc;
  @Autowired private ObjectMapper mapper;
  @Autowired private UserRepository userRepository;
  @Autowired private RoleRepository roleRepository;
  @Autowired private PermissionRepository permissionRepository;
  @Autowired private DriverRepository driverRepository;
  @Autowired private DeviceRegisterRepository deviceRegisterRepository;
  @Autowired private PasswordEncoder passwordEncoder;
  @Autowired private com.svtrucking.logistics.service.DeviceRegistrationService deviceRegistrationService;

  private User createDriverUser(String username, String password) {
    Role driverRole = roleRepository.findByName(RoleType.DRIVER).orElseGet(() -> {
      Role r = new Role();
      r.setName(RoleType.DRIVER);
      r.setDescription("Driver role");
      return roleRepository.save(r);
    });

    User u = new User();
    u.setUsername(username);
    u.setEmail(username + "@example.test");
    u.setPassword(passwordEncoder.encode(password));
    u.setEnabled(true);
    u.setAccountNonLocked(true);
    u.setAccountNonExpired(true);
    u.setCredentialsNonExpired(true);
    u.setRoles(new HashSet<>());
    u.getRoles().add(driverRole);
    return userRepository.save(u);
  }

  @Test
  @Transactional
  public void admin_with_allFunctions_can_access_device_all() throws Exception {
    // Ensure permission exists
    Permission all = permissionRepository.findByName("all_functions").orElseGet(() -> {
      Permission p = new Permission();
      p.setName("all_functions");
      p.setActionType("all");
      p.setResourceType("system");
      p.setDescription("Wildcard permission");
      return permissionRepository.save(p);
    });

    // Ensure role ADMIN exists and has the permission
    Role adminRole = roleRepository.findByName(RoleType.ADMIN).orElseGet(() -> {
      Role r = new Role();
      r.setName(RoleType.ADMIN);
      r.setDescription("Admin role");
      r.setPermissions(new HashSet<>());
      return roleRepository.save(r);
    });
    adminRole.getPermissions().add(all);
    roleRepository.save(adminRole);

    // Create a test user with ADMIN role
    User u = new User();
    u.setUsername("int-admin");
    u.setEmail("int-admin@example.test");
    u.setPassword(passwordEncoder.encode("int-pass"));
    u.setRoles(new HashSet<>());
    u.getRoles().add(adminRole);
    userRepository.save(u);

    // Create a driver and device
    Driver d = new Driver();
    d.setFirstName("Integration");
    d.setLastName("Driver");
    d.setLicenseNumber("INT-LIC-001");
    d.setPhone("+10000000002");
    d.setIsActive(true);
    d.setStatus(com.svtrucking.logistics.enums.DriverStatus.ONLINE);
    driverRepository.save(d);

    DeviceRegister device = DeviceRegister.builder()
        .driver(d)
        .deviceId("int-device-1")
        .deviceName("Integration Device")
        .status(DeviceStatus.APPROVED)
        .registeredAt(LocalDateTime.now())
        .build();
    deviceRegisterRepository.save(device);

    // Login as the user
    String loginJson = "{\"username\":\"int-admin\",\"password\":\"int-pass\"}";
    String loginResp = mvc.perform(post("/api/auth/login").contentType(MediaType.APPLICATION_JSON).content(loginJson))
        .andExpect(status().isOk())
        .andReturn().getResponse().getContentAsString();

    JsonNode root = mapper.readTree(loginResp);
    String token = root.path("data").path("token").asText(null);
    Assertions.assertNotNull(token, "Login must return a token");

    // Call protected endpoint with correct URL
    mvc.perform(get("/api/driver/device/all").header("Authorization", "Bearer " + token))
        .andExpect(status().isOk());
  }

  @Test
  @Transactional
  public void driver_login_autoApprovesFirstHeaderDevice() throws Exception {
    createDriverUser("driver-first-phone", "test-pass");

    mvc.perform(
            post("/api/auth/driver/login")
                .contentType(MediaType.APPLICATION_JSON)
                .header("X-Device-Id", "phone-a")
                .header("X-Device-Name", "Samsung A54")
                .header("X-Device-Os", "Android")
                .header("X-Device-Os-Version", "14")
                .header("X-App-Version", "1.0.0")
                .header("X-Device-Manufacturer", "Samsung")
                .header("X-Device-Model", "SM-A546E")
                .content("{\"username\":\"driver-first-phone\",\"password\":\"test-pass\"}"))
        .andExpect(status().isOk())
        .andExpect(jsonPath("$.data.code").value("LOGIN_SUCCESS"));

    Driver driver =
        driverRepository.findByUsername("driver-first-phone").orElseThrow();
    DeviceRegister device =
        deviceRegisterRepository.findByDriverIdAndDeviceId(driver.getId(), "phone-a").orElseThrow();

    Assertions.assertEquals(DeviceStatus.APPROVED, device.getStatus());
    Assertions.assertEquals("SYSTEM_AUTO_FIRST_DEVICE", device.getApprovedBy());
    Assertions.assertEquals("Samsung A54", device.getDeviceName());
    Assertions.assertEquals("Android", device.getOs());
    Assertions.assertEquals("1.0.0", device.getAppVersion());
  }

  @Test
  @Transactional
  public void debug_deviceRegistrationService_directResolve() {
    createDriverUser("driver-debug", "test-pass");

    Driver driver = new Driver();
    driver.setFirstName("Debug");
    driver.setLastName("Driver");
    driver.setPhone("+10000000010");
    driver.setIsActive(true);
    driver.setStatus(com.svtrucking.logistics.enums.DriverStatus.ONLINE);
    driver = driverRepository.save(driver);

    System.out.println("DEBUG service class: " + deviceRegistrationService.getClass().getName());
    try {
      System.out.println("DEBUG method declaring class: " + deviceRegistrationService.getClass()
          .getMethod("resolveLoginDeviceStatus", Long.class, String.class)
          .getDeclaringClass().getName());
      System.out.println("DEBUG service class location: " +
          deviceRegistrationService.getClass().getProtectionDomain().getCodeSource().getLocation());
      Object target = org.springframework.test.util.AopTestUtils.getTargetObject(deviceRegistrationService);
      System.out.println("DEBUG target class: " + target.getClass().getName());
      String directStatus = ((com.svtrucking.logistics.service.DeviceRegistrationService) target)
          .resolveLoginDeviceStatus(driver.getId(), "phone-a");
      System.out.println("DEBUG direct target status: " + directStatus);
    } catch (NoSuchMethodException e) {
      e.printStackTrace();
    }
    String status = deviceRegistrationService.resolveLoginDeviceStatus(driver.getId(), "phone-a");
    System.out.println("DEBUG direct status: " + status);
    Assertions.assertNotNull(status);
  }

  @Test
  @Transactional
  public void driver_login_rejectsSecondPhoneWhenAnotherApprovedPhoneExists() throws Exception {
    createDriverUser("driver-second-phone", "test-pass");

    mvc.perform(
            post("/api/auth/driver/login")
                .contentType(MediaType.APPLICATION_JSON)
                .header("X-Device-Id", "phone-a")
                .header("X-Device-Name", "Samsung A54")
                .header("X-Device-Os", "Android")
                .header("X-Device-Os-Version", "14")
                .header("X-App-Version", "1.0.0")
                .content("{\"username\":\"driver-second-phone\",\"password\":\"test-pass\"}"))
        .andExpect(status().isOk())
        .andExpect(jsonPath("$.data.code").value("LOGIN_SUCCESS"));

    mvc.perform(
            post("/api/auth/driver/login")
                .contentType(MediaType.APPLICATION_JSON)
                .header("X-Device-Id", "phone-b")
                .header("X-Device-Name", "iPhone 15")
                .header("X-Device-Os", "iOS")
                .header("X-Device-Os-Version", "18")
                .header("X-App-Version", "1.0.0")
                .content("{\"username\":\"driver-second-phone\",\"password\":\"test-pass\"}"))
        .andExpect(status().isForbidden())
        .andExpect(jsonPath("$.code").value("DEVICE_ACTIVE_ON_OTHER_PHONE"));
  }
}
