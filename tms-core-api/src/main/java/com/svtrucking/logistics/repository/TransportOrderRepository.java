package com.svtrucking.logistics.repository;

import com.svtrucking.logistics.dto.DashboardSummaryDto;
import com.svtrucking.logistics.dto.LoadingSummaryRowDto;
import com.svtrucking.logistics.enums.OrderStatus;
import com.svtrucking.logistics.model.TransportOrder;
import java.time.LocalDate;
import java.util.List;
import java.util.Optional;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.EntityGraph;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

@Repository
public interface TransportOrderRepository extends JpaRepository<TransportOrder, Long> {

  Optional<TransportOrder> findByOrderReferenceIgnoreCase(String orderReference);

    // Eagerly load customer to avoid LazyInitializationException in public tracking
    @Query(
      "SELECT o FROM TransportOrder o LEFT JOIN FETCH o.customer "
        + "WHERE LOWER(o.orderReference) = LOWER(:orderReference)")
    Optional<TransportOrder> findWithCustomerByOrderReferenceIgnoreCase(
      @Param("orderReference") String orderReference);

  @Query("SELECT COUNT(t) FROM TransportOrder t WHERE FUNCTION('date', t.createdAt) = CURRENT_DATE")
  int countTodayOrders();

  Page<TransportOrder> findByOrderReferenceContainingOrCustomerNameContainingIgnoreCase(
      String orderReference, String customerName, Pageable pageable);

  List<TransportOrder> findByOrderReferenceContainingIgnoreCaseOrCustomerNameContainingIgnoreCase(
      String orderReference, String customerName);

  Page<TransportOrder> findByStatus(OrderStatus status, Pageable pageable);

  Page<TransportOrder> findByOrderDateBetween(
      LocalDate startDate, LocalDate endDate, Pageable pageable);

  List<TransportOrder> findByCustomerId(Long customerId);

  @EntityGraph(attributePaths = {"stops", "stops.address"})
  @Query(
      """
                SELECT o FROM TransportOrder o
                WHERE (:query IS NULL OR LOWER(o.orderReference) LIKE LOWER(CONCAT('%', :query, '%'))
                    OR LOWER(o.customer.name) LIKE LOWER(CONCAT('%', :query, '%')))
                  AND (:status IS NULL OR o.status = :status)
                  AND (:fromDate IS NULL OR o.orderDate >= :fromDate)
                  AND (:toDate IS NULL OR o.orderDate <= :toDate)
            """)
  Page<TransportOrder> filter(
      @Param("query") String query,
      @Param("status") OrderStatus status,
      @Param("fromDate") LocalDate fromDate,
      @Param("toDate") LocalDate toDate,
      Pageable pageable);

  @Query("SELECT t FROM TransportOrder t WHERE t.status NOT IN (:excluded)")
  List<TransportOrder> findUnscheduledOrders(@Param("excluded") List<OrderStatus> excluded);

  @Query(
      "SELECT DISTINCT t.shipmentType FROM TransportOrder t "
          + "WHERE t.shipmentType IS NOT NULL AND TRIM(t.shipmentType) <> '' "
          + "ORDER BY t.shipmentType")
  List<String> findDistinctShipmentTypes();

  @Query(
      "SELECT COUNT(t) FROM TransportOrder t WHERE t.status = com.svtrucking.logistics.enums.OrderStatus.DELIVERED AND FUNCTION('date', t.createdAt) = CURRENT_DATE")
  int countTodayDelivered();

  boolean existsByOrderReference(String orderRef);

  boolean existsByOrderReferenceIgnoreCase(String orderRef);
  
  boolean existsByOrderReferenceAndIdNot(String orderRef, Long id);

  long countByOrderReferenceStartingWith(String prefix);

  @Query(
      """
            SELECT new com.svtrucking.logistics.dto.DashboardSummaryDto(
                COUNT(t),
                SUM(CASE WHEN t.status = com.svtrucking.logistics.enums.OrderStatus.PENDING THEN 1 ELSE 0 END),
                SUM(CASE WHEN t.status = com.svtrucking.logistics.enums.OrderStatus.IN_TRANSIT THEN 1 ELSE 0 END),
                SUM(CASE WHEN t.status = com.svtrucking.logistics.enums.OrderStatus.COMPLETED THEN 1 ELSE 0 END),
                SUM(CASE WHEN t.status = com.svtrucking.logistics.enums.OrderStatus.CANCELLED THEN 1 ELSE 0 END),
                SUM(CASE WHEN t.orderDate = CURRENT_DATE THEN 1 ELSE 0 END),
                SUM(CASE WHEN t.deliveryDate = CURRENT_DATE THEN 1 ELSE 0 END)
            )
            FROM TransportOrder t
            WHERE (:fromDate IS NULL OR t.deliveryDate >= :fromDate)
              AND (:toDate IS NULL OR t.deliveryDate <= :toDate)
            """)
  DashboardSummaryDto getDashboardSummary(
      @Param("fromDate") LocalDate fromDate, @Param("toDate") LocalDate toDate);

  @Query(
      """
  SELECT new com.svtrucking.logistics.dto.LoadingSummaryRowDto(
    t.customer.name,
    s.address.name,
    COUNT(DISTINCT t.id),

    SUM(CASE WHEN t.status IN (
    com.svtrucking.logistics.enums.OrderStatus.LOADED,
com.svtrucking.logistics.enums.OrderStatus.IN_TRANSIT,
com.svtrucking.logistics.enums.OrderStatus.ARRIVED_UNLOADING,
com.svtrucking.logistics.enums.OrderStatus.UNLOADING,
com.svtrucking.logistics.enums.OrderStatus.UNLOADED,
com.svtrucking.logistics.enums.OrderStatus.DELIVERED,
com.svtrucking.logistics.enums.OrderStatus.COMPLETED,
com.svtrucking.logistics.enums.OrderStatus.CANCELLED
    ) THEN 1 ELSE 0 END),

    SUM(CASE WHEN t.status IN (
com.svtrucking.logistics.enums.OrderStatus.PENDING,
com.svtrucking.logistics.enums.OrderStatus.ASSIGNED,
com.svtrucking.logistics.enums.OrderStatus.DRIVER_CONFIRMED,
com.svtrucking.logistics.enums.OrderStatus.APPROVED,
com.svtrucking.logistics.enums.OrderStatus.REJECTED,
com.svtrucking.logistics.enums.OrderStatus.SCHEDULED,
com.svtrucking.logistics.enums.OrderStatus.ARRIVED_LOADING,
com.svtrucking.logistics.enums.OrderStatus.LOADING
    ) THEN 1 ELSE 0 END),


    SUM(CASE WHEN t.status IN (
     com.svtrucking.logistics.enums.OrderStatus.ARRIVED_LOADING,
com.svtrucking.logistics.enums.OrderStatus.LOADING
    ) THEN 1 ELSE 0 END),


  SUM(CASE WHEN t.status IN (
     com.svtrucking.logistics.enums.OrderStatus.ARRIVED_LOADING
    ) THEN 1 ELSE 0 END),

    SUM(CASE WHEN t.status IN (
com.svtrucking.logistics.enums.OrderStatus.PENDING,
com.svtrucking.logistics.enums.OrderStatus.ASSIGNED,
com.svtrucking.logistics.enums.OrderStatus.DRIVER_CONFIRMED,
com.svtrucking.logistics.enums.OrderStatus.APPROVED,
com.svtrucking.logistics.enums.OrderStatus.REJECTED,
com.svtrucking.logistics.enums.OrderStatus.SCHEDULED
    ) THEN 1 ELSE 0 END),


    CASE WHEN COUNT(DISTINCT t.id) > 0 THEN (
      SUM(CASE WHEN t.status IN (
        com.svtrucking.logistics.enums.OrderStatus.LOADED,
com.svtrucking.logistics.enums.OrderStatus.IN_TRANSIT,
com.svtrucking.logistics.enums.OrderStatus.ARRIVED_UNLOADING,
com.svtrucking.logistics.enums.OrderStatus.UNLOADING,
com.svtrucking.logistics.enums.OrderStatus.UNLOADED,
com.svtrucking.logistics.enums.OrderStatus.DELIVERED,
com.svtrucking.logistics.enums.OrderStatus.COMPLETED,
com.svtrucking.logistics.enums.OrderStatus.CANCELLED
      ) THEN 1 ELSE 0 END) * 100.0 / COUNT(DISTINCT t.id)
    ) ELSE 0 END
  )
  FROM TransportOrder t
  JOIN OrderStop s ON s.transportOrder = t AND s.type = com.svtrucking.logistics.enums.StopType.DROP
  LEFT JOIN Dispatch d ON d.transportOrder = t
  LEFT JOIN d.vehicle v
  WHERE (:fromDate IS NULL OR t.deliveryDate >= :fromDate)
    AND (:toDate   IS NULL OR t.deliveryDate <= :toDate)
    AND (:customerName IS NULL OR LOWER(t.customer.name) LIKE LOWER(CONCAT('%', :customerName, '%')))
    AND (:truckType IS NULL OR v.type = :truckType)
    AND s.sequence = (
      SELECT MIN(s2.sequence)
      FROM OrderStop s2
      WHERE s2.transportOrder = t AND s2.type = com.svtrucking.logistics.enums.StopType.DROP
    )
  GROUP BY t.customer.name, s.address.name
""")
  List<LoadingSummaryRowDto> getLoadingSummary(
      @Param("fromDate") LocalDate fromDate,
      @Param("toDate") LocalDate toDate,
      @Param("customerName") String customerName,
      @Param("truckType") String truckType);
}
