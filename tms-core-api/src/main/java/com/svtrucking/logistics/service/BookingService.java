package com.svtrucking.logistics.service;

import com.svtrucking.logistics.core.ApiResponse;
import com.svtrucking.logistics.dto.BookingDto;
import com.svtrucking.logistics.dto.CreateBookingRequest;
import com.svtrucking.logistics.model.Booking;
import com.svtrucking.logistics.model.CustomerAddress;
import com.svtrucking.logistics.repository.BookingRepository;
import com.svtrucking.logistics.repository.CustomerAddressRepository;
import java.util.List;
import java.util.stream.Collectors;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.http.ResponseEntity;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
@Transactional(readOnly = true)
public class BookingService {

  @Autowired private BookingRepository bookingRepository;
  @Autowired private CustomerAddressRepository orderAddressRepository;

  @Transactional
  public ResponseEntity<ApiResponse<BookingDto>> create(CreateBookingRequest req) {
    Booking booking = new Booking();

    // Set customer
    if (req.getCustomerId() == null) {
      return ResponseEntity.badRequest().body(ApiResponse.fail("customerId is required"));
    }
    com.svtrucking.logistics.model.Customer c = new com.svtrucking.logistics.model.Customer();
    c.setId(req.getCustomerId());
    booking.setCustomer(c);

    // Persist or reuse addresses
    if (req.getPickupAddress() != null) {
      CustomerAddress pickup = req.getPickupAddress().toOrderAddress();
      if (pickup.getId() != null) {
        pickup = orderAddressRepository.findById(pickup.getId()).orElse(pickup);
      } else {
        pickup = orderAddressRepository.save(pickup);
      }
      booking.setPickupAddress(pickup);
    }
    if (req.getDeliveryAddress() != null) {
      CustomerAddress drop = req.getDeliveryAddress().toOrderAddress();
      if (drop.getId() != null) {
        drop = orderAddressRepository.findById(drop.getId()).orElse(drop);
      } else {
        drop = orderAddressRepository.save(drop);
      }
      booking.setDeliveryAddress(drop);
    }

    // Copy primitives
    booking.setServiceType(req.getServiceType());
    booking.setPaymentType(req.getPaymentType());
    booking.setPickupDate(req.getPickupDate());
    booking.setDeliveryDate(req.getDeliveryDate());
    booking.setTruckType(req.getTruckType());
    booking.setCapacity(req.getCapacity());
    booking.setEstimatedCost(req.getEstimatedCost());
    booking.setTotalWeightTons(req.getTotalWeightTons());
    booking.setTotalVolumeCbm(req.getTotalVolumeCbm());
    booking.setPalletCount(req.getPalletCount());
    booking.setSpecialHandlingNotes(req.getSpecialHandlingNotes());
    booking.setRequiresInsurance(req.getRequiresInsurance());
    booking.setNotes(req.getNotes());

    Booking saved = bookingRepository.save(booking);
    return ResponseEntity.ok(ApiResponse.ok("Booking created", BookingDto.fromEntity(saved)));
  }

  @Transactional
  public ResponseEntity<ApiResponse<BookingDto>> update(Long id, CreateBookingRequest req) {
    return bookingRepository
        .findById(id)
        .map(
            existing -> {
              // Update customer if provided
              if (req.getCustomerId() != null) {
                com.svtrucking.logistics.model.Customer c =
                    new com.svtrucking.logistics.model.Customer();
                c.setId(req.getCustomerId());
                existing.setCustomer(c);
              }

              // Persist or reuse addresses when provided
              if (req.getPickupAddress() != null) {
                CustomerAddress pickup = req.getPickupAddress().toOrderAddress();
                if (pickup.getId() != null) {
                  pickup = orderAddressRepository.findById(pickup.getId()).orElse(pickup);
                } else {
                  pickup = orderAddressRepository.save(pickup);
                }
                existing.setPickupAddress(pickup);
              }

              if (req.getDeliveryAddress() != null) {
                CustomerAddress drop = req.getDeliveryAddress().toOrderAddress();
                if (drop.getId() != null) {
                  drop = orderAddressRepository.findById(drop.getId()).orElse(drop);
                } else {
                  drop = orderAddressRepository.save(drop);
                }
                existing.setDeliveryAddress(drop);
              }

              // Copy primitives (PUT semantics assume full payload)
              existing.setServiceType(req.getServiceType());
              existing.setPaymentType(req.getPaymentType());
              existing.setPickupDate(req.getPickupDate());
              existing.setDeliveryDate(req.getDeliveryDate());
              existing.setTruckType(req.getTruckType());
              existing.setCapacity(req.getCapacity());
              existing.setEstimatedCost(req.getEstimatedCost());
              existing.setTotalWeightTons(req.getTotalWeightTons());
              existing.setTotalVolumeCbm(req.getTotalVolumeCbm());
              existing.setPalletCount(req.getPalletCount());
              existing.setSpecialHandlingNotes(req.getSpecialHandlingNotes());
              existing.setRequiresInsurance(req.getRequiresInsurance());
              existing.setNotes(req.getNotes());

              Booking saved = bookingRepository.save(existing);
              return ResponseEntity.ok(
                  ApiResponse.ok("Booking updated", BookingDto.fromEntity(saved)));
            })
        .orElseGet(() -> ResponseEntity.ok(ApiResponse.fail("Booking not found")));
  }

  public ResponseEntity<ApiResponse<BookingDto>> getById(Long id) {
    return bookingRepository
        .findById(id)
        .map(b -> ResponseEntity.ok(ApiResponse.ok("Booking found", BookingDto.fromEntity(b))))
        .orElseGet(() -> ResponseEntity.ok(ApiResponse.fail("Booking not found")));
  }

  @Transactional
  public ResponseEntity<ApiResponse<BookingDto>> confirm(Long id) {
    return bookingRepository
        .findById(id)
        .map(
            booking -> {
              booking.setStatus("CONFIRMED");
              Booking saved = bookingRepository.save(booking);
              return ResponseEntity.ok(
                  ApiResponse.ok("Booking confirmed", BookingDto.fromEntity(saved)));
            })
        .orElseGet(() -> ResponseEntity.ok(ApiResponse.fail("Booking not found")));
  }

  @Transactional
  public ResponseEntity<ApiResponse<BookingDto>> cancel(Long id, String reason) {
    return bookingRepository
        .findById(id)
        .map(
            booking -> {
              booking.setStatus("CANCELLED");
              if (reason != null && !reason.isBlank()) {
                String notes = booking.getNotes();
                String newNotes =
                    (notes == null || notes.isBlank())
                        ? "Cancellation reason: " + reason
                        : notes + "\nCancellation reason: " + reason;
                booking.setNotes(newNotes);
              }
              Booking saved = bookingRepository.save(booking);
              return ResponseEntity.ok(
                  ApiResponse.ok("Booking cancelled", BookingDto.fromEntity(saved)));
            })
        .orElseGet(() -> ResponseEntity.ok(ApiResponse.fail("Booking not found")));
  }

  @Transactional
  public ResponseEntity<ApiResponse<java.util.Map<String, Object>>> convertToOrder(Long id) {
    return bookingRepository
        .findById(id)
        .map(
            booking -> {
              booking.setStatus("CONVERTED_TO_ORDER");
              bookingRepository.save(booking);

              java.util.Map<String, Object> payload = new java.util.HashMap<>();
              payload.put("orderId", booking.getId());

              return ResponseEntity.ok(
                  ApiResponse.ok("Booking converted to order", payload));
            })
        .orElseGet(() -> ResponseEntity.ok(ApiResponse.fail("Booking not found")));
  }

  public Page<BookingDto> list(Pageable pageable, String query, String status, String serviceType) {
    Page<Booking> bookingPage = bookingRepository.findAll(pageable);
    return bookingPage.map(BookingDto::fromEntity);
  }
}
