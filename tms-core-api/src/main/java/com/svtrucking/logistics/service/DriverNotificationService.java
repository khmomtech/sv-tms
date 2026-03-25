// package com.svtrucking.logistics.service;

// import com.google.firebase.messaging.FirebaseMessaging;
// import com.google.firebase.messaging.Message;
// import com.google.firebase.messaging.Notification;
// import com.svtrucking.logistics.dto.NotificationDTO;
// import com.svtrucking.logistics.model.Driver;
// import com.svtrucking.logistics.modules.notification.model.DriverNotification;
// import com.svtrucking.logistics.repository.DriverNotificationRepository;
// import com.svtrucking.logistics.repository.DriverRepository;

// import org.springframework.beans.factory.annotation.Autowired;
// import org.springframework.data.domain.Page;
// import org.springframework.data.domain.PageRequest;
// import org.springframework.stereotype.Service;
// import org.springframework.transaction.annotation.Transactional;

// import java.util.Optional;
// import java.util.logging.Logger;

// @Service
// public class DriverNotificationService {

//     private static final Logger logger =
// Logger.getLogger(DriverNotificationService.class.getName());

//     private final DriverNotificationRepository notificationRepository;
//     private final DriverRepository driverRepository;

//     @Autowired
//     public DriverNotificationService(
//             DriverNotificationRepository notificationRepository,
//             DriverRepository driverRepository) {
//         this.notificationRepository = notificationRepository;
//         this.driverRepository = driverRepository;
//     }

//     /**
//      *  Send Push & Save Notification to DB
//      */
//     public void sendNotification(Long driverId, String title, String body) {
//         Optional<Driver> optionalDriver = driverRepository.findById(driverId);
//         if (optionalDriver.isEmpty()) {
//             throw new RuntimeException("Driver not found: " + driverId);
//         }

//         Driver driver = optionalDriver.get();
//         String deviceToken = driver.getDeviceToken();

//         if (deviceToken == null || deviceToken.isEmpty()) {
//             logger.warning("Driver has no device token.");
//         } else {
//             try {
//                 Message message = Message.builder()
//                         .setToken(deviceToken)
//                         .setNotification(Notification.builder()
//                                 .setTitle(title)
//                                 .setBody(body)
//                                 .build())
//                         .build();

//                 FirebaseMessaging.getInstance().send(message);
//                 logger.info(" Push notification sent to driver.");
//             } catch (Exception e) {
//                 logger.warning(" Failed to send FCM push: " + e.getMessage());
//             }
//         }

//         saveNotification(title, body, driverId);
//     }

//     /**
//      *  Save a Notification Record
//      */
//     public void saveNotification(String title, String body, Long driverId) {
//         DriverNotification notification = DriverNotification.builder()
//                 .title(title)
//                 .message(body)
//                 .driverId(driverId)
//                 .isRead(false)
//                 .build();

//         notificationRepository.save(notification);
//         logger.info(" Notification saved to DB.");
//     }

//     /**
//      *  Paginated Driver Notifications
//      */
//     public Page<DriverNotification> getNotifications(Long driverId, int page, int size) {
//         return notificationRepository.findByDriverIdOrderByCreatedAtDesc(driverId,
// PageRequest.of(page, size));
//     }

//     /**
//      *  Mark as Read
//      */
//     @Transactional
//     public void markAsRead(Long id) {
//         Optional<DriverNotification> optional = notificationRepository.findById(id);
//         if (optional.isEmpty()) {
//             throw new RuntimeException("Notification not found.");
//         }

//         DriverNotification notif = optional.get();
//         notif.setRead(true);
//         notificationRepository.save(notif);
//         logger.info(" Notification marked as read: " + id);
//     }

//     /**
//      *  Delete One Notification
//      */
//     public void deleteNotification(Long id) {
//         if (!notificationRepository.existsById(id)) {
//             throw new RuntimeException("Notification not found.");
//         }
//         notificationRepository.deleteById(id);
//         logger.info(" Notification deleted: " + id);
//     }

//     /**
//      *  Delete All for Driver
//      */
//     @Transactional
//     public void deleteAllNotificationsForDriver(Long driverId) {
//         notificationRepository.deleteByDriverId(driverId);
//         logger.info(" All notifications deleted for Driver ID: " + driverId);
//     }

//     /**
//      *  Convert Entity to DTO
//      */
//     public NotificationDTO convertToDTO(DriverNotification n) {
//         return NotificationDTO.builder()
//                 .id(n.getId())
//                 .title(n.getTitle())
//                 .body(n.getMessage())
//                 .isRead(n.isRead())
//                 .createdAt(n.getCreatedAt())
//                 .build();
//     }

//     @Transactional
// public void markAllAsReadByDriver(Long driverId) {
//     notificationRepository.markAllAsReadByDriver(driverId);
//     logger.info(" All notifications marked as read for Driver ID: " + driverId);
// }
// }
