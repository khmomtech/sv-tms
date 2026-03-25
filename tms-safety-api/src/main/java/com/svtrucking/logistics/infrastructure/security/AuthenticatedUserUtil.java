package com.svtrucking.logistics.infrastructure.security;

import com.svtrucking.logistics.identity.domain.DriverProfile;
import com.svtrucking.logistics.identity.domain.User;
import com.svtrucking.logistics.identity.repository.DriverProfileRepository;
import com.svtrucking.logistics.identity.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.stereotype.Component;

@Component
@RequiredArgsConstructor
public class AuthenticatedUserUtil {

  private final UserRepository userRepository;
  private final DriverProfileRepository driverRepository;

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

    DriverProfile driver =
        driverRepository
            .findByUserId(user.getId())
            .orElseThrow(
                () -> new RuntimeException("Authenticated user is not assigned to a driver"));

    return driver.getId();
  }
}
