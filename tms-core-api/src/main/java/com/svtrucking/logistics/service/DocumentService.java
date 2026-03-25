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
// public class DocumentService {

//     @Autowired private AssignmentVehicleToDriverRepository documentRepo;
//     @Autowired private VehicleRepository vehicleRepo;

//     public List<VehicleDocument> getAllDocuments() {
//         return documentRepo.findAll();
//     }

//     public List<VehicleDocument> getDocumentsByVehicle(Long vehicleId) {
//         return documentRepo.findByVehicleId(vehicleId);
//     }

//     public VehicleDocument uploadDocument(VehicleDocument document) {
//         return documentRepo.save(document);
//     }

//     public void deleteDocument(Long id) {
//         documentRepo.deleteById(id);
//     }

//     public void checkExpiringDocuments() {
//         List<VehicleDocument> expiringDocs = documentRepo.findExpiringDocuments();
//         for (VehicleDocument doc : expiringDocs) {
//             sendExpiryNotification(doc);
//         }
//     }

//     private void sendExpiryNotification(VehicleDocument doc) {
//         System.out.println("ALERT: Document " + doc.getDocumentType() + " for Vehicle " +
// doc.getVehicle().getLicensePlate() + " is expiring soon!");
//     }
// }
