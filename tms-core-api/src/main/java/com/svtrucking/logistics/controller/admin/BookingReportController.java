package com.svtrucking.logistics.controller.admin;

import com.svtrucking.logistics.core.ApiResponse;
import com.svtrucking.logistics.dto.BookingAnalyticsDto;
import com.svtrucking.logistics.dto.BookingDto;
import com.svtrucking.logistics.dto.BookingReportSummaryDto;
import com.svtrucking.logistics.service.BookingReportService;
import java.time.LocalDate;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.data.domain.Sort;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/admin/bookings/reports")
public class BookingReportController {

    @Autowired
    private BookingReportService bookingReportService;

    @GetMapping("/summary")
    public ResponseEntity<ApiResponse<BookingReportSummaryDto>> getSummary(
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate startDate,
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate endDate,
            @RequestParam(required = false) String status) {
        BookingReportSummaryDto summary = bookingReportService.getSummary(startDate, endDate, status);
        return ResponseEntity.ok(
                ApiResponse.ok("Booking summary retrieved successfully", summary));
    }

    @GetMapping("/detailed")
    public ResponseEntity<ApiResponse<Map<String, Object>>> getDetailedList(
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "20") int size,
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate startDate,
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate endDate,
            @RequestParam(required = false) String status,
            @RequestParam(required = false) String serviceType) {
        Pageable pageable = PageRequest.of(page, size, Sort.by("id").descending());
        Page<BookingDto> bookingPage = bookingReportService.getDetailedList(startDate, endDate, status, serviceType,
                pageable);

        Map<String, Object> response = new HashMap<>();
        response.put("content", bookingPage.getContent());
        response.put("totalElements", bookingPage.getTotalElements());
        response.put("totalPages", bookingPage.getTotalPages());
        response.put("size", bookingPage.getSize());
        response.put("number", bookingPage.getNumber());
        response.put("empty", bookingPage.isEmpty());
        response.put("first", bookingPage.isFirst());
        response.put("last", bookingPage.isLast());

        return ResponseEntity.ok(
                ApiResponse.ok("Detailed booking list retrieved successfully", response));
    }

    @GetMapping("/analytics/by-customer")
    public ResponseEntity<ApiResponse<List<BookingAnalyticsDto>>> getAnalyticsByCustomer(
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate startDate,
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate endDate) {
        List<BookingAnalyticsDto> analytics = bookingReportService.getAnalyticsByCustomer(startDate, endDate);
        return ResponseEntity.ok(
                ApiResponse.ok("Customer analytics retrieved successfully", analytics));
    }

    @GetMapping("/analytics/by-service-type")
    public ResponseEntity<ApiResponse<List<BookingAnalyticsDto>>> getAnalyticsByServiceType(
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate startDate,
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate endDate) {
        List<BookingAnalyticsDto> analytics = bookingReportService.getAnalyticsByServiceType(startDate, endDate);
        return ResponseEntity.ok(
                ApiResponse.ok("Service type analytics retrieved successfully", analytics));
    }

    @GetMapping("/analytics/by-truck-type")
    public ResponseEntity<ApiResponse<List<BookingAnalyticsDto>>> getAnalyticsByTruckType(
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate startDate,
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate endDate) {
        List<BookingAnalyticsDto> analytics = bookingReportService.getAnalyticsByTruckType(startDate, endDate);
        return ResponseEntity.ok(
                ApiResponse.ok("Truck type analytics retrieved successfully", analytics));
    }

    @GetMapping("/export/csv")
    public ResponseEntity<byte[]> exportCsv(
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate startDate,
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate endDate,
            @RequestParam(required = false) String status,
            @RequestParam(required = false) String serviceType) {
        byte[] csvData = bookingReportService.exportToCsv(startDate, endDate, status, serviceType);

        return ResponseEntity.ok()
                .header(
                        HttpHeaders.CONTENT_DISPOSITION,
                        "attachment; filename=\"bookings_report.csv\"")
                .contentType(MediaType.parseMediaType("text/csv"))
                .body(csvData);
    }
}
