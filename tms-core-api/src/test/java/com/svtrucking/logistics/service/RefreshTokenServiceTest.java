package com.svtrucking.logistics.service;

import static org.mockito.Mockito.*;

import com.svtrucking.logistics.model.RefreshToken;
import com.svtrucking.logistics.repository.RefreshTokenRepository;
import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.mockito.ArgumentCaptor;

class RefreshTokenServiceTest {

  RefreshTokenRepository repo;
  RefreshTokenService svc;

  @BeforeEach
  void setUp() {
    repo = mock(RefreshTokenRepository.class);
    svc = new RefreshTokenService(repo);
  }

  @Test
  void createAndFindByToken() {
    String token = "rt-abc";
    RefreshToken saved = new RefreshToken(1L, token, 42L, LocalDateTime.now(), LocalDateTime.now().plusDays(1), false, "device-x");
    when(repo.save(any())).thenReturn(saved);

    var created = svc.create(token, 42L, new java.util.Date(), new java.util.Date(System.currentTimeMillis() + 3600_000), "device-x");
    // repo.save called
    verify(repo, times(1)).save(any());

    when(repo.findByToken(token)).thenReturn(Optional.of(saved));
    var rtOpt = svc.findByToken(token);
    assert rtOpt.isPresent();
    assert rtOpt.get().getToken().equals(token);
  }

  @Test
  void revokeAndValidate() {
    RefreshToken t1 = new RefreshToken(1L, "t1", 1L, LocalDateTime.now().minusDays(2), LocalDateTime.now().minusDays(1), false, null);
    RefreshToken t2 = new RefreshToken(2L, "t2", 1L, LocalDateTime.now(), LocalDateTime.now().plusDays(1), false, null);
    when(repo.findAll()).thenReturn(List.of(t1, t2));

    svc.revokeAllForUser(1L);

    ArgumentCaptor<RefreshToken> cap = ArgumentCaptor.forClass(RefreshToken.class);
    verify(repo, atLeastOnce()).save(cap.capture());
    // ensure at least one revoked
    boolean anyRevoked = cap.getAllValues().stream().anyMatch(RefreshToken::getRevoked);
    assert anyRevoked;
  }
}
