package com.svtrucking.logistics.repository;

import com.svtrucking.logistics.entity.Banner;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.stereotype.Repository;

import java.time.LocalDateTime;
import java.util.List;

@Repository
public interface BannerRepository extends JpaRepository<Banner, Long> {

    /**
     * Find all active banners within the valid date range, ordered by display order
     */
    @Query("SELECT b FROM Banner b WHERE b.active = true " +
           "AND b.startDate <= :now " +
           "AND b.endDate >= :now " +
           "ORDER BY b.displayOrder ASC, b.createdAt DESC")
    List<Banner> findActiveBanners(LocalDateTime now);

    /**
     * Find banners by category
     */
    List<Banner> findByCategoryOrderByDisplayOrderAsc(String category);

    /**
     * Find all banners ordered by display order
     */
    List<Banner> findAllByOrderByDisplayOrderAscCreatedAtDesc();

    /**
     * Find active banners by category within date range
     */
    @Query("SELECT b FROM Banner b WHERE b.active = true " +
           "AND b.category = :category " +
           "AND b.startDate <= :now " +
           "AND b.endDate >= :now " +
           "ORDER BY b.displayOrder ASC")
    List<Banner> findActiveBannersByCategory(String category, LocalDateTime now);
}
