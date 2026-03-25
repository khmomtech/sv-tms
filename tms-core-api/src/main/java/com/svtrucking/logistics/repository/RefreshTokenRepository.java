package com.svtrucking.logistics.repository;

import com.svtrucking.logistics.model.RefreshToken;
import java.util.List;
import java.util.Optional;
import org.springframework.data.jpa.repository.JpaRepository;

public interface RefreshTokenRepository extends JpaRepository<RefreshToken, Long> {
  Optional<RefreshToken> findByToken(String token);

  List<RefreshToken> findByUserId(Long userId);

  // Delete expired tokens before the provided cutoff. Returns number deleted.
  int deleteByExpiresAtBefore(java.time.LocalDateTime cutoff);
}
