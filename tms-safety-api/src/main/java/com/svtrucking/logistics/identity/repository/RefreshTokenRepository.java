package com.svtrucking.logistics.identity.repository;

import com.svtrucking.logistics.identity.domain.RefreshToken;
import java.util.List;
import java.util.Optional;
import org.springframework.data.jpa.repository.JpaRepository;

public interface RefreshTokenRepository extends JpaRepository<RefreshToken, Long> {
  Optional<RefreshToken> findByToken(String token);

  List<RefreshToken> findByUserId(Long userId);

  int deleteByExpiresAtBefore(java.time.LocalDateTime cutoff);
}

