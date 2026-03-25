package com.svtrucking.logistics.controller;

import com.svtrucking.logistics.dto.requests.ForgotPasswordRequest;
import com.svtrucking.logistics.dto.requests.ResetPasswordRequest;
import com.svtrucking.logistics.service.PasswordResetService;
import com.svtrucking.logistics.repository.UserRepository;
import org.springframework.http.ResponseEntity;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RestController;

@RestController
public class AuthPasswordResetController {

  private final PasswordResetService passwordResetService;
  private final UserRepository userRepository;
  private final PasswordEncoder passwordEncoder;

  public AuthPasswordResetController(PasswordResetService passwordResetService, UserRepository userRepository, PasswordEncoder passwordEncoder) {
    this.passwordResetService = passwordResetService;
    this.userRepository = userRepository;
    this.passwordEncoder = passwordEncoder;
  }

  @PostMapping("/api/auth/forgot-password")
  public ResponseEntity<?> forgotPassword(@RequestBody ForgotPasswordRequest req) {
    passwordResetService.createAndSendToken(req.getEmail());
    return ResponseEntity.ok(java.util.Map.of("message", "If the email exists we will send reset instructions"));
  }

  @PostMapping("/api/auth/reset-password")
  public ResponseEntity<?> resetPassword(@RequestBody ResetPasswordRequest req) {
    boolean ok = passwordResetService.resetPassword(req.getToken(), req.getNewPassword(), passwordEncoder, userId -> {
      var opt = userRepository.findById(userId);
      if (opt.isPresent()) {
        var u = opt.get();
        u.setPassword(passwordEncoder.encode(req.getNewPassword()));
        userRepository.save(u);
      }
    });
    if (ok) return ResponseEntity.ok(java.util.Map.of("message", "Password updated"));
    return ResponseEntity.badRequest().body(java.util.Map.of("error", "Invalid or expired token"));
  }
}
