// package com.svtrucking.logistics.repository;

// import org.springframework.data.domain.Page;
// import org.springframework.data.domain.Pageable;
// import org.springframework.data.jpa.repository.JpaRepository;
// import org.springframework.data.jpa.repository.Modifying;
// import org.springframework.data.jpa.repository.Query;
// import org.springframework.data.repository.query.Param;

// import com.svtrucking.logistics.modules.notification.model.DriverNotification;

// import java.util.List;

// public interface DriverNotificationRepository extends JpaRepository<DriverNotification, Long> {

//     /**
//      *  Get all DriverNotifications for a driver, sorted by newest first
//      */
//     List<DriverNotification> findByDriverIdOrderByCreatedAtDesc(Long driverId);

//     /**
//      *  Paginated DriverNotifications for a driver
//      */
//     Page<DriverNotification> findByDriverIdOrderByCreatedAtDesc(Long driverId, Pageable
// pageable);

//     /**
//      *  Get unread DriverNotifications only
//      */
//     List<DriverNotification> findByDriverIdAndIsReadFalseOrderByCreatedAtDesc(Long driverId);

//     /**
//      *  Count unread DriverNotifications
//      */
//     long countByDriverIdAndIsReadFalse(Long driverId);

//     /**
//      *  Delete all DriverNotifications for a driver
//      */
//     void deleteByDriverId(Long driverId);

//     @Modifying
//     @Query("UPDATE DriverNotification n SET n.isRead = true WHERE n.driverId = :driverId AND
// n.isRead = false")
//     void markAllAsReadByDriver(@Param("driverId") Long driverId);

//     /**
//      *  Delete DriverNotifications older than X days (optional cleanup method)
//      * You can implement this with a `@Modifying` query if needed.
//      */
//     // @Modifying
//     // @Query("DELETE FROM DriverNotification n WHERE n.createdAt < :cutoff")
//     // void deleteOlderThan(@Param("cutoff") LocalDateTime cutoff);

// }
