package com.svtrucking.logistics.repository;

import com.svtrucking.logistics.model.TaskTag;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface TaskTagRepository extends JpaRepository<TaskTag, Long> {

  // Find by name
  Optional<TaskTag> findByNameIgnoreCase(String name);

  // Find active tags
  List<TaskTag> findByIsActiveTrueOrderByNameAsc();

  // Find by category
  List<TaskTag> findByCategoryAndIsActiveTrueOrderByNameAsc(String category);

  // Find all by category
  List<TaskTag> findByCategoryOrderByNameAsc(String category);

  // Search by name
  List<TaskTag> findByNameContainingIgnoreCaseAndIsActiveTrue(String name);

  // Check if tag exists
  boolean existsByNameIgnoreCase(String name);
}
