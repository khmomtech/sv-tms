package com.svtrucking.logistics.spec;

import com.svtrucking.logistics.dto.ItemFilterDto;
import com.svtrucking.logistics.model.Item;
import jakarta.persistence.criteria.Predicate;
import java.util.ArrayList;
import java.util.List;
import org.springframework.data.jpa.domain.Specification;

public class ItemSpecification {
  private ItemSpecification() {}

  public static Specification<Item> from(ItemFilterDto f) {
    return (root, query, cb) -> {
      List<Predicate> predicates = new ArrayList<>();
      if (f != null) {
        if (f.q != null && !f.q.isBlank()) {
          String like = "%" + f.q.trim().toLowerCase() + "%";
          predicates.add(
              cb.or(
                  cb.like(cb.lower(root.get("itemCode")), like),
                  cb.like(cb.lower(root.get("itemName")), like),
                  cb.like(cb.lower(root.get("itemNameKh")), like),
                  cb.like(cb.lower(root.get("size")), like),
                  cb.like(cb.lower(root.get("unit")), like),
                  cb.like(cb.lower(root.get("weight")), like),
                  cb.like(cb.lower(root.get("pallets")), like),
                  cb.like(cb.lower(root.get("palletType")), like),
                  cb.like(cb.lower(root.get("itemType").as(String.class)), like)));
        }
        if (f.status != null && !f.status.isBlank()) {
          try {
            predicates.add(cb.equal(root.get("status"), Integer.valueOf(f.status.trim())));
          } catch (NumberFormatException ignored) {
            // Ignore invalid status filters instead of breaking item search.
          }
        }
        if (f.from != null) {
          predicates.add(cb.greaterThanOrEqualTo(root.get("createdAt"), f.from.atStartOfDay()));
        }
        if (f.to != null) {
          predicates.add(cb.lessThanOrEqualTo(root.get("createdAt"), f.to.atTime(23, 59, 59)));
        }
      }
      return cb.and(predicates.toArray(new Predicate[0]));
    };
  }
}
