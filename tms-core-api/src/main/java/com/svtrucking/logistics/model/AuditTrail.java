package com.svtrucking.logistics.model;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import java.time.LocalDateTime;
import lombok.AllArgsConstructor;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

@Entity
@Table(name = "audit_trails")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
public class AuditTrail {

  @Id
  @GeneratedValue(strategy = GenerationType.IDENTITY)
  private Long id;

  @Column(name = "user_id")
  private Long userId;

  @Column(name = "username")
  private String username;

  @Column(name = "action")
  private String action;

  @Column(name = "resource_type")
  private String resourceType;

  @Column(name = "resource_id")
  private Long resourceId;

  @Column(name = "resource_name")
  private String resourceName;

  @Column(name = "timestamp")
  private LocalDateTime timestamp;

  @Column(name = "details", length = 1000)
  private String details;

  @Column(name = "ip_address")
  private String ipAddress;

  @Column(name = "user_agent", length = 500)
  private String userAgent;
}
