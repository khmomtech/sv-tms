// package com.svtrucking.logistics.service;

// import com.svtrucking.logistics.model.Order;
// import com.svtrucking.logistics.model.VehicleDocument;
// import com.svtrucking.logistics.model.VehicleInspection;
// import com.svtrucking.logistics.repository.AssignmentVehicleToDriverRepository;
// import com.svtrucking.logistics.repository.InspectionRepository;
// import com.svtrucking.logistics.repository.OrderRepository;
// import com.svtrucking.logistics.repository.VehicleRepository;
// import com.svtrucking.logistics.enums.OrderStatus;

// import org.springframework.beans.factory.annotation.Autowired;
// import org.springframework.stereotype.Service;
// import java.util.List;

// @Service
// public class ExpiryNotificationService {
//     public void checkAndNotify() {
//         List<VehicleDocument> expiringDocs = documentRepo.findExpiringDocuments();
//         for (VehicleDocument doc : expiringDocs) {
//             System.out.println("ALERT: " + doc.getDocumentType() + " for Vehicle " +
// doc.getVehicle().getLicensePlate() + " is expiring soon!");
//         }
//     }
// }
