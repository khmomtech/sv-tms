package com.svtrucking.logistics.repository;

import com.svtrucking.logistics.entity.HomeLayoutSection;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

/**
 * Repository for managing home screen layout sections
 */
@Repository
public interface HomeLayoutSectionRepository extends JpaRepository<HomeLayoutSection, Long> {

    /**
     * Find section by unique key
     */
    Optional<HomeLayoutSection> findBySectionKey(String sectionKey);

    /**
     * Find all visible sections ordered by display_order
     */
    List<HomeLayoutSection> findByVisibleTrueOrderByDisplayOrderAsc();

    /**
     * Find all sections ordered by display_order
     */
    List<HomeLayoutSection> findAllByOrderByDisplayOrderAsc();

    /**
     * Find sections by category
     */
    List<HomeLayoutSection> findByCategoryOrderByDisplayOrderAsc(String category);

    /**
     * Check if section key exists
     */
    boolean existsBySectionKey(String sectionKey);
}
