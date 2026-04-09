package com.svtrucking.logistics.model;

import jakarta.persistence.*;
import lombok.*;

/**
 * Task Tag Definition - reusable labels for tasks
 */
@Entity
@Table(name = "task_tag_definitions", indexes = {
    @Index(name = "idx_tag_name", columnList = "name"),
    @Index(name = "idx_tag_category", columnList = "category")
})
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class TaskTag {

  @Id
  @GeneratedValue(strategy = GenerationType.IDENTITY)
  private Long id;

  @Column(nullable = false, unique = true, length = 50)
  private String name;

  @Column(length = 7)
  private String color; // Hex color like "#FF5733"

  @Column(length = 50)
  private String category; // "department", "priority", "type", "custom"

  @Column(length = 500)
  private String description;

  @Column(name = "is_active")
  @Builder.Default
  private Boolean isActive = true;
}
