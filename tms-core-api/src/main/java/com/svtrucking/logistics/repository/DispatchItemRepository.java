package com.svtrucking.logistics.repository;

import com.svtrucking.logistics.model.DispatchItem;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

@Repository
public interface DispatchItemRepository extends JpaRepository<DispatchItem, Long> {}
