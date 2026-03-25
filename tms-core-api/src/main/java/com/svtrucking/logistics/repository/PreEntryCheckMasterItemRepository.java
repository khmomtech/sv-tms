package com.svtrucking.logistics.repository;

import com.svtrucking.logistics.model.PreEntryCheckMasterItem;
import java.util.List;
import java.util.Optional;
import org.springframework.data.jpa.repository.EntityGraph;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

public interface PreEntryCheckMasterItemRepository extends JpaRepository<PreEntryCheckMasterItem, Long> {
  @Query(
      """
        select c.code
        from PreEntryCheckMasterItem i
        join i.category c
        where i.isActive = true
          and c.isActive = true
        group by c.code, c.sortOrder
        order by c.sortOrder asc
        """
  )
  List<String> findActiveCategoryCodesWithActiveItems();

  @EntityGraph(attributePaths = {"category"})
  List<PreEntryCheckMasterItem> findByCategoryIdOrderBySortOrderAsc(Long categoryId);

  @EntityGraph(attributePaths = {"category"})
  List<PreEntryCheckMasterItem> findByCategoryIdAndIsActiveTrueOrderBySortOrderAsc(Long categoryId);

  @EntityGraph(attributePaths = {"category"})
  List<PreEntryCheckMasterItem> findAllByOrderBySortOrderAsc();

  Optional<PreEntryCheckMasterItem> findByItemKeyIgnoreCase(String itemKey);

  long countByCategoryIdAndIsActiveTrue(Long categoryId);

  @Query("select coalesce(max(i.sortOrder), 0) from PreEntryCheckMasterItem i where i.category.id = :categoryId")
  Integer findMaxSortOrderByCategoryId(Long categoryId);

  @EntityGraph(attributePaths = {"category"})
  @Query(
      """
        select i
        from PreEntryCheckMasterItem i
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
  List<PreEntryCheckMasterItem> searchItems(
      @Param("categoryId") Long categoryId,
      @Param("activeOnly") boolean activeOnly,
      @Param("keyword") String keyword);
}
