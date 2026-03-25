// package com.svtrucking.logistics.controller;

// import com.svtrucking.logistics.model.AssignmentVehicleToDriver;
// import com.svtrucking.logistics.model.Vehicle;
// import com.svtrucking.logistics.repository.VehicleRepository;
// import com.svtrucking.logistics.service.FleetService;

// import java.util.List;
// import java.util.Optional;

// import org.springframework.beans.factory.annotation.Autowired;
// import org.springframework.http.HttpStatus;
// import org.springframework.http.ResponseEntity;
// import org.springframework.scheduling.annotation.Scheduled;
// import org.springframework.web.bind.annotation.*;

// @RestController
// @RequestMapping("/api/documents")
// public class DocumentController {

//     @Autowired private DocumentService documentService;

//     // Get All Documents
//     @GetMapping("/")
//     public List<VehicleDocument> getAllDocuments() {
//         return documentService.getAllDocuments();
//     }

//     // Get Documents by Vehicle ID
//     @GetMapping("/vehicle/{vehicleId}")
//     public List<VehicleDocument> getDocumentsByVehicle(@PathVariable Long vehicleId) {
//         return documentService.getDocumentsByVehicle(vehicleId);
//     }

//     // Upload Document
//     @PostMapping("/upload")
//     public ResponseEntity<VehicleDocument> uploadDocument(@RequestBody VehicleDocument document)
// {
//         return ResponseEntity.ok(documentService.uploadDocument(document));
//     }

//     // Delete Document
//     @DeleteMapping("/delete/{id}")
//     public ResponseEntity<?> deleteDocument(@PathVariable Long id) {
//         documentService.deleteDocument(id);
//         return ResponseEntity.ok("Document deleted successfully");
//     }
// }
