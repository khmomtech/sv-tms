package com.svtrucking.logistics.repository;

import com.svtrucking.logistics.enums.TaskPriority;
import com.svtrucking.logistics.enums.TaskStatus;
import com.svtrucking.logistics.model.Task;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.JpaSpecificationExecutor;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;

@Repository
public interface TaskRepository extends JpaRepository<Task, Long>, JpaSpecificationExecutor<Task> {

  // Find by code
  Optional<Task> findByCodeAndIsDeletedFalse(String code);

  // Find by relation (e.g., all tasks for a work order)
  List<Task> findByRelationTypeAndRelationIdAndIsDeletedFalse(String relationType, Long relationId);

  // Find by relation with pagination
  Page<Task> findByRelationTypeAndRelationIdAndIsDeletedFalse(
      String relationType, Long relationId, Pageable pageable);

  // Find standalone tasks (no relation)
  List<Task> findByRelationTypeIsNullAndIsDeletedFalse();

  Page<Task> findByRelationTypeIsNullAndIsDeletedFalse(Pageable pageable);

  // Find by status
  List<Task> findByStatusAndIsDeletedFalse(TaskStatus status);

  Page<Task> findByStatusAndIsDeletedFalse(TaskStatus status, Pageable pageable);

  // Find by assigned user
  List<Task> findByAssignedToIdAndIsDeletedFalse(Long userId);

  Page<Task> findByAssignedToIdAndIsDeletedFalse(Long userId, Pageable pageable);

  // Find by assigned user and status
  List<Task> findByAssignedToIdAndStatusAndIsDeletedFalse(Long userId, TaskStatus status);

  // Find by priority
  List<Task> findByPriorityAndIsDeletedFalse(TaskPriority priority);

  // Count methods for statistics
  long countByIsDeletedFalse();
  
  long countByStatusAndIsDeletedFalse(TaskStatus status);
  
  long countByPriorityAndIsDeletedFalse(TaskPriority priority);
  
  long countByAssignedToIdAndIsDeletedFalse(Long userId);
  
  long countByCreatedByIdAndIsDeletedFalse(Long userId);
  
  long countByRelationTypeIsNullAndIsDeletedFalse();
  
  @Query("SELECT COUNT(t) FROM Task t JOIN t.watchers w WHERE w.id = :userId AND t.isDeleted = false")
  long countTasksWatchedByUser(@Param("userId") Long userId);

  // Find urgent tasks
  List<Task> findByIsUrgentTrueAndStatusNotInAndIsDeletedFalse(List<TaskStatus> statuses);

  // Find overdue tasks
  @Query("SELECT t FROM Task t WHERE t.dueDate < :now " +
         "AND t.status NOT IN :completedStatuses " +
         "AND t.isDeleted = false")
  List<Task> findOverdueTasks(
      @Param("now") LocalDateTime now,
      @Param("completedStatuses") List<TaskStatus> completedStatuses);

  // Find tasks by department
  List<Task> findByDepartmentAndIsDeletedFalse(String department);

  Page<Task> findByDepartmentAndIsDeletedFalse(String department, Pageable pageable);

  // Find tasks by team
  List<Task> findByTeamAndIsDeletedFalse(String team);

  // Find parent tasks (no parent)
  List<Task> findByParentTaskIsNullAndIsDeletedFalse();

  // Find subtasks of a parent
  List<Task> findByParentTaskIdAndIsDeletedFalse(Long parentTaskId);

  // Find tasks created by user
  List<Task> findByCreatedByIdAndIsDeletedFalse(Long userId);

  // Find tasks with watchers containing user
  @Query("SELECT t FROM Task t JOIN t.watchers w WHERE w.id = :userId AND t.isDeleted = false")
  List<Task> findTasksWatchedByUser(@Param("userId") Long userId);

  // Find tasks by tag
  @Query("SELECT t FROM Task t JOIN t.tags tag WHERE tag.id = :tagId AND t.isDeleted = false")
  List<Task> findByTagId(@Param("tagId") Long tagId);

  // Count overdue tasks
  @Query("SELECT COUNT(t) FROM Task t WHERE t.dueDate < :now " +
         "AND t.status NOT IN :completedStatuses " +
         "AND t.isDeleted = false")
  long countOverdueTasks(
      @Param("now") LocalDateTime now,
      @Param("completedStatuses") List<TaskStatus> completedStatuses);

  // Find tasks by multiple statuses
  List<Task> findByStatusInAndIsDeletedFalse(List<TaskStatus> statuses);

  Page<Task> findByStatusInAndIsDeletedFalse(List<TaskStatus> statuses, Pageable pageable);

  // Find tasks by assigned user and multiple statuses
  List<Task> findByAssignedToIdAndStatusInAndIsDeletedFalse(Long userId, List<TaskStatus> statuses);

  // Search by title or description
  @Query("SELECT t FROM Task t WHERE " +
         "(LOWER(t.title) LIKE LOWER(CONCAT('%', :keyword, '%')) " +
         "OR LOWER(t.description) LIKE LOWER(CONCAT('%', :keyword, '%'))) " +
         "AND t.isDeleted = false")
  List<Task> searchByKeyword(@Param("keyword") String keyword);

  @Query("SELECT t FROM Task t WHERE " +
         "(LOWER(t.title) LIKE LOWER(CONCAT('%', :keyword, '%')) " +
         "OR LOWER(t.description) LIKE LOWER(CONCAT('%', :keyword, '%'))) " +
         "AND t.isDeleted = false")
  Page<Task> searchByKeyword(@Param("keyword") String keyword, Pageable pageable);

  // Complex search with multiple filters
  @Query("SELECT t FROM Task t WHERE " +
         "(:keyword IS NULL OR LOWER(t.title) LIKE LOWER(CONCAT('%', :keyword, '%')) " +
         "OR LOWER(t.description) LIKE LOWER(CONCAT('%', :keyword, '%'))) " +
         "AND (:status IS NULL OR t.status = :status) " +
         "AND (:priority IS NULL OR t.priority = :priority) " +
         "AND (:assignedToId IS NULL OR t.assignedTo.id = :assignedToId) " +
         "AND (:department IS NULL OR t.department = :department) " +
         "AND (:relationType IS NULL OR t.relationType = :relationType) " +
         "AND t.isDeleted = false")
  Page<Task> searchTasks(
      @Param("keyword") String keyword,
      @Param("status") TaskStatus status,
      @Param("priority") TaskPriority priority,
      @Param("assignedToId") Long assignedToId,
      @Param("department") String department,
      @Param("relationType") String relationType,
      Pageable pageable);
}
