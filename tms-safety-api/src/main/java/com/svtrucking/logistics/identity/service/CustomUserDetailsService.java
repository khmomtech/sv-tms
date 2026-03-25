package com.svtrucking.logistics.identity.service;

import com.svtrucking.logistics.identity.domain.User;
import com.svtrucking.logistics.identity.repository.UserRepository;
import java.util.List;
import java.util.stream.Collectors;
import org.springframework.security.core.authority.SimpleGrantedAuthority;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.security.core.userdetails.UserDetailsService;
import org.springframework.security.core.userdetails.UsernameNotFoundException;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
public class CustomUserDetailsService implements UserDetailsService {

  private final UserRepository userRepository;

  public CustomUserDetailsService(UserRepository userRepository) {
    this.userRepository = userRepository;
  }

  @Override
  @Transactional //  Ensures database consistency
  public UserDetails loadUserByUsername(String username) throws UsernameNotFoundException {
    User user =
        userRepository
            .findByUsernameWithRoles(username)
            .orElseThrow(() -> new UsernameNotFoundException("User not found: " + username));

    //  Map roles to Spring Security authorities
    List<SimpleGrantedAuthority> authorities =
        user.getRoles().stream()
            .map(
                role ->
                    new SimpleGrantedAuthority(
                        "ROLE_" + role.getName().name())) // Ensure enum handling
            .collect(Collectors.toList());
    
    // Add permissions from roles to authorities
    user.getRoles().forEach(role -> {
      role.getPermissions().forEach(permission -> {
        authorities.add(new SimpleGrantedAuthority(permission.getName()));
      });
    });

    //  Handle account states (locked, expired, disabled)
    return org.springframework.security.core.userdetails.User.withUsername(user.getUsername())
        .password(user.getPassword()) // Password must be encoded with BCrypt
        .authorities(authorities)
        .accountLocked(!user.isAccountNonLocked()) // Lock status
        .disabled(!user.isEnabled()) // Disabled status
        .credentialsExpired(!user.isCredentialsNonExpired()) // Expired credentials
        .accountExpired(!user.isAccountNonExpired()) // Expired account
        .build();
  }
}
