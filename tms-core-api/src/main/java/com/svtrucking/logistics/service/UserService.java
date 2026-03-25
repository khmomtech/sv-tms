package com.svtrucking.logistics.service;

import com.svtrucking.logistics.enums.RoleType;
import com.svtrucking.logistics.model.Role;
import com.svtrucking.logistics.model.User;
import com.svtrucking.logistics.dto.UserDto;
import com.svtrucking.logistics.repository.RoleRepository;
import com.svtrucking.logistics.repository.UserRepository;
import java.util.HashSet;
import java.util.List;
import java.util.Optional;
import java.util.Set;
import org.springframework.cache.annotation.CacheEvict;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
public class UserService {

  private final UserRepository userRepository;
  private final RoleRepository roleRepository;
  private final PasswordEncoder passwordEncoder;

  public UserService(
      UserRepository userRepository,
      RoleRepository roleRepository,
      PasswordEncoder passwordEncoder) {
    this.userRepository = userRepository;
    this.roleRepository = roleRepository;
    this.passwordEncoder = passwordEncoder;
  }

  /** Get all users */
  @Transactional(readOnly = true)
  public List<User> getAllUsers() {
    return userRepository.findAllWithRoles();
  }

  /**
   * Get all users mapped to DTOs with roles initialized inside the transaction
   */
  @Transactional(readOnly = true)
  public List<UserDto> getAllUserDtos() {
    return userRepository.findAllWithRoles().stream().map(UserDto::fromEntity).toList();
  }

  /** Create a new user */
  @Transactional
  public User createUser(String username, String password, String email, Set<RoleType> roleTypes) {
    if (userRepository.existsByUsername(username)) {
      throw new RuntimeException("Username already exists: " + username);
    }

    Set<Role> roles = new HashSet<>();
    for (RoleType roleType : roleTypes) {
      Role role = roleRepository
          .findByName(roleType)
          .orElseThrow(() -> new RuntimeException("Role not found: " + roleType));
      roles.add(role);
    }

    User user = new User();
    user.setUsername(username);
    user.setPassword(passwordEncoder.encode(password));
    user.setEmail(email);
    user.setRoles(roles);
    user.setEnabled(true);
    user.setAccountNonExpired(true);
    user.setAccountNonLocked(true);
    user.setCredentialsNonExpired(true);

    return userRepository.save(user);
  }

  /** Get user by ID */
  public Optional<User> getUserById(Long id) {
    return userRepository.findById(id);
  }

  /** Update user details */
  @Transactional
  @CacheEvict(value = "userDetails", key = "#username")
  public User updateUser(Long id, String username, String email, Set<RoleType> roleTypes) {
    User user = userRepository
        .findById(id)
        .orElseThrow(() -> new RuntimeException("User not found with ID: " + id));

    if (username != null && !username.isEmpty()) {
      user.setUsername(username);
    }

    if (email != null && !email.isEmpty()) {
      user.setEmail(email);
    }

    if (roleTypes != null && !roleTypes.isEmpty()) {
      Set<Role> roles = new HashSet<>();
      for (RoleType roleType : roleTypes) {
        Role role = roleRepository
            .findByName(roleType)
            .orElseThrow(() -> new RuntimeException("Role not found: " + roleType));
        roles.add(role);
      }
      user.setRoles(roles);
    }

    return userRepository.save(user);
  }

  /** Change user password */
  @Transactional
  @CacheEvict(value = "userDetails", allEntries = true)
  public void changePassword(Long id, String newPassword) {
    User user = userRepository
        .findById(id)
        .orElseThrow(() -> new RuntimeException("User not found with ID: " + id));

    user.setPassword(passwordEncoder.encode(newPassword));
    userRepository.save(user);
  }

  /** Delete user by ID */
  @Transactional
  @CacheEvict(value = "userDetails", allEntries = true)
  public void deleteUser(Long id) {
    if (!userRepository.existsById(id)) {
      throw new RuntimeException("User not found with ID: " + id);
    }
    userRepository.deleteById(id);
  }
}
