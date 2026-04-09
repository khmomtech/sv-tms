package com.svtrucking.logistics.repository;

import com.svtrucking.logistics.model.TaskAttachment;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface TaskAttachmentRepository extends JpaRepository<TaskAttachment, Long> {

  // Find attachments by task
  List<TaskAttachment> findByTaskIdAndIsDeletedFalseOrderByUploadedAtDesc(Long taskId);

  // Find attachments by uploader
  List<TaskAttachment> findByUploadedByIdAndIsDeletedFalseOrderByUploadedAtDesc(Long userId);

  // Find attachments by mime type
  List<TaskAttachment> findByMimeTypeContainingAndIsDeletedFalse(String mimeType);

  // Count attachments for a task
  long countByTaskIdAndIsDeletedFalse(Long taskId);

  // Find by filename
  List<TaskAttachment> findByFileNameContainingIgnoreCaseAndIsDeletedFalse(String fileName);
}
