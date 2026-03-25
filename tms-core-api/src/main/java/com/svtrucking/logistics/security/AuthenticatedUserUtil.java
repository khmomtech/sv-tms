package com.svtrucking.logistics.security;

import com.svtrucking.logistics.model.Driver;
import com.svtrucking.logistics.model.User;
import com.svtrucking.logistics.repository.CustomerRepository;
import com.svtrucking.logistics.repository.DriverRepository;
import com.svtrucking.logistics.repository.UserRepository;
import com.svtrucking.logistics.repository.UserSettingRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.stereotype.Component;

@Component
@RequiredArgsConstructor
public class AuthenticatedUserUtil {

  private final UserRepository userRepository;

  @Autowired private DriverRepository driverRepository;
  @Autowired private UserSettingRepository userSettingRepository;
  @Autowired private CustomerRepository customerRepository;

  public User getCurrentUser() {
    Authentication authentication = SecurityContextHolder.getContext().getAuthentication();
    if (authentication == null || !authentication.isAuthenticated()) {
      throw new RuntimeException("No authenticated user found");
    }

    String username = authentication.getName();
    return userRepository
        .findByUsernameWithRoles(username)
        .or(() -> userRepository.findByUsername(username))
        .orElseThrow(() -> new RuntimeException("User not found for username: " + username));
  }

  public Long getCurrentUserId() {
    return getCurrentUser().getId();
  }

  public Long getCurrentDriverId() {
    User user = getCurrentUser();

    Driver driver =
        driverRepository
            .findByUserId(user.getId())
            .orElseThrow(
                () -> new RuntimeException("Authenticated user is not assigned to a driver"));

    return driver.getId();
  }

  /**
   * Try to resolve the current authenticated user's linked customer id.
   *
   * Implementation notes:
   * - Non-invasive: this looks for a UserSetting with key `customer_id` (or `customerId`) and
   *   validates it refers to an existing Customer. This avoids immediate schema migrations.
   * - Fallbacks: if not present, it will try to interpret the authenticated username as a
   *   customer code (not ideal, but useful for quick installs where username==customerCode).
   *
   * Returns an Optional<long> if found and valid, otherwise empty.
   */
  public java.util.Optional<Long> getCurrentCustomerId() {
    User user = getCurrentUser();

    // 1) Check user_settings table for an explicit mapping (key: customer_id or customerId)
    try {
      var settingOpt = userSettingRepository.findByUserIdAndKey(user.getId(), "customer_id");
      if (settingOpt.isEmpty()) {
        settingOpt = userSettingRepository.findByUserIdAndKey(user.getId(), "customerId");
      }
      if (settingOpt.isPresent()) {
        String val = settingOpt.get().getValue();
        if (val != null && !val.isBlank()) {
          try {
            Long cid = Long.parseLong(val.trim());
            if (customerRepository.findById(cid).isPresent()) return java.util.Optional.of(cid);
          } catch (NumberFormatException ignored) {
            // ignore and continue
          }
        }
      }
    } catch (Exception ignored) {
      // If user settings table is not present or other issue, fall through to other heuristics
    }

    // 2) Heuristic: try matching username -> customerCode
    try {
      var custOpt = customerRepository.findByCustomerCode(user.getUsername());
      if (custOpt.isPresent()) return java.util.Optional.of(custOpt.get().getId());
    } catch (Exception ignored) {
      // no-op
    }

    return java.util.Optional.empty();
  }
}
