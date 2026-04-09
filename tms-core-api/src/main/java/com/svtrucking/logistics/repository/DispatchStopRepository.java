package com.svtrucking.logistics.repository;

import com.svtrucking.logistics.model.DispatchStop;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

@Repository
public interface DispatchStopRepository extends JpaRepository<DispatchStop, Long> {}
