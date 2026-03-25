// package com.svtrucking.logistics.controller;

// import com.svtrucking.logistics.service.FirebaseMessagingService;
// import com.svtrucking.logistics.service.DriverService;
// import com.svtrucking.logistics.service.DriverNotificationService;
// import com.svtrucking.logistics.core.ApiResponse;
// import com.svtrucking.logistics.dto.DriverDto;
// import com.svtrucking.logistics.model.Driver;
// import org.springframework.http.ResponseEntity;
// import org.springframework.web.bind.annotation.*;

// import java.util.List;
// import java.util.logging.Logger;

// @RestController
// @RequestMapping("/api/admin/notifications")
// @CrossOrigin(origins = "*")
// public class NotificationController {

//     private static final Logger logger =
// Logger.getLogger(NotificationController.class.getName());

//     private final FirebaseMessagingService firebaseMessagingService;
//     private final DriverService driverService;
//     private final DriverNotificationService notificationService;

//     public NotificationController(FirebaseMessagingService firebaseMessagingService,
//                                   DriverService driverService,
//                                   DriverNotificationService notificationService) {
//         this.firebaseMessagingService = firebaseMessagingService;
//         this.driverService = driverService;
//         this.notificationService = notificationService;
//     }

//     /**
//      *  Send Notification to a Specific Driver via Device Token
//      */
//     @PostMapping("/send")
//     public ResponseEntity<String> sendNotification(
//             @RequestParam String token,
//             @RequestParam String title,
//             @RequestParam String body) {
//         try {
//             String response = firebaseMessagingService.sendNotification(token, title, body);
//             logger.info(" Notification sent to token: " + token);
//             return ResponseEntity.ok(response);
//         } catch (Exception e) {
//             logger.severe(" Failed to send notification: " + e.getMessage());
//             return ResponseEntity.internalServerError().body("Failed to send notification.");
//         }
//     }

//     @GetMapping("/notify-all")
//     public ResponseEntity<ApiResponse<String>> notifyAllDrivers(@RequestParam String title,
// @RequestParam String message) {
//         try {
//             List<DriverDto> drivers = driverService.getAllDrivers();
//             for (DriverDto driver : drivers) {
//                 notificationService.sendNotification(driver.getId(), title, message);
//                 logger.info(String.format(" Sent to driver ID: %d", driver.getId()));
//             }
//             return ResponseEntity.ok(new ApiResponse<>(true, "All drivers notified."));
//         } catch (Exception e) {
//             return ResponseEntity.status(500).body(new ApiResponse<>(false, e.getMessage()));
//         }
//     }

// }
