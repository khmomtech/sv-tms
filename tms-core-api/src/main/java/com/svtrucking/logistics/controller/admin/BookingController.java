package com.svtrucking.logistics.controller.admin;

import com.svtrucking.logistics.core.ApiResponse;
import com.svtrucking.logistics.dto.BookingDto;
import com.svtrucking.logistics.dto.CreateBookingRequest;
import com.svtrucking.logistics.service.BookingService;
import java.util.HashMap;
import java.util.Map;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.data.domain.Sort;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/admin/bookings")
public class BookingController {

  @Autowired private BookingService bookingService;

  @PostMapping
  public ResponseEntity<ApiResponse<BookingDto>> create(@RequestBody CreateBookingRequest req) {
    return bookingService.create(req);
  }

  @PutMapping("/{id}")
  public ResponseEntity<ApiResponse<BookingDto>> update(
      @PathVariable Long id, @RequestBody CreateBookingRequest req) {
    return bookingService.update(id, req);
  }

  @GetMapping("/{id}")
  public ResponseEntity<ApiResponse<BookingDto>> get(@PathVariable Long id) {
    return bookingService.getById(id);
  }

  @PostMapping("/{id}/confirm")
  public ResponseEntity<ApiResponse<BookingDto>> confirm(@PathVariable Long id) {
    return bookingService.confirm(id);
  }

  @PostMapping("/{id}/cancel")
  public ResponseEntity<ApiResponse<BookingDto>> cancel(
      @PathVariable Long id, @RequestBody(required = false) Map<String, String> body) {
    String reason = body != null ? body.getOrDefault("reason", null) : null;
    return bookingService.cancel(id, reason);
  }

  @PostMapping("/{id}/convert-to-order")
  public ResponseEntity<ApiResponse<Map<String, Object>>> convertToOrder(@PathVariable Long id) {
    return bookingService.convertToOrder(id);
  }

  @GetMapping
  public ResponseEntity<ApiResponse<Map<String, Object>>> list(
      @RequestParam(defaultValue = "0") int page,
      @RequestParam(defaultValue = "10") int size,
      @RequestParam(required = false) String query,
      @RequestParam(required = false) String status,
      @RequestParam(required = false) String serviceType) {
    Pageable pageable = PageRequest.of(page, size, Sort.by("id").descending());
    Page<BookingDto> bookingPage = bookingService.list(pageable, query, status, serviceType);
    
    Map<String, Object> response = new HashMap<>();
    response.put("content", bookingPage.getContent());
    response.put("totalElements", bookingPage.getTotalElements());
    response.put("totalPages", bookingPage.getTotalPages());
    response.put("size", bookingPage.getSize());
    response.put("number", bookingPage.getNumber());
    response.put("empty", bookingPage.isEmpty());
    response.put("first", bookingPage.isFirst());
    response.put("last", bookingPage.isLast());
    
    return ResponseEntity.ok(ApiResponse.ok("Bookings retrieved successfully", response));
  }
}
