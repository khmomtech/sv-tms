package com.svtrucking.logistics.repository;

import com.svtrucking.logistics.model.Employee;
import com.svtrucking.logistics.model.User;
import java.util.List;
import java.util.Optional;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

@Repository
public interface EmployeeRepository extends JpaRepository<Employee, Long> {

  Optional<Employee> findByUser(User user);

  @Query(
      "SELECT e FROM Employee e WHERE "
          + "(:search IS NULL OR LOWER(e.firstName) LIKE LOWER(CONCAT('%', :search, '%')) "
          + "OR LOWER(e.lastName) LIKE LOWER(CONCAT('%', :search, '%')) "
          + "OR LOWER(e.email) LIKE LOWER(CONCAT('%', :search, '%')) "
          + "OR LOWER(e.department) LIKE LOWER(CONCAT('%', :search, '%')) "
          + "OR LOWER(e.position) LIKE LOWER(CONCAT('%', :search, '%')))")
  Page<Employee> search(@Param("search") String search, Pageable pageable);

  List<Employee> findAllByOrderByFirstNameAscLastNameAsc();
}
