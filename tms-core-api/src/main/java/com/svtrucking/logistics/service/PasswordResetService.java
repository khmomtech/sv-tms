package com.svtrucking.logistics.service;

import com.svtrucking.logistics.model.PasswordResetToken;
import com.svtrucking.logistics.repository.PasswordResetTokenRepository;
import com.svtrucking.logistics.repository.UserRepository;
import java.time.Instant;
import java.time.temporal.ChronoUnit;
import java.util.Optional;
import java.util.UUID;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
public class PasswordResetService {
  private final PasswordResetTokenRepository tokenRepo;
  private final UserRepository userRepository;
  private final Logger log = LoggerFactory.getLogger(PasswordResetService.class);

  public PasswordResetService(PasswordResetTokenRepository tokenRepo, UserRepository userRepository) {
    this.tokenRepo = tokenRepo;
    this.userRepository = userRepository;
  }

  @Transactional
  public void createAndSendToken(String email) {
    var userOpt = userRepository.findByEmail(email);
    if (userOpt.isEmpty()) {
      // Avoid user enumeration: return silently
      log.info("Password reset requested for non-existing email: {}", email);
      return;
    }

    var user = userOpt.get();
    var token = new PasswordResetToken();
    token.setUserId(user.getId());
    token.setToken(UUID.randomUUID().toString());
    token.setExpiresAt(Instant.now().plus(1, ChronoUnit.HOURS));
    tokenRepo.save(token);

    // TODO: integrate with email service. For now, assume email sent.
    // Security: Never log password reset tokens - they can be used to hijack accounts
    log.info("Password reset requested for user: {}", user.getUsername());
  }

  @Transactional
  public boolean resetPassword(String tokenStr, String newPassword, org.springframework.security.crypto.password.PasswordEncoder encoder, java.util.function.Consumer<Long> passwordUpdater) {
    Optional<PasswordResetToken> opt = tokenRepo.findByToken(tokenStr);
    if (opt.isEmpty()) return false;
    var token = opt.get();
    if (token.getExpiresAt().isBefore(Instant.now())) {
      tokenRepo.delete(token);
      return false;
    }

    // Update password via provided callback (keeps this service decoupled)
    passwordUpdater.accept(token.getUserId());
    tokenRepo.delete(token);
    return true;
  }
}
