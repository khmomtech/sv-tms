package com.svtrucking.logistics.service;

import com.svtrucking.logistics.model.User;
import com.svtrucking.logistics.repository.UserRepository;
import io.jsonwebtoken.Claims;
import io.jsonwebtoken.Jws;
import io.jsonwebtoken.JwtException;
import io.jsonwebtoken.Jwts;
import io.jsonwebtoken.security.Keys;
import java.util.Date;
import java.util.Optional;
import javax.crypto.SecretKey;
import org.springframework.stereotype.Service;

@Service
public class SsoService {

  private final UserRepository userRepository;

  // Use the same secret key as in JwtUtil for consistency
  private static final String SECRET_KEY =
      "SuperSecureKeyForJWTAuthentication2024SuperSecureKeyForJWT";

  public SsoService(UserRepository userRepository) {
    this.userRepository = userRepository;
  }

  /** Validate an SSO token and return the associated user */
  public Optional<User> validateSsoToken(String token) {
    try {
      SecretKey key = Keys.hmacShaKeyFor(SECRET_KEY.getBytes());
      Jws<Claims> claims = Jwts.parserBuilder().setSigningKey(key).build().parseClaimsJws(token);

      String username = claims.getBody().getSubject();
      Date expiration = claims.getBody().getExpiration();

      // Check if token is expired
      if (expiration.before(new Date())) {
        return Optional.empty();
      }

      // Find user by username
      return userRepository.findByUsername(username);
    } catch (JwtException e) {
      // Invalid token
      return Optional.empty();
    }
  }

  /** Create an SSO token for a user */
  public String createSsoToken(User user) {
    SecretKey key = Keys.hmacShaKeyFor(SECRET_KEY.getBytes());

    // Set expiration to 24 hours
    Date expiration = new Date(System.currentTimeMillis() + 24 * 60 * 60 * 1000);

    return Jwts.builder()
        .setSubject(user.getUsername())
        .setIssuedAt(new Date())
        .setExpiration(expiration)
        .signWith(key)
        .compact();
  }

  /** Validate SSO token and authenticate user */
  public boolean authenticateWithSsoToken(String token) {
    Optional<User> userOpt = validateSsoToken(token);
    return userOpt.isPresent() && userOpt.get().isEnabled();
  }
}
