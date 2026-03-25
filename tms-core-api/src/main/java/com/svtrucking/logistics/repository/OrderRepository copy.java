// package com.svtrucking.logistics.repository;

// import com.svtrucking.logistics.model.Dispatch;
// import com.svtrucking.logistics.enums.DispatchStatus;
// import org.springframework.data.domain.Page;
// import org.springframework.data.domain.Pageable;
// import org.springframework.data.jpa.repository.JpaRepository;
// import org.springframework.stereotype.Repository;
// import java.time.LocalDateTime;
// import java.util.List;

// @Repository
// public interface DispatchRepository extends JpaRepository<Dispatch, Long> {

//     //  Search Dispatch by Driver ID
//     Page<Dispatch> findByDriver_Id(Long driverId, Pageable pageable);

//     //  Search Dispatch by Vehicle ID
//     Page<Dispatch> findByVehicle_Id(Long vehicleId, Pageable pageable);

//     //  Search Dispatch by Status
//     Page<Dispatch> findByStatus(DispatchStatus status, Pageable pageable);

//     //  Search Dispatch by Start Time Range
//     Page<Dispatch> findByStartTimeBetween(LocalDateTime start, LocalDateTime end, Pageable
// pageable);

//     //  Search by multiple criteria
//     Page<Dispatch> findByDriver_IdAndStatus(Long driverId, DispatchStatus status, Pageable
// pageable);

//     //  Search by Route Code (Exact Match)
//     Dispatch findByRouteCode(String routeCode);
// }
