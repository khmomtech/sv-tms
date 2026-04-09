package com.svtrucking.logistics.repository;

import com.svtrucking.logistics.model.TaskComment;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface TaskCommentRepository extends JpaRepository<TaskComment, Long> {

  // Find comments by task
  List<TaskComment> findByTaskIdAndIsDeletedFalseOrderByCreatedAtAsc(Long taskId);

  Page<TaskComment> findByTaskIdAndIsDeletedFalse(Long taskId, Pageable pageable);

  // Find top-level comments (no parent)
  List<TaskComment> findByTaskIdAndParentCommentIsNullAndIsDeletedFalseOrderByCreatedAtAsc(Long taskId);

  // Find replies to a comment
  List<TaskComment> findByParentCommentIdAndIsDeletedFalseOrderByCreatedAtAsc(Long parentCommentId);

  // Find comments by author
  List<TaskComment> findByAuthorIdAndIsDeletedFalseOrderByCreatedAtDesc(Long authorId);

  // Find internal comments only
  List<TaskComment> findByTaskIdAndIsInternalTrueAndIsDeletedFalseOrderByCreatedAtAsc(Long taskId);

  // Count comments for a task
  long countByTaskIdAndIsDeletedFalse(Long taskId);

  // Search comments by content
  @Query("SELECT c FROM TaskComment c WHERE " +
         "LOWER(c.content) LIKE LOWER(CONCAT('%', :keyword, '%')) " +
         "AND c.isDeleted = false " +
         "ORDER BY c.createdAt DESC")
  List<TaskComment> searchByContent(@Param("keyword") String keyword);
}
