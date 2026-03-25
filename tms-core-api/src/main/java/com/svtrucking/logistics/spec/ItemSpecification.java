package com.svtrucking.logistics.spec;

import com.svtrucking.logistics.dto.ItemFilterDto;
import com.svtrucking.logistics.model.Item;
import jakarta.persistence.criteria.Predicate;
import org.springframework.data.jpa.domain.Specification;

import java.util.ArrayList;
import java.util.List;

public class ItemSpecification {
    public static Specification<Item> from(ItemFilterDto f) {
        return (root, query, cb) -> {
            List<Predicate> p = new ArrayList<>();
            if (f != null) {
                if (f.q != null && !f.q.isBlank()) {
                    String like = "%" + f.q.trim().toLowerCase() + "%";
                    p.add(cb.or(
                        cb.like(cb.lower(root.get("name")), like),
                        cb.like(cb.lower(root.get("code")), like)
                    ));
                }
                if (f.ownerId != null) p.add(cb.equal(root.get("ownerId"), f.ownerId));
                if (f.status != null) p.add(cb.equal(root.get("status"), f.status));
                if (f.from != null) p.add(cb.greaterThanOrEqualTo(root.get("createdAt"), f.from.atStartOfDay()));
                if (f.to != null) p.add(cb.lessThanOrEqualTo(root.get("createdAt"), f.to.atTime(23,59,59)));
            }
            p.add(cb.equal(root.get("deleted"), false));
            return cb.and(p.toArray(new Predicate[0]));
        };
    }
}
