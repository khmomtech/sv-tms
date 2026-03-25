package com.svtrucking.logistics.service;

import com.svtrucking.logistics.model.RefreshToken;
import com.svtrucking.logistics.repository.RefreshTokenRepository;
import java.time.LocalDateTime;
import java.time.ZoneId;
import java.util.Optional;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.transaction.annotation.Propagation;

@Service
public class RefreshTokenService {

  private final RefreshTokenRepository repository;

  public RefreshTokenService(RefreshTokenRepository repository) {
    this.repository = repository;
  }

  @Transactional(propagation = Propagation.REQUIRES_NEW)
  public RefreshToken create(String token, Long userId, java.util.Date issuedAt, java.util.Date expiresAt, String deviceInfo) {
    // If a token already exists, return it immediately to avoid duplicate inserts.
    repository.findByToken(token).ifPresent(existing -> {
      // return via exception flow by throwing an unchecked signal (handled below)
      throw new TokenAlreadyExistsSignal(existing);
    });

    RefreshToken rt = new RefreshToken();
    rt.setToken(token);
    rt.setUserId(userId);
    if (issuedAt != null) {
      rt.setIssuedAt(issuedAt.toInstant().atZone(ZoneId.systemDefault()).toLocalDateTime());
    } else {
      rt.setIssuedAt(LocalDateTime.now());
    }
    if (expiresAt != null) {
      rt.setExpiresAt(expiresAt.toInstant().atZone(ZoneId.systemDefault()).toLocalDateTime());
    }
    rt.setRevoked(false);
    rt.setDeviceInfo(deviceInfo);
    try {
      return repository.save(rt);
    } catch (RuntimeException ex) {
      // On any persistence collision or session problem, try to return the existing token.
      return repository.findByToken(token).orElseThrow(() -> {
        if (ex instanceof TokenAlreadyExistsSignal) {
          return ((TokenAlreadyExistsSignal) ex).getOriginalException();
        }
        return ex;
      });
    }
  }

  // Internal unchecked signal to short-circuit when token already exists in repo
  private static class TokenAlreadyExistsSignal extends RuntimeException {
    private final RefreshToken existing;
    public TokenAlreadyExistsSignal(RefreshToken existing) {
      super("token-exists");
      this.existing = existing;
    }
    public RefreshToken getExisting() { return existing; }
    public RuntimeException getOriginalException() { return this; }
  }

  public Optional<RefreshToken> findByToken(String token) {
    return repository.findByToken(token);
  }

  @Transactional
  public void revoke(RefreshToken token) {
    token.setRevoked(true);
    repository.save(token);
  }

  @Transactional
  public void revokeAllForUser(Long userId) {
    repository.findAll().stream()
        .filter(t -> t.getUserId() != null && t.getUserId().equals(userId))
        .forEach(t -> {
          t.setRevoked(true);
          repository.save(t);
        });
  }

  public boolean isValid(RefreshToken t) {
    if (t == null) return false;
    if (Boolean.TRUE.equals(t.getRevoked())) return false;
    if (t.getExpiresAt() == null) return false;
    return t.getExpiresAt().isAfter(LocalDateTime.now());
  }

  public java.util.Optional<RefreshToken> findById(Long id) {
    return repository.findById(id);
  }

  public java.util.List<RefreshToken> findByUserId(Long userId) {
    return repository.findByUserId(userId);
  }

  @Transactional
  public void revokeById(Long id) {
    repository.findById(id).ifPresent(t -> {
      t.setRevoked(true);
      repository.save(t);
    });
  }
}
