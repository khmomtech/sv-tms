package com.svtrucking.logistics.model;

import com.svtrucking.logistics.enums.DispatchStatus;
import com.svtrucking.logistics.enums.DispatchStatusChangeSource;
import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.ManyToOne;
import jakarta.persistence.Table;
import java.time.LocalDateTime;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;
import jakarta.persistence.FetchType;

@Setter
@Getter
@Entity
@Table(name = "dispatch_status_history")
@Data
@NoArgsConstructor
@AllArgsConstructor
public class DispatchStatusHistory {

  @Id
  @GeneratedValue(strategy = GenerationType.IDENTITY)
  private Long id;

  @ManyToOne(fetch = FetchType.LAZY)
  @JoinColumn(name = "dispatch_id", nullable = false)
  private Dispatch dispatch;

  @Enumerated(EnumType.STRING)
  private DispatchStatus status;

  private String updatedBy;

  private Long actorUserId;

  private String actorRolesSnapshot;

  @Enumerated(EnumType.STRING)
  private DispatchStatusChangeSource source;

  private String overrideReason;

  private String remarks;

  private LocalDateTime updatedAt;
}
