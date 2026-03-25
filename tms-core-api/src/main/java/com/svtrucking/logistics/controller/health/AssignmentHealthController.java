package com.svtrucking.logistics.controller.health;

import com.svtrucking.logistics.repository.VehicleDriverRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.HashMap;
import java.util.Map;

@RestController
@RequestMapping("/api/health/assignments")
@RequiredArgsConstructor
public class AssignmentHealthController {

    private final VehicleDriverRepository assignmentRepository;

    @GetMapping
    public ResponseEntity<Map<String, Object>> getAssignmentHealth() {
        Map<String, Object> health = new HashMap<>();
        
        try {
            long activeCount = assignmentRepository.countByRevokedAtIsNull();
            health.put("status", "UP");
            health.put("activeAssignments", activeCount);
            health.put("timestamp", System.currentTimeMillis());
            
            return ResponseEntity.ok(health);
        } catch (Exception e) {
            health.put("status", "DOWN");
            health.put("error", e.getMessage());
            health.put("timestamp", System.currentTimeMillis());
            
            return ResponseEntity.status(503).body(health);
        }
    }
}
