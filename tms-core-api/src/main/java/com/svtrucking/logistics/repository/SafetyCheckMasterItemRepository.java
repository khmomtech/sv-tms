package com.svtrucking.logistics.repository;

import com.svtrucking.logistics.model.SafetyCheckMasterItem;
import java.util.List;
import java.util.Optional;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.EntityGraph;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

public interface SafetyCheckMasterItemRepository extends JpaRepository<SafetyCheckMasterItem, Long> {
  @EntityGraph(attributePaths = {"category"})
  List<SafetyCheckMasterItem> findByIsActiveTrueOrderBySortOrderAsc();

  @EntityGraph(attributePaths = {"category"})
  List<SafetyCheckMasterItem> findByCategoryIdOrderBySortOrderAsc(Long categoryId);

  @EntityGraph(attributePaths = {"category"})
  List<SafetyCheckMasterItem> findByCategoryIdAndIsActiveTrueOrderBySortOrderAsc(Long categoryId);

  @EntityGraph(attributePaths = {"category"})
  List<SafetyCheckMasterItem> findAllByOrderBySortOrderAsc();

  Optional<SafetyCheckMasterItem> findByItemKey(String itemKey);
  Optional<SafetyCheckMasterItem> findByItemKeyIgnoreCase(String itemKey);

  long countByCategoryIdAndIsActiveTrue(Long categoryId);

  @Query("select coalesce(max(i.sortOrder), 0) from SafetyCheckMasterItem i where i.category.id = :categoryId")
  Integer findMaxSortOrderByCategoryId(Long categoryId);

  @EntityGraph(attributePaths = {"category"})
  @Query(
      """
        select i
        from SafetyCheckMasterItem i
        join i.category c
        where (:categoryId is null or c.id = :categoryId)
          and (:activeOnly = false or i.isActive = true)
          and (
            :keyword is null
            or :keyword = ''
            or lower(i.itemKey) like lower(concat('%', :keyword, '%'))
            or lower(i.itemLabelKm) like lower(concat('%', :keyword, '%'))
            or lower(c.nameKm) like lower(concat('%', :keyword, '%'))
          )
        order by c.sortOrder asc, i.sortOrder asc, i.id asc
        """
  )
  List<SafetyCheckMasterItem> searchItems(
      @Param("categoryId") Long categoryId,
      @Param("activeOnly") boolean activeOnly,
      @Param("keyword") String keyword);
}
