package com.svtrucking.message.repository;

import com.svtrucking.message.model.MessageDeliveryAttempt;
import org.springframework.data.jpa.repository.JpaRepository;

public interface MessageDeliveryAttemptRepository extends JpaRepository<MessageDeliveryAttempt, Long> {
}
