package com.svtrucking.logistics.security;

import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;

public class SecurityUtils {

  public static String getCurrentUserLogin() {
    Authentication authentication = SecurityContextHolder.getContext().getAuthentication();
    if (authentication != null
        && authentication.getPrincipal()
            instanceof org.springframework.security.core.userdetails.User) {
      return ((org.springframework.security.core.userdetails.User) authentication.getPrincipal())
          .getUsername();
    }
    return null;
  }
}
