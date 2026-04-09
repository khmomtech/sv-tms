package com.svtrucking.logistics.service;

import com.svtrucking.logistics.core.ApiResponse;
import com.svtrucking.logistics.dto.ImportError;
import com.svtrucking.logistics.dto.CustomerAddressDto;
import com.svtrucking.logistics.dto.EmployeeDto;
import com.svtrucking.logistics.dto.OrderItemDto;
import com.svtrucking.logistics.dto.OrderStopDto;
import com.svtrucking.logistics.dto.TransportOrderDto;
import com.svtrucking.logistics.dto.requests.UpdateTransportOrderDto;
import com.svtrucking.logistics.enums.AssignmentStatus;
import com.svtrucking.logistics.enums.DispatchStatus;
import com.svtrucking.logistics.enums.OrderStatus;
import com.svtrucking.logistics.enums.OrderOrigin;
import com.svtrucking.logistics.enums.StopType;
import com.svtrucking.logistics.exception.ResourceNotFoundException;
import com.svtrucking.logistics.model.TransportOrder;
import com.svtrucking.logistics.model.User;
import com.svtrucking.logistics.model.OrderItem;
import com.svtrucking.logistics.model.CustomerAddress;
import com.svtrucking.logistics.model.OrderStop;
import com.svtrucking.logistics.model.Dispatch;
import com.svtrucking.logistics.model.Vehicle;
import com.svtrucking.logistics.model.VehicleDriver;
import com.svtrucking.logistics.model.Item;
import com.svtrucking.logistics.model.Customer;
import com.svtrucking.logistics.repository.TransportOrderRepository;
import com.svtrucking.logistics.repository.UserRepository;
import com.svtrucking.logistics.repository.OrderItemRepository;
import com.svtrucking.logistics.repository.ItemRepository;
import com.svtrucking.logistics.repository.CustomerRepository;
import com.svtrucking.logistics.repository.CustomerAddressRepository;
import com.svtrucking.logistics.repository.OrderStopRepository;
import com.svtrucking.logistics.repository.DispatchRepository;
import com.svtrucking.logistics.repository.VehicleRepository;
import com.svtrucking.logistics.repository.VehicleDriverRepository;
import com.svtrucking.logistics.repository.EmployeeRepository;
import jakarta.persistence.EntityManager;
import jakarta.persistence.PersistenceContext;
import java.io.InputStream;
import java.time.LocalDate;
import java.time.format.DateTimeFormatter;
import java.util.ArrayList;
import java.util.Collection;
import java.util.HashSet;
import java.util.LinkedHashMap;
import java.util.LinkedHashSet;
import java.util.List;
import java.util.Map;
import java.util.Objects;
import java.util.Set;
import java.util.regex.Pattern;
import java.util.stream.Collectors;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.data.domain.PageImpl;
import lombok.extern.slf4j.Slf4j;
import org.apache.poi.ss.usermodel.Cell;
import org.apache.poi.ss.usermodel.DataFormatter;
import org.apache.poi.ss.usermodel.DateUtil;
import org.apache.poi.ss.usermodel.Row;
import org.apache.poi.ss.usermodel.Sheet;
import org.apache.poi.ss.usermodel.Workbook;
import org.apache.poi.ss.usermodel.WorkbookFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.http.ResponseEntity;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.security.core.userdetails.UsernameNotFoundException;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.multipart.MultipartFile;

import com.svtrucking.logistics.validator.TransportOrderValidator;

@Slf4j
@Service
public class TransportOrderService {

    private static final String ORDER_NOT_FOUND = "Order Not Found";
    private final TransportOrderRepository repository;

    @PersistenceContext
    private EntityManager entityManager;

    @Autowired
    private UserRepository userRepository;
    @Autowired
    private OrderItemRepository orderItemRepository;

    @Autowired
    private ItemRepository itemRepository;

    @Autowired
    private CustomerRepository customerRepository;
    @Autowired
    private CustomerAddressRepository orderAddressRepository;

    @Autowired
    private OrderStopRepository orderStopRepository;

    @Autowired
    private DispatchRepository dispatchRepository;

    @Autowired
    private VehicleRepository vehicleRepository;

    @Autowired
    private TransportOrderValidator transportOrderValidator;

    @Autowired
    private VehicleDriverRepository vehicleDriverRepository;
    @Autowired
    private EmployeeRepository employeeRepository;
    @Autowired
    private DispatchWorkflowPolicyService dispatchWorkflowPolicyService;
    @Autowired
    private JdbcTemplate jdbcTemplate;

    public TransportOrderService(TransportOrderRepository repository) {
        this.repository = repository;
    }

    private static final Pattern ORDER_REF_PATTERN = Pattern.compile("^[0-9]{7}-[0-9]{5}$");
    private static final long MAX_IMPORT_FILE_BYTES = 5 * 1024 * 1024; // 5 MB safety guard
    private static final int MAX_IMPORT_ROWS = 5_000; // prevent OOM/slow uploads
    private static final Set<String> ALLOWED_IMPORT_CONTENT_TYPES = Set.of(
            "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
            "application/vnd.ms-excel");
    private static final List<String> REQUIRED_IMPORT_HEADERS = List.of(
            "DeliveryDate",
            "CustomerCode",
            "TrackingNo",
            "TruckTripCount",
            "TruckNumber",
            "TripNo",
            "FromDestination",
            "ToDestination",
            "ItemCode",
            "ItemName",
            "Qty",
            "UoM",
            "UoMPallet",
            "LoadingPlace",
            "Status");
    private static final DateTimeFormatter IMPORT_DATE_FORMAT = DateTimeFormatter.ofPattern("dd.MM.yyyy");
    private static final DataFormatter EXCEL_FORMATTER = new DataFormatter();

    private String normalizeKey(String raw) {
        return raw == null ? null : raw.trim().toLowerCase();
    }

    private String normalizeVehiclePlate(String raw) {
        if (raw == null) {
            return null;
        }
        String normalized = raw.replaceAll("[^A-Za-z0-9]", "").toLowerCase();
        return normalized.isEmpty() ? null : normalized;
    }

    private Map<String, VehicleDriver> buildActiveVehicleDriverByPlateMap() {
        List<VehicleDriver> activeAssignments = vehicleDriverRepository.findAllActiveWithVehicleAndDriverOrderByAssignedAtDesc();
        Map<String, VehicleDriver> byPlate = new LinkedHashMap<>();
        for (VehicleDriver assignment : activeAssignments) {
            if (assignment.getVehicle() == null || assignment.getVehicle().getLicensePlate() == null) {
                continue;
            }
            String plateKey = normalizeVehiclePlate(assignment.getVehicle().getLicensePlate());
            if (plateKey == null) {
                continue;
            }
            byPlate.putIfAbsent(plateKey, assignment);
        }
        return byPlate;
    }

    private int logDuplicateActiveAssignmentWarnings(Map<String, VehicleDriver> selectedByPlate) {
        List<VehicleDriver> activeAssignments = vehicleDriverRepository.findAllActiveWithVehicleAndDriverOrderByAssignedAtDesc();
        Map<String, List<VehicleDriver>> groupedByPlate = new LinkedHashMap<>();
        for (VehicleDriver assignment : activeAssignments) {
            if (assignment.getVehicle() == null || assignment.getVehicle().getLicensePlate() == null) {
                continue;
            }
            String plateKey = normalizeVehiclePlate(assignment.getVehicle().getLicensePlate());
            if (plateKey == null) {
                continue;
            }
            groupedByPlate.computeIfAbsent(plateKey, ignored -> new ArrayList<>()).add(assignment);
        }

        int warnings = 0;
        for (Map.Entry<String, List<VehicleDriver>> entry : groupedByPlate.entrySet()) {
            List<VehicleDriver> assignments = entry.getValue();
            if (assignments.size() <= 1) {
                continue;
            }
            VehicleDriver selected = selectedByPlate.get(entry.getKey());
            if (selected == null) {
                continue;
            }
            List<String> ignored = assignments.stream()
                    .filter(a -> !Objects.equals(a.getId(), selected.getId()))
                    .map(a -> "assignmentId=" + a.getId() + ",driverId="
                            + (a.getDriver() != null ? a.getDriver().getId() : null))
                    .toList();
            log.warn(
                    "Multiple active vehicle assignments found for normalizedPlate={}; selected assignmentId={}, driverId={}, ignored=[{}]",
                    entry.getKey(),
                    selected.getId(),
                    selected.getDriver() != null ? selected.getDriver().getId() : null,
                    String.join("; ", ignored));
            warnings++;
        }
        return warnings;
    }

    private Set<String> loadNormalizedSetFromSql(String sql) {
        return jdbcTemplate.query(sql, (rs, rowNum) -> normalizeKey(rs.getString(1))).stream()
                .filter(Objects::nonNull)
                .collect(Collectors.toCollection(LinkedHashSet::new));
    }

    private Set<String> loadNormalizedVehicleSetFromSql(String sql) {
        return jdbcTemplate.query(sql, (rs, rowNum) -> normalizeVehiclePlate(rs.getString(1))).stream()
                .filter(Objects::nonNull)
                .collect(Collectors.toCollection(LinkedHashSet::new));
    }

    private Map<String, Long> loadNormalizedIdMapFromSql(String sql) {
        return jdbcTemplate.query(sql, rs -> {
            Map<String, Long> result = new LinkedHashMap<>();
            while (rs.next()) {
                String key = normalizeKey(rs.getString(2));
                if (key != null) {
                    result.putIfAbsent(key, rs.getLong(1));
                }
            }
            return result;
        });
    }

    private Map<String, Long> loadNormalizedVehicleIdMapFromSql(String sql) {
        return jdbcTemplate.query(sql, rs -> {
            Map<String, Long> result = new LinkedHashMap<>();
            while (rs.next()) {
                String key = normalizeVehiclePlate(rs.getString(2));
                if (key != null) {
                    result.putIfAbsent(key, rs.getLong(1));
                }
            }
            return result;
        });
    }

    @Transactional(readOnly = true)
    public ApiResponse<Page<TransportOrderDto>> getAllOrders(Pageable pageable) {
        Page<TransportOrder> orders = repository.findAll(pageable);
        Page<TransportOrderDto> dtoOrders = mapTransportOrderPage(orders);
        return new ApiResponse<>(true, "Orders retrieved successfully", dtoOrders);
    }

    @Transactional(readOnly = true)
    public ApiResponse<List<TransportOrderDto>> getAllOrderLists() {
        List<TransportOrder> orders = repository.findAll();
        initializeStops(orders);
        List<TransportOrderDto> dtoOrders = orders.stream().map(TransportOrderDto::fromEntity)
                .collect(Collectors.toList());
        return new ApiResponse<>(true, "Orders retrieved successfully", dtoOrders);
    }

    @Transactional(readOnly = true)
    public ApiResponse<List<String>> getShipmentTypes() {
        List<String> types = repository.findDistinctShipmentTypes().stream()
                .map(String::trim)
                .filter(type -> !type.isEmpty())
                .distinct()
                .toList();

        if (types.isEmpty()) {
            types = List.of("FTL", "LTL", "EXPRESS", "STANDARD");
        }

        return new ApiResponse<>(true, "Shipment types retrieved successfully", types);
    }

    @Transactional(readOnly = true)
    public ApiResponse<List<EmployeeDto>> getAvailableSellers() {
        List<EmployeeDto> sellers = employeeRepository.findAllByOrderByFirstNameAscLastNameAsc().stream()
                .map(EmployeeDto::fromEntity)
                .toList();
        return new ApiResponse<>(true, "Sellers retrieved successfully", sellers);
    }

    @Transactional(readOnly = true)
    public ResponseEntity<ApiResponse<Page<TransportOrderDto>>> searchOrders(
            String query, Pageable pageable) {
        Page<TransportOrder> results = repository.findByOrderReferenceContainingOrCustomerNameContainingIgnoreCase(
                query, query, pageable);
        Page<TransportOrderDto> dtoResults = mapTransportOrderPage(results);
        return ResponseEntity.ok(new ApiResponse<>(true, "Search results retrieved", dtoResults));
    }

    public ResponseEntity<ApiResponse<Page<TransportOrder>>> filterByStatus(
            OrderStatus status, Pageable pageable) {
        Page<TransportOrder> results = repository.findByStatus(status, pageable);
        return ResponseEntity.ok(new ApiResponse<>(true, "Filtered orders retrieved", results));
    }

    public ResponseEntity<ApiResponse<Page<TransportOrder>>> filterByDateRange(
            LocalDate startDate, LocalDate endDate, Pageable pageable) {
        Page<TransportOrder> results = repository.findByOrderDateBetween(startDate, endDate, pageable);
        return ResponseEntity.ok(new ApiResponse<>(true, "Filtered orders retrieved", results));
    }

    @Transactional(readOnly = true)
    public ResponseEntity<ApiResponse<TransportOrderDto>> getOrderById(Long id) {
        TransportOrder order = repository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException(ORDER_NOT_FOUND));
        return ResponseEntity.ok(
                new ApiResponse<>(true, "Order retrieved", TransportOrderDto.fromEntity(order)));
    }

    @Transactional
    public ResponseEntity<ApiResponse<TransportOrderDto>> updateOrder(
            Long id, UpdateTransportOrderDto orderDto) {
        TransportOrder existingOrder = repository
                .findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Transport Order not found"));

        // Update core fields
        existingOrder.setOrderDate(orderDto.getOrderDate());
        existingOrder.setDeliveryDate(orderDto.getDeliveryDate());
        existingOrder.setShipmentType(orderDto.getShipmentType());
        existingOrder.setBillTo(orderDto.getBillTo());
        existingOrder.setCourierAssigned(orderDto.getCourierAssigned());
        if (orderDto.getStatus() != null) {
            transportOrderValidator.validateStatusTransition(existingOrder.getStatus(), orderDto.getStatus());
            existingOrder.setStatus(orderDto.getStatus());
        }

        if (orderDto.getOrigin() != null) {
            existingOrder.setOrigin(orderDto.getOrigin());
        }
        if (orderDto.getRequiresDriver() != null) {
            existingOrder.setRequiresDriver(orderDto.getRequiresDriver());
        }
        if (orderDto.getSourceReference() != null) {
            existingOrder.setSourceReference(orderDto.getSourceReference());
        }

        // Update customer
        if (orderDto.getCustomerId() != null) {
            customerRepository.findById(orderDto.getCustomerId()).ifPresent(existingOrder::setCustomer);
        }

        // Update addresses
        if (orderDto.getPickupAddress() != null) {
            existingOrder.setPickupAddress(
                    findOrCreateOrderAddress(orderDto.getPickupAddress(), existingOrder));
        }
        if (orderDto.getDropAddress() != null) {
            existingOrder.setDropAddress(
                    findOrCreateOrderAddress(orderDto.getDropAddress(), existingOrder));
        }

        // ---------- FIX STARTS HERE: clear first, then add ----------
        // Clear and repopulate items
        existingOrder.getItems().clear(); // Important: Clear managed collection
        if (orderDto.getItems() != null) {
            for (OrderItemDto dto : orderDto.getItems()) {
                OrderItem item = convertToOrderItem(dto);
                item.setTransportOrder(existingOrder);
                existingOrder.getItems().add(item);
            }
        }

        // Clear and repopulate stops
        existingOrder.getStops().clear(); // Important: Clear managed collection
        if (orderDto.getStops() != null) {
            for (OrderStopDto dto : orderDto.getStops()) {
                OrderStop stop = convertToOrderStop(dto);
                stop.setTransportOrder(existingOrder);
                existingOrder.getStops().add(stop);
            }
        }

        // Final save
        transportOrderValidator.validateForUpdate(existingOrder, id);
        repository.save(existingOrder);

        return ResponseEntity.ok(
                new ApiResponse<>(
                        true, "Order updated successfully", TransportOrderDto.fromEntity(existingOrder)));
    }

    @Transactional
    public ResponseEntity<ApiResponse<String>> deleteOrder(Long id) {
        transportOrderValidator.validateForDeletion(id);
        TransportOrder order = repository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException(ORDER_NOT_FOUND));
        repository.delete(order);
        return ResponseEntity.ok(new ApiResponse<>(true, "Order deleted successfully"));
    }

    @Transactional
    public ResponseEntity<ApiResponse<TransportOrderDto>> updateOrderStatus(
            Long id, OrderStatus status) {
        return repository
                .findById(id)
                .map(
                        order -> {
                            transportOrderValidator.validateStatusTransition(order.getStatus(), status);
                            order.setStatus(status);
                            TransportOrder updatedOrder = repository.save(order);
                            return ResponseEntity.ok(
                                    new ApiResponse<>(
                                            true,
                                            "Order status updated successfully",
                                            TransportOrderDto.fromEntity(updatedOrder)));
                        })
                .orElseThrow(() -> new ResourceNotFoundException(ORDER_NOT_FOUND));
    }

    public ResponseEntity<ApiResponse<List<OrderItem>>> getOrderItems(Long orderId) {
        TransportOrder order = repository
                .findById(orderId)
                .orElseThrow(() -> new ResourceNotFoundException(ORDER_NOT_FOUND));
        return ResponseEntity.ok(new ApiResponse<>(true, "Order items retrieved", order.getItems()));
    }

    public ResponseEntity<ApiResponse<List<CustomerAddress>>> getOrderAddresses(Long orderId) {
        TransportOrder order = repository
                .findById(orderId)
                .orElseThrow(() -> new ResourceNotFoundException(ORDER_NOT_FOUND));
        return ResponseEntity.ok(
                new ApiResponse<>(true, "Order addresses retrieved", order.getPickupAddresses()));
    }

    @Transactional
    public ResponseEntity<ApiResponse<TransportOrderDto>> saveOrder(TransportOrderDto orderDto) {
        TransportOrder order = new TransportOrder();
        String genRef = generateOrderReference(
                orderDto.getDeliveryDate() != null ? orderDto.getDeliveryDate() : LocalDate.now(),
                orderDto.getCourierAssigned(),
                orderDto.getDropAddress() != null ? orderDto.getDropAddress().getCity() : null,
                orderDto.getCustomerName());
        if (!ORDER_REF_PATTERN.matcher(genRef).matches()) {
            throw new IllegalArgumentException(
                    "Generated order_reference does not match standard format: " + genRef);
        }
        order.setOrderReference(genRef);
        order.setCustomer(findCustomerById(orderDto.getCustomerId()));
        order.setCreatedBy(getAuthenticatedUser());
        order.setOrderDate(orderDto.getOrderDate());
        order.setDeliveryDate(orderDto.getDeliveryDate());
        order.setShipmentType(orderDto.getShipmentType());
        order.setBillTo(orderDto.getBillTo());
        order.setCourierAssigned(orderDto.getCourierAssigned());
        order.setStatus(orderDto.getStatus());
        if (orderDto.getOrigin() != null) {
            order.setOrigin(orderDto.getOrigin());
        }
        if (orderDto.getRequiresDriver() != null) {
            order.setRequiresDriver(orderDto.getRequiresDriver());
        }
        if (orderDto.getSourceReference() != null) {
            order.setSourceReference(orderDto.getSourceReference());
        }

        if (orderDto.getPickupAddress() != null) {
            order.setPickupAddress(findOrCreateOrderAddress(orderDto.getPickupAddress(), order));
        }

        if (orderDto.getDropAddress() != null) {
            order.setDropAddress(findOrCreateOrderAddress(orderDto.getDropAddress(), order));
        }

        order = repository.save(order); // Save early to get ID for FK mapping
        final TransportOrder savedOrder = order;

        if (orderDto.getPickupAddresses() != null) {
            List<CustomerAddress> pickupAddresses = orderDto.getPickupAddresses().stream()
                    .map(dto -> findOrCreateOrderAddress(dto, savedOrder))
                    .collect(Collectors.toList());
            orderAddressRepository.saveAll(pickupAddresses);
            savedOrder.setPickupAddresses(pickupAddresses);
        }

        if (orderDto.getDropAddresses() != null) {
            List<CustomerAddress> dropAddresses = orderDto.getDropAddresses().stream()
                    .map(dto -> findOrCreateOrderAddress(dto, savedOrder))
                    .collect(Collectors.toList());
            orderAddressRepository.saveAll(dropAddresses);
            savedOrder.setDropAddresses(dropAddresses);
        }

        if (orderDto.getItems() != null) {
            List<OrderItem> items = orderDto.getItems().stream()
                    .map(
                            dto -> {
                                OrderItem item = convertToOrderItem(dto);
                                item.setTransportOrder(savedOrder);
                                return item;
                            })
                    .collect(Collectors.toList());
            orderItemRepository.saveAll(items);
            savedOrder.setItems(items);
        }

        // Multi-Stop Save Handling
        if (orderDto.getStops() != null && !orderDto.getStops().isEmpty()) {
            List<OrderStop> stops = orderDto.getStops().stream()
                    .map(
                            stopDto -> {
                                OrderStop stop = convertToOrderStop(stopDto);
                                stop.setTransportOrder(savedOrder);
                                return stop;
                            })
                    .collect(Collectors.toList());
            orderStopRepository.saveAll(stops);
            savedOrder.setStops(stops);
        }

        repository.save(savedOrder); // Final save with relationships
        return ResponseEntity.ok(
                new ApiResponse<>(
                        true, "Order saved successfully", TransportOrderDto.fromEntity(savedOrder)));
    }

    private CustomerAddress findOrCreateOrderAddress(CustomerAddressDto dto, TransportOrder order) {
        if (dto.getId() != null) {
            return orderAddressRepository
                    .findById(dto.getId())
                    .orElseThrow(
                            () -> new ResourceNotFoundException(
                                    "Customer Address with ID " + dto.getId() + " not found"));
        }
        CustomerAddress newAddress = convertToCustomerAddress(dto);
        return orderAddressRepository.save(newAddress);
    }

    private String nextSeq(LocalDate date) {
        String prefix = date.format(java.time.format.DateTimeFormatter.ofPattern("yyyyDDD"))
                + "-"; // e.g., 2025256-
        long count = repository.countByOrderReferenceStartingWith(prefix);
        long next = count + 1; // 1-based per prefix
        return String.format("%05d", next);
    }

    private String generateOrderReference(LocalDate date, String route, String dest, String cust) {
        {
            LocalDate d = (date != null) ? date : LocalDate.now();
            String prefix = d.format(java.time.format.DateTimeFormatter.ofPattern("yyyyDDD"));

            // Compute next sequence and ensure uniqueness under contention
            long count = repository.countByOrderReferenceStartingWith(prefix + "-");
            long next = count + 1;
            String ref;
            do {
                String seq = String.format("%05d", next++);
                ref = prefix + "-" + seq;
            } while (repository.existsByOrderReference(ref));

            return ref;
        }
    }

    private User getAuthenticatedUser() {
        Authentication authentication = SecurityContextHolder.getContext().getAuthentication();
        if (authentication == null
                || !authentication.isAuthenticated()
                || "anonymousUser".equals(authentication.getPrincipal())) {
            throw new UsernameNotFoundException("User is not authenticated!");
        }
        return userRepository
                .findByUsername(authentication.getName())
                .orElseThrow(() -> new UsernameNotFoundException("User not found"));
    }

    private Customer findCustomerById(Long customerId) {
        return customerRepository
                .findById(customerId)
                .orElseThrow(() -> new ResourceNotFoundException("Customer not found"));
    }

    private CustomerAddress convertToCustomerAddress(CustomerAddressDto dto) {
        CustomerAddress orderAddress = new CustomerAddress();
        orderAddress.setName(dto.getName());
        orderAddress.setAddress(dto.getAddress());
        orderAddress.setCity(dto.getCity());
        orderAddress.setCountry(dto.getCountry());
        orderAddress.setContactName(dto.getContactName());
        orderAddress.setContactPhone(dto.getContactPhone());
        orderAddress.setLongitude(dto.getLongitude());
        orderAddress.setLatitude(dto.getLatitude());
        orderAddress.setType("DROP");
        return orderAddress;
    }

    @Transactional(readOnly = true)
    public List<TransportOrderDto> searchOrders(String query) {
        return repository
                .findByOrderReferenceContainingIgnoreCaseOrCustomerNameContainingIgnoreCase(query, query)
                .stream()
                .map(TransportOrderDto::fromEntity)
                .collect(Collectors.toList());
    }

    @Transactional(readOnly = true)
    public List<TransportOrderDto> findByCustomerId(Long customerId) {
        return repository.findByCustomerId(customerId).stream()
                .map(TransportOrderDto::fromEntity)
                .toList();
    }

    @Transactional(readOnly = true)
    public List<TransportOrderDto> getUnscheduledOrders() {
        List<OrderStatus> excluded = List.of(
                OrderStatus.SCHEDULED,
                OrderStatus.APPROVED,
                OrderStatus.IN_TRANSIT,
                OrderStatus.COMPLETED,
                OrderStatus.DELIVERED);
        return repository.findUnscheduledOrders(excluded).stream()
                .map(TransportOrderDto::fromEntity)
                .toList();
    }

    @Transactional(readOnly = true)
    public ResponseEntity<ApiResponse<Page<TransportOrderDto>>> filterOrders(
            String query, OrderStatus status, LocalDate fromDate, LocalDate toDate, Pageable pageable) {
        Page<TransportOrder> filteredOrders = repository.filter(query, status, fromDate, toDate, pageable);
        Page<TransportOrderDto> result = mapTransportOrderPage(filteredOrders);
        return ResponseEntity.ok(
                new ApiResponse<>(true, "Filtered orders retrieved successfully", result));
    }

    private OrderStop convertToOrderStop(OrderStopDto dto) {
        if (dto.getAddressId() == null) {
            throw new IllegalArgumentException("❗ Stop addressId must not be null");
        }

        CustomerAddress address = orderAddressRepository
                .findById(dto.getAddressId())
                .orElseThrow(
                        () -> new IllegalArgumentException("❗ Invalid address ID: " + dto.getAddressId()));

        return OrderStop.builder()
                .type(dto.getType())
                .sequence(dto.getSequence())
                .eta(dto.getEta())
                .remarks(dto.getRemarks())
                .contactPhone(dto.getContactPhone())
                .contactName(dto.getContactName())
                .confirmedBy(dto.getConfirmedBy())
                .proofImageUrl(dto.getProofImageUrl())
                .address(address)
                .build();
    }

    private OrderStatus mapStatus(String raw) {
        if (raw == null)
            throw new IllegalArgumentException("Status is required");
        String s = raw.trim().toUpperCase();
        if ("PENDDING".equals(s))
            return OrderStatus.PENDING;
        return OrderStatus.valueOf(s); // throws if invalid
    }

    private void initializeStops(Collection<TransportOrder> orders) {
        if (orders == null || orders.isEmpty()) {
            return;
        }
        for (TransportOrder order : orders) {
            List<OrderStop> stops = order.getStops();
            if (stops == null || stops.isEmpty()) {
                continue;
            }
            stops.size(); // trigger initialization
            for (OrderStop stop : stops) {
                if (stop != null && stop.getAddress() != null) {
                    stop.getAddress().getId();
                }
            }
        }
    }

    private Page<TransportOrderDto> mapTransportOrderPage(Page<TransportOrder> page) {
        List<TransportOrder> orders = page.getContent();
        initializeStops(orders);
        List<TransportOrderDto> dtos = orders.stream().map(TransportOrderDto::fromEntity).collect(Collectors.toList());
        return new PageImpl<>(dtos, page.getPageable(), page.getTotalElements());
    }

    private List<String> validateImportHeaders(Row headerRow) {
        if (headerRow == null) {
            return List.of("Missing header row");
        }

        // Keep compatibility with existing uploads/tests:
        // require the template to expose at least the first 15 columns, but do not enforce names.
        List<String> errors = new ArrayList<>();
        int nonBlankHeaders = 0;
        for (int i = 0; i < REQUIRED_IMPORT_HEADERS.size(); i++) {
            String actual = getCellAsString(headerRow.getCell(i));
            if (!isBlank(actual)) {
                nonBlankHeaders++;
            }
        }
        if (nonBlankHeaders < REQUIRED_IMPORT_HEADERS.size()) {
            errors.add(
                    "Template must include at least "
                            + REQUIRED_IMPORT_HEADERS.size()
                            + " populated header columns (A to O)");
        }

        return errors;
    }

    private boolean isBlank(String value) {
        return value == null || value.trim().isEmpty();
    }

    private String buildGroupKey(String deliveryDate, String customerCode, String toDestination, String tripNo) {
        return (isBlank(deliveryDate) ? "?" : deliveryDate.trim()) + "_"
                + (isBlank(customerCode) ? "?" : customerCode.trim()) + "_"
                + (isBlank(toDestination) ? "?" : toDestination.trim()) + "_"
                + (isBlank(tripNo) ? "?" : tripNo.trim());
    }

    private boolean isImportDataRowEmpty(Row row) {
        if (row == null) {
            return true;
        }
        for (int i = 0; i <= 14; i++) {
            String value = getCellAsString(row.getCell(i));
            if (!isBlank(value)) {
                return false;
            }
        }
        return true;
    }

    @Transactional(rollbackFor = Exception.class)
    public ResponseEntity<ApiResponse<?>> importBulkOrders(MultipartFile file) {
        if (file == null || file.isEmpty()) {
            return ResponseEntity.badRequest()
                    .body(new ApiResponse<>(false, "File is required", null));
        }

        if (file.getSize() > MAX_IMPORT_FILE_BYTES) {
            return ResponseEntity.status(413)
                    .body(new ApiResponse<>(false, "File too large. Max 5 MB per upload", null));
        }

        String contentType = file.getContentType();
        String originalName = file.getOriginalFilename();
        boolean hasXlsxExtension = originalName != null && originalName.toLowerCase().endsWith(".xlsx");
        if (contentType != null
                && !ALLOWED_IMPORT_CONTENT_TYPES.contains(contentType)
                && !"application/octet-stream".equalsIgnoreCase(contentType)
                && !hasXlsxExtension) {
            return ResponseEntity.badRequest()
                    .body(new ApiResponse<>(false, "Only Excel files (.xlsx) are supported", null));
        }

        try (InputStream in = file.getInputStream(); Workbook wb = WorkbookFactory.create(in)) {
            Sheet sheet = wb.getSheetAt(0);
            if (sheet == null) {
                return ResponseEntity.unprocessableEntity()
                        .body(new ApiResponse<>(false, "Missing first sheet in workbook", null));
            }

            int totalRows = sheet.getPhysicalNumberOfRows();
            if (totalRows <= 1) {
                return ResponseEntity.unprocessableEntity()
                        .body(new ApiResponse<>(false, "Sheet is empty. Add at least one data row", null));
            }

            if (totalRows - 1 > MAX_IMPORT_ROWS) {
                return ResponseEntity.badRequest()
                        .body(new ApiResponse<>(false, "Too many rows. Limit 5000 rows per upload", null));
            }

            List<String> headerErrors = validateImportHeaders(sheet.getRow(0));
            if (!headerErrors.isEmpty()) {
                return ResponseEntity.unprocessableEntity()
                        .body(new ApiResponse<>(
                                false,
                                "Invalid template headers. Please use the official template.",
                                headerErrors));
            }

            DateTimeFormatter df = IMPORT_DATE_FORMAT;

            // -------- Parse & group ----------
            int rowIdx = 0;
            Map<String, List<Row>> groups = new LinkedHashMap<>();
            List<ImportError> errors = new ArrayList<>();
            for (Row r : sheet) {
                if (rowIdx++ == 0)
                    continue; // skip header
                if (isImportDataRowEmpty(r))
                    continue; // skip style-only/trailing empty rows
                String d = getCellAsString(r.getCell(0)); // Col 0: DeliveryDate
                String cus = getCellAsString(r.getCell(1)); // Col 1: CustomerCode
                String trip = getCellAsString(r.getCell(5)); // Col 5: TripNo (NOT Col 3 which is TruckTripCount)
                String toDest = getCellAsString(r.getCell(7)); // Col 7: ToDestination
                int excelRow = r.getRowNum() + 1;
                if (isBlank(d)) {
                    errors.add(new ImportError(excelRow, buildGroupKey(d, cus, toDest, trip), "deliveryDate", String.valueOf(d),
                            "Delivery date is required"));
                }
                if (isBlank(cus)) {
                    errors.add(new ImportError(excelRow, buildGroupKey(d, cus, toDest, trip), "customerCode", String.valueOf(cus),
                            "Customer code is required"));
                }
                if (isBlank(toDest)) {
                    errors.add(new ImportError(excelRow, buildGroupKey(d, cus, toDest, trip), "toDestination", String.valueOf(toDest),
                            "Destination is required"));
                }
                if (isBlank(trip)) {
                    errors.add(new ImportError(excelRow, buildGroupKey(d, cus, toDest, trip), "tripNo", String.valueOf(trip),
                            "Trip number is required"));
                }

                if (isBlank(d) || isBlank(cus) || isBlank(toDest) || isBlank(trip)) {
                    continue;
                }
                String key = d + "_" + cus + "_" + toDest + "_" + trip;
                groups.computeIfAbsent(key, k -> new ArrayList<>()).add(r);
            }

            if (groups.isEmpty() && !errors.isEmpty()) {
                String summary = "Import blocked. " + errors.size() + " issue(s) found. Nothing was saved.";
                return ResponseEntity.unprocessableEntity().body(new ApiResponse<>(false, summary, errors));
            }

            // -------- VALIDATION PASS (no writes) ----------
            Set<String> normalizedItemCodes = Set.of();
            Set<String> normalizedVehicles = Set.of();
            Set<String> normalizedAddresses = Set.of();
            Set<String> normalizedCustomers = Set.of();

            // Preload lookups for performance
            Set<String> allItemCodes = Set.of(); // fallback to empty
            Set<String> allVehicles = Set.of();
            Set<String> allAddresses = Set.of();
            Set<String> allCustomers = Set.of();
            Map<String, Item> itemMap = Map.of();
            Map<String, Vehicle> vehicleMap = Map.of();
            Map<String, CustomerAddress> addressMap = Map.of();
            Map<String, Customer> customerMap = Map.of();
            Map<String, Long> itemIdMap = Map.of();
            Map<String, Long> vehicleIdMap = Map.of();
            Map<String, Long> addressIdMap = Map.of();
            Map<String, Long> customerIdMap = Map.of();

            try {
                allItemCodes = itemRepository.findAllItemCodes();
                normalizedItemCodes = allItemCodes.stream().map(this::normalizeKey).filter(Objects::nonNull)
                        .collect(Collectors.toSet());
                itemMap = itemRepository.findAll().stream()
                        .filter(i -> i.getItemCode() != null)
                        .collect(Collectors.toMap(i -> normalizeKey(i.getItemCode()), i -> i, (a, b) -> a));
                itemIdMap = loadNormalizedIdMapFromSql(
                        "select id, item_code from items where item_code is not null");
                normalizedItemCodes = new LinkedHashSet<>(normalizedItemCodes);
                normalizedItemCodes.addAll(itemIdMap.keySet());
            } catch (Exception ex) {
                log.warn("Failed to load item codes, continuing with empty set", ex);
            }

            try {
                allVehicles = vehicleRepository.findAllPlates();
                normalizedVehicles = allVehicles.stream().map(this::normalizeVehiclePlate).filter(Objects::nonNull)
                        .collect(Collectors.toSet());
                vehicleMap = vehicleRepository.findAll().stream()
                        .filter(v -> v.getLicensePlate() != null)
                        .collect(
                                Collectors.toMap(
                                        v -> normalizeVehiclePlate(v.getLicensePlate()), v -> v, (a, b) -> a));
                vehicleIdMap = loadNormalizedVehicleIdMapFromSql(
                        "select id, license_plate from vehicles where license_plate is not null");
                normalizedVehicles = new LinkedHashSet<>(normalizedVehicles);
                normalizedVehicles.addAll(vehicleIdMap.keySet());
            } catch (Exception ex) {
                log.warn("Failed to load vehicle plates, continuing with empty set", ex);
            }

            try {
                allAddresses = orderAddressRepository.findAllNames();
                normalizedAddresses = allAddresses.stream().map(this::normalizeKey).filter(Objects::nonNull)
                        .collect(Collectors.toSet());
                addressMap = orderAddressRepository.findAll().stream()
                        .filter(a -> a.getName() != null)
                        .collect(
                                Collectors.toMap(
                                        a -> normalizeKey(a.getName()), a -> a, (a, b) -> a));
                addressIdMap = loadNormalizedIdMapFromSql(
                        "select id, name from customer_addresses where name is not null");
                normalizedAddresses = new LinkedHashSet<>(normalizedAddresses);
                normalizedAddresses.addAll(addressIdMap.keySet());
            } catch (Exception ex) {
                log.error("Error loading customer addresses: {}", ex.getMessage(), ex);
                return ResponseEntity.status(500)
                        .body(new ApiResponse<>(
                                false,
                                "System error: Unable to load address data. Possible database schema issue. "
                                        + "Contact support: " + ex.getMessage(),
                                null));
            }

            try {
                allCustomers = customerRepository.findAllCodes();
                normalizedCustomers = allCustomers.stream().map(this::normalizeKey).filter(Objects::nonNull)
                        .collect(Collectors.toSet());
                customerMap = customerRepository.findAll().stream()
                        .filter(c -> c.getCustomerCode() != null)
                        .collect(
                                Collectors.toMap(
                                        c -> normalizeKey(c.getCustomerCode()), c -> c, (a, b) -> a));
                customerIdMap = loadNormalizedIdMapFromSql(
                        "select id, customer_code from customers where customer_code is not null and deleted_at is null");
                normalizedCustomers = new LinkedHashSet<>(normalizedCustomers);
                normalizedCustomers.addAll(customerIdMap.keySet());
            } catch (Exception ex) {
                log.warn("Failed to load customer codes, continuing with empty set", ex);
            }

            for (Map.Entry<String, List<Row>> e : groups.entrySet()) {
                int errorsBeforeGroup = errors.size();
                String key = e.getKey();
                Row first = e.getValue().get(0);
                int firstExcelRow = first.getRowNum() + 1;

                // header-level checks
                String deliveryDateStr = getCellAsString(first.getCell(0));
                String customerCode = getCellAsString(first.getCell(1));
                // TrackingNo is cell(2)
                // TruckTripCount is cell(3)
                String truckNumber = getCellAsString(first.getCell(4));
                String tripNo = getCellAsString(first.getCell(5)); // TripNo
                Integer truckTripCount = parseCellAsInteger(first.getCell(3)); // TruckTripCount - robust parsing
                String statusStr = getCellAsString(first.getCell(14));
                String fromDest = getCellAsString(first.getCell(6));
                String toDest = getCellAsString(first.getCell(7));
                String normalizedTruck = normalizeVehiclePlate(truckNumber);
                String normalizedFromDest = normalizeKey(fromDest);
                String normalizedToDest = normalizeKey(toDest);
                boolean vehicleKnown = normalizedVehicles.contains(normalizedTruck)
                        || vehicleMap.containsKey(normalizedTruck)
                        || vehicleIdMap.containsKey(normalizedTruck);
                boolean fromKnown = normalizedAddresses.contains(normalizedFromDest)
                        || addressMap.containsKey(normalizedFromDest)
                        || addressIdMap.containsKey(normalizedFromDest);
                boolean toKnown = normalizedAddresses.contains(normalizedToDest)
                        || addressMap.containsKey(normalizedToDest)
                        || addressIdMap.containsKey(normalizedToDest);

                log.debug(
                        "Import validation lookup: truck={} normalizedTruck={} vehicleKnown={} from={} normalizedFrom={} fromKnown={} to={} normalizedTo={} toKnown={}",
                        truckNumber,
                        normalizedTruck,
                        vehicleKnown,
                        fromDest,
                        normalizedFromDest,
                        fromKnown,
                        toDest,
                        normalizedToDest,
                        toKnown);

                // date
                try {
                    LocalDate.parse(deliveryDateStr, df);
                } catch (Exception ex) {
                    errors.add(
                            new ImportError(
                                    firstExcelRow,
                                    key,
                                    "deliveryDate",
                                    deliveryDateStr,
                                    "Invalid date format dd.MM.yyyy"));
                }

                // customer
                if (isBlank(customerCode) || !normalizedCustomers.contains(normalizeKey(customerCode)))
                    errors.add(
                            new ImportError(
                                    firstExcelRow,
                                    key,
                                    "customerCode",
                                    String.valueOf(customerCode),
                                    "Customer not found"));

                // status
                try {
                    mapStatus(statusStr);
                } catch (Exception ex) {
                    errors.add(new ImportError(firstExcelRow, key, "status", statusStr, "Invalid status"));
                }

                // vehicle
                if (isBlank(truckNumber) || !vehicleKnown)
                    errors.add(
                            new ImportError(
                                    firstExcelRow,
                                    key,
                                    "truckNumber",
                                    String.valueOf(truckNumber),
                                    "Vehicle not found"));

                if (truckTripCount == null || truckTripCount < 0)
                    errors.add(
                            new ImportError(
                                    firstExcelRow,
                                    key,
                                    "truckTripCount",
                                    String.valueOf(truckTripCount),
                                    "Truck trip count must be a whole number"));

                if (tripNo == null || tripNo.trim().isEmpty()) {
                    errors.add(
                            new ImportError(
                                    firstExcelRow,
                                    key,
                                    "tripNo",
                                    String.valueOf(tripNo),
                                    "Trip number is required"));
                }

                // addresses
                if (isBlank(fromDest) || !fromKnown)
                    errors.add(
                            new ImportError(
                                    firstExcelRow,
                                    key,
                                    "fromLocation",
                                    String.valueOf(fromDest),
                                    "Stop address not found"));
                if (isBlank(toDest) || !toKnown)
                    errors.add(
                            new ImportError(
                                    firstExcelRow,
                                    key,
                                    "toLocation",
                                    String.valueOf(toDest),
                                    "Stop address not found"));

                if (errors.size() == errorsBeforeGroup) {
                    try {
                        LocalDate parsedDate = LocalDate.parse(deliveryDateStr, df);
                        String candidateRef = generateOrderReference(parsedDate, truckNumber, toDest, customerCode);
                        if (repository.existsByOrderReference(candidateRef)) {
                            errors.add(
                                    new ImportError(
                                            firstExcelRow,
                                            key,
                                            "orderReference",
                                            candidateRef,
                                            "Order already exists"));
                        }
                    } catch (Exception ignored) {
                        // Parsing issues already captured above
                    }
                }

                // line-level checks
                for (Row r : e.getValue()) {
                    int excelRow = r.getRowNum() + 1;
                    String itemCode = getCellAsString(r.getCell(8));
                    String uom = getCellAsString(r.getCell(11));
                    Double qty = safeNumeric(r.getCell(10));
                    if (isBlank(itemCode) || !normalizedItemCodes.contains(normalizeKey(itemCode))) {
                        errors.add(
                                new ImportError(
                                        excelRow, key, "itemCode", String.valueOf(itemCode), "Item not found"));
                    }
                    if (qty == null || qty <= 0) {
                        errors.add(
                                new ImportError(
                                        excelRow, key, "quantity", String.valueOf(qty), "Quantity must be > 0"));
                    }
                    if (uom == null || uom.isBlank()) {
                        errors.add(
                                new ImportError(
                                        excelRow, key, "uom", String.valueOf(uom), "Unit of measurement is required"));
                    }
                }
            }

            // If any errors: return 422 with a clean message (NO DB writes)
            if (!errors.isEmpty()) {
                String summary = " Import blocked. " + errors.size() + " issue(s) found. Nothing was saved.";
                return ResponseEntity.unprocessableEntity().body(new ApiResponse<>(false, summary, errors));
            }

            Map<String, VehicleDriver> activeVehicleDriverByPlate = buildActiveVehicleDriverByPlateMap();
            int autoAssignedCount = 0;
            int unassignedCount = 0;
            // -------- PERSIST PASS ----------
            int created = 0;
            log.info("Starting persist pass for {} group(s)", groups.size());
            for (Map.Entry<String, List<Row>> e : groups.entrySet()) {
                List<Row> rows = e.getValue();
                Row first = rows.get(0);
                log.debug("Processing group: {} with {} rows", e.getKey(), rows.size());

                String deliveryDateStr = getCellAsString(first.getCell(0));
                String customerCode = getCellAsString(first.getCell(1));

                String trackingNo = getCellAsString(first.getCell(2));
                Integer truckTripCount = parseCellAsInteger(first.getCell(3));
                if (truckTripCount == null) {
                    throw new IllegalStateException("Missing truckTripCount after validation for key: " + e.getKey());
                }
                String truckNumber = getCellAsString(first.getCell(4));

                String tripNo = getCellAsString(first.getCell(5));

                String fromDest = getCellAsString(first.getCell(6));
                String toDest = getCellAsString(first.getCell(7));
                String statusStr = getCellAsString(first.getCell(14));
                LocalDate deliveryDate = LocalDate.parse(deliveryDateStr, df);

                Customer customer = customerMap.get(normalizeKey(customerCode));
                if (customer == null) {
                    Long customerId = customerIdMap.get(normalizeKey(customerCode));
                    if (customerId != null) {
                        customer = entityManager.getReference(Customer.class, customerId);
                    }
                }
                if (customer == null) {
                    throw new IllegalStateException("Customer not found after validation: " + customerCode);
                }
                OrderStatus status = mapStatus(statusStr);
                Vehicle vehicle = vehicleMap.get(normalizeVehiclePlate(truckNumber));
                if (vehicle == null) {
                    Long vehicleId = vehicleIdMap.get(normalizeVehiclePlate(truckNumber));
                    if (vehicleId != null) {
                        vehicle = entityManager.getReference(Vehicle.class, vehicleId);
                    }
                }
                if (vehicle == null) {
                    throw new IllegalStateException("Vehicle not found after validation: " + truckNumber);
                }
                String canonicalTruckNumber = vehicle.getLicensePlate();
                String orderRef = generateOrderReference(deliveryDate, canonicalTruckNumber, toDest, customerCode);
                if (!ORDER_REF_PATTERN.matcher(orderRef).matches()) {
                    throw new IllegalArgumentException(
                            "Generated order_reference does not match standard format: " + orderRef);
                }

                TransportOrder order = new TransportOrder();
                order.setOrderReference(orderRef);
                order.setCustomer(customer);
                order.setCreatedBy(getAuthenticatedUser());
                order.setOrderDate(LocalDate.now());
                order.setDeliveryDate(deliveryDate);
                order.setTripNo(tripNo);
                order.setTruckNumber(canonicalTruckNumber);
                order.setTruckTripCount(truckTripCount);
                order.setStatus(status);
                order.setOrigin(OrderOrigin.IMPORT);
                // Allow spreadsheet to indicate whether a driver is required (col index 15)
                String requiresDriverCell = getCellAsString(first.getCell(15));
                if (requiresDriverCell != null && "FALSE".equalsIgnoreCase(requiresDriverCell.trim())) {
                    order.setRequiresDriver(Boolean.FALSE);
                } else {
                    order.setRequiresDriver(Boolean.TRUE);
                }
                repository.save(order);
                repository.flush(); // Ensure ID is generated before using in dispatch

                Dispatch dispatch = Dispatch.builder()
                        .routeCode(orderRef)
                        .trackingNo(trackingNo)
                        .truckTrip(tripNo)
                        .fromLocation(fromDest)
                        .toLocation(toDest)
                        .deliveryDate(deliveryDate)
                        .customer(customer)
                        .status(DispatchStatus.PENDING)
                        .createdBy(null) // TEMP: Set to null for debugging
                        .startTime(deliveryDate.atStartOfDay())
                        .createdDate(java.time.LocalDateTime.now())
                        .updatedDate(java.time.LocalDateTime.now())
                        .build();

                dispatch.setLoadingTypeCode(DispatchWorkflowPolicyService.DEFAULT_TEMPLATE_CODE);
                dispatch.setWorkflowVersionId(
                        dispatchWorkflowPolicyService.resolveWorkflowVersionIdForDispatch(dispatch));

                dispatch.setVehicle(vehicle);
                VehicleDriver activeAssignment = activeVehicleDriverByPlate.get(normalizeVehiclePlate(canonicalTruckNumber));
                if (activeAssignment != null && activeAssignment.getDriver() != null) {
                    dispatch.setDriver(activeAssignment.getDriver());
                    dispatch.setStatus(DispatchStatus.ASSIGNED);
                    autoAssignedCount++;
                } else {
                    unassignedCount++;
                }

                dispatch.setTransportOrder(order);
                dispatchRepository.save(dispatch);

                // items
                for (Row r : rows) {
                    String itemCode = getCellAsString(r.getCell(8));
                    Double qtyVal = safeNumeric(r.getCell(10));
                    double qty = qtyVal != null ? qtyVal : 0;
                    String uom = getCellAsString(r.getCell(11));
                    Double palletVal = safeNumeric(r.getCell(12));
                    double pallet = palletVal != null ? palletVal : 0;
                    String fromRow = getCellAsString(r.getCell(6));
                    String toRow = getCellAsString(r.getCell(7));
                    String wh = getCellAsString(r.getCell(13));

                    Item item = itemMap.get(normalizeKey(itemCode));
                    if (item == null) {
                        Long itemId = itemIdMap.get(normalizeKey(itemCode));
                        if (itemId != null) {
                            item = entityManager.getReference(Item.class, itemId);
                        }
                    }
                    if (item == null) {
                        throw new IllegalStateException("Item not found after validation: " + itemCode);
                    }
                    OrderItem oi = new OrderItem();
                    oi.setItem(item);
                    oi.setQuantity(qty);
                    oi.setWeight(0);
                    oi.setUnitOfMeasurement(uom);
                    oi.setPalletType(pallet);
                    oi.setFromDestination(fromRow);
                    oi.setToDestination(toRow);
                    oi.setWarehouse(wh);
                    oi.setTransportOrder(order);
                    orderItemRepository.save(oi);
                }

                // stops
                Set<String> dedup = new HashSet<>();
                List<OrderStop> stops = new ArrayList<>();
                for (String stopName : List.of(fromDest, toDest)) {
                    String key = order.getId() + "-" + stopName;
                    if (dedup.add(key)) {
                        CustomerAddress addr = addressMap.get(normalizeKey(stopName));
                        if (addr == null) {
                            Long addressId = addressIdMap.get(normalizeKey(stopName));
                            if (addressId != null) {
                                addr = entityManager.getReference(CustomerAddress.class, addressId);
                            }
                        }
                        if (addr == null) {
                            throw new IllegalStateException("Address not found after validation: " + stopName);
                        }
                        stops.add(
                                OrderStop.builder()
                                        .type(stops.isEmpty() ? StopType.PICKUP : StopType.DROP)
                                        .sequence(stops.size() + 1)
                                        .address(addr)
                                        .transportOrder(order)
                                        .build());
                    }
                }
                if (!stops.isEmpty())
                    orderStopRepository.saveAll(stops);

                created++;
            }

            int duplicateAssignmentWarnings = logDuplicateActiveAssignmentWarnings(activeVehicleDriverByPlate);
            log.info("Successfully persisted {} order(s)", created);
            log.info(
                    "Bulk order import summary: groups={}, created={}, autoAssigned={}, unassigned={}, duplicateActivePlateWarnings={}",
                    groups.size(),
                    created,
                    autoAssignedCount,
                    unassignedCount,
                    duplicateAssignmentWarnings);
            String msg = " Imported " + created + " order(s).";
            return ResponseEntity.ok(new ApiResponse<>(true, msg, null));

        } catch (Exception ex) {
            String errorMsg = "Bulk import failed";
            String details = ex.getMessage();

            // Provide more specific error messages based on exception type
            if (ex instanceof org.springframework.orm.jpa.JpaSystemException) {
                errorMsg = "System error: Database schema issue while loading entity data";
                details = "Unable to deserialize database records. " +
                        "This may indicate corrupted data or schema mismatch. " +
                        "Please contact support with the following details: " + details;
            } else if (ex instanceof IllegalStateException) {
                errorMsg = "Import blocked: referenced data missing after validation";
                details = "Validation passed but a referenced entity (customer, vehicle, item, address) " +
                        "was missing when saving. Details: " + details;
                log.error("Bulk import validation drift: {}", details);
                return ResponseEntity.unprocessableEntity()
                        .body(new ApiResponse<>(false, errorMsg, List.of(details)));
            } else if (ex instanceof java.util.NoSuchElementException) {
                errorMsg = "System error: Missing required entity during import";
                details = "One or more referenced entities (customer, vehicle, item, address) " +
                        "could not be found. Check that all related records exist before importing. " +
                        "Details: " + details;
            } else if (ex instanceof jakarta.persistence.EntityNotFoundException) {
                errorMsg = "System error: Entity not found";
                details = "A referenced entity could not be loaded. Details: " + details;
            } else if (ex instanceof org.springframework.dao.DataIntegrityViolationException) {
                errorMsg = "System error: Data constraint violation";
                details = "The imported data violates database constraints (e.g., duplicate key). " +
                        "Details: " + details;
            } else if (ex instanceof java.io.IOException) {
                errorMsg = "File read error";
                details = "Failed to read the Excel file. Ensure the file is valid and not corrupted. " +
                        "Details: " + details;
            }

            log.error("Bulk import failed: {}", errorMsg, ex);
            // Any exception here triggers TX rollback automatically due to @Transactional
            return ResponseEntity.status(500)
                    .body(new ApiResponse<>(false, errorMsg, details));
        }
    }

    private Double safeNumeric(Cell c) {
        try {
            if (c == null) {
                return null;
            }
            if (c.getCellType() == org.apache.poi.ss.usermodel.CellType.NUMERIC) {
                return c.getNumericCellValue();
            }
            String raw = getCellAsString(c);
            if (raw == null || raw.isBlank()) {
                return null;
            }
            return Double.parseDouble(raw.trim().replace(",", ""));
        } catch (Exception e) {
            return null;
        }
    }

    private Integer parseInteger(String raw) {
        try {
            if (raw == null || raw.isBlank())
                return null;
            return Integer.parseInt(raw.trim());
        } catch (NumberFormatException ex) {
            return null;
        }
    }

    private Integer parseCellAsInteger(Cell cell) {
        if (cell == null)
            return null;
        try {
            return switch (cell.getCellType()) {
                case NUMERIC -> (int) cell.getNumericCellValue();
                case STRING -> Integer.parseInt(cell.getStringCellValue().trim().replace(",", ""));
                case FORMULA -> {
                    String value = EXCEL_FORMATTER.formatCellValue(cell);
                    if (value == null || value.isBlank()) {
                        yield null;
                    }
                    yield (int) Math.floor(Double.parseDouble(value.trim().replace(",", "")));
                }
                default -> null;
            };
        } catch (Exception ex) {
            return null;
        }
    }

    private String getCellAsString(Cell cell) {
        if (cell == null)
            return null;
        try {
            if (cell.getCellType() == org.apache.poi.ss.usermodel.CellType.NUMERIC && DateUtil.isCellDateFormatted(cell)) {
                return cell.getLocalDateTimeCellValue().toLocalDate().format(IMPORT_DATE_FORMAT);
            }
        } catch (Exception ex) {
            log.debug("Failed to parse date-formatted cell at row={}, col={}", cell.getRowIndex(), cell.getColumnIndex(), ex);
        }
        String value = EXCEL_FORMATTER.formatCellValue(cell);
        if (value == null) {
            return null;
        }
        String trimmed = value.trim();
        return trimmed.isEmpty() ? null : trimmed;
    }

    private OrderItem convertToOrderItem(OrderItemDto dto) {
        OrderItem orderItem = new OrderItem();

        // --- Begin item relation lookup and assignment ---
        Item resolvedItem = null;
        if (dto.getItemId() != null) {
            resolvedItem = itemRepository
                    .findById(dto.getItemId())
                    .orElseThrow(
                            () -> new ResourceNotFoundException("Item not found: id=" + dto.getItemId()));
        } else if (dto.getItemCode() != null && !dto.getItemCode().isBlank()) {
            resolvedItem = itemRepository
                    .findByItemCode(dto.getItemCode())
                    .orElseThrow(
                            () -> new ResourceNotFoundException("Item not found: code=" + dto.getItemCode()));
        }
        if (resolvedItem != null) {
            orderItem.setItem(resolvedItem);
        }
        // --- End item relation lookup and assignment ---

        orderItem.setQuantity(dto.getQuantity());
        // --- Begin unitOfMeasurement fallback logic ---
        if ((dto.getUnitOfMeasurement() == null || dto.getUnitOfMeasurement().isBlank())
                && resolvedItem != null) {
            orderItem.setUnitOfMeasurement(resolvedItem.getUnit());
        } else {
            orderItem.setUnitOfMeasurement(dto.getUnitOfMeasurement());
        }
        // --- End unitOfMeasurement fallback logic ---
        orderItem.setPalletType(dto.getPalletType());
        orderItem.setDimensions(dto.getDimensions());
        orderItem.setWeight(dto.getWeight());
        orderItem.setFromDestination(dto.getFromDestination());
        orderItem.setToDestination(dto.getToDestination());
        orderItem.setWarehouse(dto.getWarehouse());
        orderItem.setDepartment(dto.getDepartment());

        if (dto.getPickupAddress() != null) {
            orderItem.setPickupAddress(findOrCreateOrderAddress(dto.getPickupAddress(), null));
        }
        if (dto.getDropAddress() != null) {
            orderItem.setDropAddress(findOrCreateOrderAddress(dto.getDropAddress(), null));
        }

        return orderItem;
    }
}
