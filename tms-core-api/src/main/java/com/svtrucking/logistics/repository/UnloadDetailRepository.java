package com.svtrucking.logistics.repository;

import com.svtrucking.logistics.model.UnloadDetail;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

@Repository
public interface UnloadDetailRepository extends JpaRepository<UnloadDetail, Long> {}
