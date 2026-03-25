package com.svtrucking.message.controller;

import com.svtrucking.message.model.MessageDeliveryAttempt;
import com.svtrucking.message.repository.MessageDeliveryAttemptRepository;
import java.util.List;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/internal/messages")
public class MessageAuditController {

    private final MessageDeliveryAttemptRepository attemptRepository;

    public MessageAuditController(MessageDeliveryAttemptRepository attemptRepository) {
        this.attemptRepository = attemptRepository;
    }

    @GetMapping("/delivery-attempts")
    public List<MessageDeliveryAttempt> listDeliveryAttempts() {
        return attemptRepository.findAll();
    }
}
