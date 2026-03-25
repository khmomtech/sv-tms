package com.svtrucking.logistics.service;

import static org.mockito.Mockito.*;

import com.svtrucking.logistics.model.Driver;
import com.svtrucking.logistics.modules.notification.dto.CreateNotificationRequest;
import com.svtrucking.logistics.modules.notification.model.DriverNotification;
import com.svtrucking.logistics.modules.notification.repository.DriverNotificationRepository;
import com.svtrucking.logistics.modules.notification.service.DriverNotificationService;
import com.svtrucking.logistics.modules.notification.provider.PushProvider;
import com.svtrucking.logistics.repository.DriverRepository;
import com.svtrucking.logistics.messaging.CoreEventPublisher;
import java.time.LocalDateTime;
import java.util.Optional;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.messaging.simp.SimpMessagingTemplate;

class DriverNotificationServiceTest {

  private DriverNotificationRepository notificationRepository;
  private DriverRepository driverRepository;
  private CoreEventPublisher eventPublisher;
  private SimpMessagingTemplate messagingTemplate;
  private PushProvider pushProvider;
  private DriverNotificationService service;

  @BeforeEach
  void setUp() {
    notificationRepository = mock(DriverNotificationRepository.class);
    driverRepository = mock(DriverRepository.class);
    eventPublisher = mock(CoreEventPublisher.class);
    messagingTemplate = mock(SimpMessagingTemplate.class);
    pushProvider = mock(PushProvider.class);

    service = new DriverNotificationService(
        notificationRepository,
        driverRepository,
        eventPublisher,
        messagingTemplate,
        pushProvider);
  }

  @Test
  void sendNotification_pushesWebSocketAndPublishesEvent() {
    CreateNotificationRequest request = CreateNotificationRequest.builder()
        .driverId(42L)
        .title("Test")
        .message("Hello Driver")
        .type("ADMIN")
        .referenceId("42")
        .sender("ADMIN_UI")
        .build();

    DriverNotification saved = new DriverNotification();
    saved.setId(123L);
    saved.setDriverId(42L);
    saved.setTitle("Test");
    saved.setMessage("Hello Driver");
    saved.setType("ADMIN");
    saved.setReferenceId("42");
    saved.setSender("ADMIN_UI");
    saved.setCreatedAt(LocalDateTime.now());
    saved.setSentAt(LocalDateTime.now());

    when(notificationRepository.save(any(DriverNotification.class))).thenReturn(saved);

    service.sendNotification(request);

    verify(notificationRepository, times(1)).save(any(DriverNotification.class));
    verify(messagingTemplate, times(1))
        .convertAndSend(eq("/topic/driver-notification/42"), any(Object.class));
    verify(eventPublisher, times(1)).publishNotification(eq("42"), any());
  }

  @Test
  void sendNotification_noDriverId_doesNotPushWebSocket() {
    CreateNotificationRequest request = CreateNotificationRequest.builder()
        .title("Broadcast")
        .message("Anyone")
        .build();

    DriverNotification saved = new DriverNotification();
    saved.setId(999L);
    saved.setCreatedAt(LocalDateTime.now());
    saved.setSentAt(LocalDateTime.now());
    when(notificationRepository.save(any(DriverNotification.class))).thenReturn(saved);

    service.sendNotification(request);

    verify(notificationRepository, times(1)).save(any(DriverNotification.class));
    verify(messagingTemplate, never())
        .convertAndSend(startsWith("/topic/driver-notification/"), any(Object.class));
    verify(eventPublisher, times(1)).publishNotification(eq("broadcast"), any());
  }
}
