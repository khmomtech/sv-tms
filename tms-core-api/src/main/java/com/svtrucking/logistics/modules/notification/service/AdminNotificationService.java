package com.svtrucking.logistics.modules.notification.service;

import com.svtrucking.logistics.modules.notification.dto.NotificationDTO;
import com.svtrucking.logistics.modules.notification.model.AdminNotification;
import com.svtrucking.logistics.modules.notification.repository.AdminNotificationRepository;
import java.time.LocalDateTime;
import java.util.List;
import java.util.stream.Collectors;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Sort;
import org.springframework.messaging.simp.SimpMessagingTemplate;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
@RequiredArgsConstructor
public class AdminNotificationService {

  private final AdminNotificationRepository repository;
  private final SimpMessagingTemplate messagingTemplate;

  /** 🆕 Save a new admin notification and send via WebSocket */
  public void saveNotification(
      String title,
      String message,
      String type,
      String topic,
      String referenceId,
      String severity,
      String sender,
      String actionUrl,
      String actionLabel) {
    AdminNotification notif =
        AdminNotification.builder()
            .title(title)
            .message(message)
            .type(type)
            .topic(topic)
            .referenceId(referenceId)
            .severity(severity)
            .sender(sender)
            .actionUrl(actionUrl)
            .actionLabel(actionLabel)
            .isRead(false)
            .createdAt(LocalDateTime.now())
            .build();

    AdminNotification saved = repository.save(notif);

    // 🔔 WebSocket broadcast after saving
    messagingTemplate.convertAndSend("/topic/admin-notifications", convertToDTO(saved));
  }

  /** Get all admin notifications (latest first) */
  public List<AdminNotification> getAll() {
    return repository.findAll(Sort.by(Sort.Direction.DESC, "createdAt"));
  }

  /** 📤 Get all notifications as DTOs */
  public List<NotificationDTO> getAllAsDTOs() {
    return getAll().stream().map(this::convertToDTO).collect(Collectors.toList());
  }

  /** 🔄 Convert AdminNotification to NotificationDTO */
  public NotificationDTO convertToDTO(AdminNotification n) {
    return NotificationDTO.builder()
        .id(n.getId())
        .title(n.getTitle())
        .body(n.getMessage())
        .type(n.getType())
        .topic(n.getTopic())
        .referenceId(n.getReferenceId())
        .actionUrl(n.getActionUrl())
        .actionLabel(n.getActionLabel())
        .severity(n.getSeverity())
        .sender(n.getSender())
        .isRead(n.isRead())
        .createdAt(n.getCreatedAt())
        .build();
  }

  /** Mark a single admin notification as read */
  @Transactional
  public void markAsRead(Long id) {
    repository
        .findById(id)
        .ifPresent(
            notification -> {
              notification.setRead(true);
              repository.save(notification);
            });
  }

  /** Mark all as read */
  @Transactional
  public void markAllAsRead() {
    repository.markAllAsRead();
  }

  /** 🗑️ Delete by ID */
  public void delete(Long id) {
    repository.deleteById(id);
  }

  /** 🧹 Clear all notifications */
  public void clearAll() {
    repository.deleteAll();
  }

  /** 🔢 Count of unread notifications */
  public long countUnread() {
    return repository.countByIsReadFalse();
  }
}
