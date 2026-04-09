package com.svtrucking.logistics.repository;

import com.svtrucking.logistics.model.DriverIssuePhoto;
import org.springframework.data.jpa.repository.JpaRepository;
import java.util.List;

public interface DriverIssuePhotoRepository extends JpaRepository<DriverIssuePhoto, Long> {

  List<DriverIssuePhoto> findByDriverIssueId(Long issueId);

  void deleteByDriverIssueId(Long issueId);
}
