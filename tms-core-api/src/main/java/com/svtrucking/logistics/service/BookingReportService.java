package com.svtrucking.logistics.service;

import com.svtrucking.logistics.dto.BookingAnalyticsDto;
import com.svtrucking.logistics.dto.BookingDto;
import com.svtrucking.logistics.dto.BookingReportSummaryDto;
import com.svtrucking.logistics.model.Booking;
import com.svtrucking.logistics.repository.BookingRepository;
import java.io.ByteArrayOutputStream;
import java.io.OutputStreamWriter;
import java.io.PrintWriter;
import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.*;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.domain.Specification;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
@Transactional
public class BookingReportService {

  @Autowired private BookingRepository bookingRepository;

  public BookingReportSummaryDto getSummary(LocalDate startDate, LocalDate endDate, String status) {
    Specification<Booking> spec = buildSpecification(startDate, endDate, status, null, null);
    List<Booking> bookings = bookingRepository.findAll(spec);

    if (bookings.isEmpty()) {
      return BookingReportSummaryDto.builder()
          .totalBookings(0L)
          .confirmedBookings(0L)
          .cancelledBookings(0L)
          .convertedToOrderBookings(0L)
          .newBookings(0L)
          .totalRevenue(BigDecimal.ZERO)
          .averageCost(BigDecimal.ZERO)
          .confirmationRate(0.0)
          .cancellationRate(0.0)
          .conversionRate(0.0)
          .build();
    }

    long total = bookings.size();
    long confirmed = bookings.stream().filter(b -> "CONFIRMED".equals(b.getStatus())).count();
    long cancelled = bookings.stream().filter(b -> "CANCELLED".equals(b.getStatus())).count();
    long converted = bookings.stream().filter(b -> "CONVERTED_TO_ORDER".equals(b.getStatus())).count();
    long newBookings = bookings.stream().filter(b -> "NEW".equals(b.getStatus())).count();

    BigDecimal totalRevenue =
        bookings.stream()
            .map(Booking::getEstimatedCost)
            .filter(Objects::nonNull)
            .reduce(BigDecimal.ZERO, BigDecimal::add);

    BigDecimal averageCost =
        total > 0 ? totalRevenue.divide(BigDecimal.valueOf(total)) : BigDecimal.ZERO;

    return BookingReportSummaryDto.builder()
        .totalBookings(total)
        .confirmedBookings(confirmed)
        .cancelledBookings(cancelled)
        .convertedToOrderBookings(converted)
        .newBookings(newBookings)
        .totalRevenue(totalRevenue)
        .averageCost(averageCost)
        .confirmationRate(total > 0 ? (double) confirmed / total : 0.0)
        .cancellationRate(total > 0 ? (double) cancelled / total : 0.0)
        .conversionRate(total > 0 ? (double) converted / total : 0.0)
        .build();
  }

  public Page<BookingDto> getDetailedList(
      LocalDate startDate, LocalDate endDate, String status, String serviceType, Pageable pageable) {
    Specification<Booking> spec = buildSpecification(startDate, endDate, status, serviceType, null);
    Page<Booking> bookingPage = bookingRepository.findAll(spec, pageable);
    return bookingPage.map(BookingDto::fromEntity);
  }

  public List<BookingAnalyticsDto> getAnalyticsByCustomer(
      LocalDate startDate, LocalDate endDate) {
    Specification<Booking> spec = buildSpecification(startDate, endDate, null, null, null);
    List<Booking> bookings = bookingRepository.findAll(spec);

    return bookings.stream()
        .collect(
            java.util.stream.Collectors.groupingBy(
                b -> b.getCustomer() != null ? b.getCustomer().getName() : "Unknown"))
        .entrySet()
        .stream()
        .map(
            entry -> {
              List<Booking> groupBookings = entry.getValue();
              long confirmed =
                  groupBookings.stream().filter(b -> "CONFIRMED".equals(b.getStatus())).count();
              long converted =
                  groupBookings.stream()
                      .filter(b -> "CONVERTED_TO_ORDER".equals(b.getStatus()))
                      .count();
              BigDecimal revenue =
                  groupBookings.stream()
                      .map(Booking::getEstimatedCost)
                      .filter(Objects::nonNull)
                      .reduce(BigDecimal.ZERO, BigDecimal::add);
              long size = groupBookings.size();

              return BookingAnalyticsDto.builder()
                  .name(entry.getKey())
                  .count(size)
                  .revenue(revenue)
                  .averageCost(size > 0 ? revenue.divide(BigDecimal.valueOf(size)) : BigDecimal.ZERO)
                  .confirmationRate(size > 0 ? (double) confirmed / size : 0.0)
                  .conversionRate(size > 0 ? (double) converted / size : 0.0)
                  .build();
            })
        .sorted(Comparator.comparingLong(BookingAnalyticsDto::getCount).reversed())
        .toList();
  }

  public List<BookingAnalyticsDto> getAnalyticsByServiceType(
      LocalDate startDate, LocalDate endDate) {
    Specification<Booking> spec = buildSpecification(startDate, endDate, null, null, null);
    List<Booking> bookings = bookingRepository.findAll(spec);

    return bookings.stream()
        .collect(
            java.util.stream.Collectors.groupingBy(
                b -> b.getServiceType() != null ? b.getServiceType() : "Unknown"))
        .entrySet()
        .stream()
        .map(this::buildAnalytics)
        .sorted(Comparator.comparingLong(BookingAnalyticsDto::getCount).reversed())
        .toList();
  }

  public List<BookingAnalyticsDto> getAnalyticsByTruckType(
      LocalDate startDate, LocalDate endDate) {
    Specification<Booking> spec = buildSpecification(startDate, endDate, null, null, null);
    List<Booking> bookings = bookingRepository.findAll(spec);

    return bookings.stream()
        .collect(
            java.util.stream.Collectors.groupingBy(
                b -> b.getTruckType() != null ? b.getTruckType() : "Unknown"))
        .entrySet()
        .stream()
        .map(this::buildAnalytics)
        .sorted(Comparator.comparingLong(BookingAnalyticsDto::getCount).reversed())
        .toList();
  }

  public byte[] exportToCsv(
      LocalDate startDate, LocalDate endDate, String status, String serviceType) {
    Specification<Booking> spec = buildSpecification(startDate, endDate, status, serviceType, null);
    List<Booking> bookings = bookingRepository.findAll(spec);

    try (ByteArrayOutputStream out = new ByteArrayOutputStream();
        PrintWriter writer = new PrintWriter(new OutputStreamWriter(out))) {

      // Write CSV header
      writer.println(
          "ID,Customer,Service Type,Status,Pickup Date,Delivery Date,Truck Type,Estimated Cost");

      for (Booking booking : bookings) {
        writer.println(
            String.format(
                "%d,%s,%s,%s,%s,%s,%s,%s",
                booking.getId(),
                escapeQuotes(booking.getCustomer() != null ? booking.getCustomer().getName() : ""),
                escapeQuotes(booking.getServiceType() != null ? booking.getServiceType() : ""),
                escapeQuotes(booking.getStatus() != null ? booking.getStatus() : ""),
                booking.getPickupDate() != null ? booking.getPickupDate().toString() : "",
                booking.getDeliveryDate() != null ? booking.getDeliveryDate().toString() : "",
                escapeQuotes(booking.getTruckType() != null ? booking.getTruckType() : ""),
                booking.getEstimatedCost() != null ? booking.getEstimatedCost().toString() : "0"));
      }

      writer.flush();
      return out.toByteArray();
    } catch (Exception e) {
      throw new RuntimeException("Failed to export CSV", e);
    }
  }

  private String escapeQuotes(String value) {
    if (value == null) return "";
    return value.replace("\"", "\"\"");
  }

  private BookingAnalyticsDto buildAnalytics(Map.Entry<String, List<Booking>> entry) {
    List<Booking> groupBookings = entry.getValue();
    long confirmed =
        groupBookings.stream().filter(b -> "CONFIRMED".equals(b.getStatus())).count();
    long converted =
        groupBookings.stream().filter(b -> "CONVERTED_TO_ORDER".equals(b.getStatus())).count();
    BigDecimal revenue =
        groupBookings.stream()
            .map(Booking::getEstimatedCost)
            .filter(Objects::nonNull)
            .reduce(BigDecimal.ZERO, BigDecimal::add);
    long size = groupBookings.size();

    return BookingAnalyticsDto.builder()
        .name(entry.getKey())
        .count(size)
        .revenue(revenue)
        .averageCost(size > 0 ? revenue.divide(BigDecimal.valueOf(size)) : BigDecimal.ZERO)
        .confirmationRate(size > 0 ? (double) confirmed / size : 0.0)
        .conversionRate(size > 0 ? (double) converted / size : 0.0)
        .build();
  }

  private Specification<Booking> buildSpecification(
      LocalDate startDate, LocalDate endDate, String status, String serviceType, String query) {
    return (root, criteriaQuery, criteriaBuilder) -> {
      List<jakarta.persistence.criteria.Predicate> predicates = new ArrayList<>();

      if (startDate != null) {
        predicates.add(criteriaBuilder.greaterThanOrEqualTo(root.get("pickupDate"), startDate));
      }

      if (endDate != null) {
        predicates.add(criteriaBuilder.lessThanOrEqualTo(root.get("pickupDate"), endDate));
      }

      if (status != null && !status.isEmpty()) {
        predicates.add(criteriaBuilder.equal(root.get("status"), status));
      }

      if (serviceType != null && !serviceType.isEmpty()) {
        predicates.add(criteriaBuilder.equal(root.get("serviceType"), serviceType));
      }

      if (query != null && !query.isEmpty()) {
        String queryPattern = "%" + query.toLowerCase() + "%";
        predicates.add(
            criteriaBuilder.or(
                criteriaBuilder.like(
                    criteriaBuilder.lower(
                        root.get("customer").get("name")),
                    queryPattern),
                criteriaBuilder.like(
                    criteriaBuilder.lower(
                        root.get("id").as(String.class)),
                    queryPattern)));
      }

      return criteriaBuilder.and(predicates.toArray(new jakarta.persistence.criteria.Predicate[0]));
    };
  }
}
