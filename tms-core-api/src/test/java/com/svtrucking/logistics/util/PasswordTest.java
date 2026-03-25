package com.svtrucking.logistics.util;

import org.junit.jupiter.api.Test;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import static org.junit.jupiter.api.Assertions.assertTrue;

public class PasswordTest {
    @Test
    void testPasswordMatching() {
        BCryptPasswordEncoder encoder = new BCryptPasswordEncoder();
        String hash = "$2a$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi";
        
        System.out.println("Testing 'password': " + encoder.matches("password", hash));
        System.out.println("Testing 'super123': " + encoder.matches("super123", hash));
        
        // Generate a new hash for super123
        String newHash = encoder.encode("super123");
        System.out.println("New hash for 'super123': " + newHash);
        System.out.println("Verify new hash: " + encoder.matches("super123", newHash));
        
        assertTrue(encoder.matches("password", hash));
    }
}
