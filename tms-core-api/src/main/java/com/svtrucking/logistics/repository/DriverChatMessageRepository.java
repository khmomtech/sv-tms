package com.svtrucking.logistics.repository;

import com.svtrucking.logistics.model.DriverChatMessage;
import java.util.List;
import java.util.Optional;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.domain.Sort;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

@Repository
public interface DriverChatMessageRepository extends JpaRepository<DriverChatMessage, Long> {
  Page<DriverChatMessage> findByDriverId(Long driverId, Pageable pageable);

  List<DriverChatMessage> findByDriverId(Long driverId, Sort sort);

  Optional<DriverChatMessage> findFirstByDriverIdOrderByCreatedAtDesc(Long driverId);

  long countByDriverId(Long driverId);

  long countByDriverIdAndReadFalseAndSenderRoleIgnoreCase(Long driverId, String senderRole);

  @Query("select m.driverId from DriverChatMessage m group by m.driverId order by max(m.createdAt) desc")
  List<Long> findDriverIdsOrderedByLatestMessage();

  @Modifying(clearAutomatically = true, flushAutomatically = true)
  @Query("""
      update DriverChatMessage m
         set m.read = true
       where m.driverId = :driverId
         and upper(m.senderRole) = upper(:senderRole)
         and m.read = false
      """)
  int markConversationAsReadBySenderRole(
      @Param("driverId") Long driverId,
      @Param("senderRole") String senderRole);
}
