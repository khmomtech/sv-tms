package com.svtrucking.logistics.repository;

import com.svtrucking.logistics.model.DriverChatConversationMetadata;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

@Repository
public interface DriverChatConversationMetadataRepository
    extends JpaRepository<DriverChatConversationMetadata, Long> {}
