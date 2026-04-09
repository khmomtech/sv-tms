// package com.svtrucking.logistics.controller;

// import com.svtrucking.logistics.dto.DispatchDto;
// import com.svtrucking.logistics.enums.DispatchStatus;
// import com.svtrucking.logistics.model.LoadProof;
// import com.svtrucking.logistics.service.DispatchService;
// import com.svtrucking.logistics.service.LoadProofService;

// import jakarta.transaction.Transactional;

// import com.svtrucking.logistics.core.ApiResponse;

// import lombok.RequiredArgsConstructor;
// import lombok.extern.slf4j.Slf4j;

// import org.springframework.beans.factory.annotation.Autowired;
// import org.springframework.data.domain.Page;
// import org.springframework.data.domain.Pageable;
// import org.springframework.http.HttpStatus;
// import org.springframework.http.MediaType;
// import org.springframework.http.ResponseEntity;
// import org.springframework.web.bind.annotation.*;
// import org.springframework.web.multipart.MultipartFile;

// import java.time.LocalDateTime;
// import java.util.List;
// import java.util.Map;

// @Slf4j
// @RestController
// @RequestMapping("/api/admin/dispatches")
// @CrossOrigin(origins = "*") //  Allow Angular frontend
// @RequiredArgsConstructor
// public class LoadProofController {

//     private final LoadProofService loadProofService;

//     @PostMapping(value = "/{dispatchId}/load", consumes = MediaType.MULTIPART_FORM_DATA_VALUE)
//     @Transactional
//     public ResponseEntity<ApiResponse<LoadProof>> submitLoadProof(
//             @PathVariable Long dispatchId,
//             @RequestParam(required = false) String remarks,
//             @RequestParam("images") List<MultipartFile> images,
//             @RequestParam(value = "signature", required = false) MultipartFile signature) {
//         try {
//             if (images == null || images.isEmpty()) {
//                 return ResponseEntity.badRequest()
//                         .body(new ApiResponse<>(false, "At least one image is required.", null));
//             }

//             LoadProof proof = loadProofService.submitLoadProof(dispatchId, remarks, images,
// signature);
//             return ResponseEntity.ok(new ApiResponse<>(true, " Load proof submitted", proof));
//         } catch (Exception e) {
//             e.printStackTrace(); // Optional: log this in production
//             return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
//                     .body(new ApiResponse<>(false, "Failed to submit load proof", null));
//         }
//     }
// }
