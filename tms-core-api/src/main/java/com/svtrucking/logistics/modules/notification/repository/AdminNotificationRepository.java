package com.svtrucking.logistics.modules.notification.repository;

import com.svtrucking.logistics.modules.notification.model.AdminNotification;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.stereotype.Repository;

@Repository
public interface AdminNotificationRepository extends JpaRepository<AdminNotification, Long> {

  /** 🔢 Count unread notifications using JPQL */
  @Query("SELECT COUNT(a) FROM AdminNotification a WHERE a.isRead = false")
  long countUnread();

  /** 🔢 Count unread notifications using derived query */
  long countByIsReadFalse();

  /** Mark all admin notifications as read */
  @Modifying
  @Query("UPDATE AdminNotification n SET n.isRead = true")
  void markAllAsRead();
}
