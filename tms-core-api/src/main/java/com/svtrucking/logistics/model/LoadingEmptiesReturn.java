package com.svtrucking.logistics.model;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.FetchType;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.Index;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.ManyToOne;
import jakarta.persistence.Table;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

import java.time.LocalDateTime;

@Getter
@Setter
@Entity
@Table(
    name = "loading_empties_return",
    indexes = {
        @Index(name = "idx_loading_empties_session", columnList = "loading_session_id")
    }
)
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class LoadingEmptiesReturn {

  @Id
  @GeneratedValue(strategy = GenerationType.IDENTITY)
  private Long id;

  @ManyToOne(fetch = FetchType.LAZY, optional = false)
  @JoinColumn(name = "loading_session_id", nullable = false)
  private LoadingSession loadingSession;

  @Column(name = "item_name", length = 128, nullable = false)
  private String itemName;

  @Column(name = "quantity", nullable = false)
  private Integer quantity;

  @Column(name = "unit", length = 32)
  private String unit;

  @Column(name = "condition_note", length = 255)
  private String conditionNote;

  @Column(name = "recorded_at")
  private LocalDateTime recordedAt;
}
