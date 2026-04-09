package com.svtrucking.logistics.config;

import org.springframework.stereotype.Component;
import org.springframework.context.ApplicationListener;
import org.springframework.context.event.ContextRefreshedEvent;

import javax.sql.DataSource;
import java.sql.Connection;
import java.sql.Statement;

@Component
public class TestSchemaInitializer implements ApplicationListener<ContextRefreshedEvent> {

  private final DataSource dataSource;

  public TestSchemaInitializer(DataSource dataSource) {
    this.dataSource = dataSource;
  }

  @Override
  public void onApplicationEvent(ContextRefreshedEvent event) {
    try (Connection c = dataSource.getConnection(); Statement s = c.createStatement()) {
        // driver_documents (existing)
        s.executeUpdate("CREATE TABLE IF NOT EXISTS \"driver_documents\" ("
          + "\"id\" BIGINT AUTO_INCREMENT PRIMARY KEY,"
          + "\"driver_id\" BIGINT NOT NULL,"
          + "\"name\" VARCHAR(255) NOT NULL,"
          + "\"category\" VARCHAR(50) NOT NULL,"
          + "\"expiry_date\" DATE,"
          + "\"description\" CLOB,"
          + "\"is_required\" BOOLEAN DEFAULT TRUE,"
          + "\"file_url\" VARCHAR(500),"
          + "\"created_at\" TIMESTAMP,"
          + "\"updated_at\" TIMESTAMP,"
          + "\"updated_by\" VARCHAR(255)"
          + ")");

        // customers and related tables used by authorization/auth tests
        s.executeUpdate("CREATE TABLE IF NOT EXISTS \"customers\" ("
          + "\"id\" BIGINT AUTO_INCREMENT PRIMARY KEY,"
          + "\"user_id\" BIGINT,"
          + "\"account_manager_id\" BIGINT,"
          + "\"partner_company_id\" BIGINT,"
          + "\"name\" VARCHAR(255),"
          + "\"email\" VARCHAR(255),"
          + "\"address\" VARCHAR(500),"
          + "\"created_at\" TIMESTAMP,"
          + "\"currency\" VARCHAR(10),"
          + "\"credit_limit\" DECIMAL(15,2),"
          + "\"current_balance\" DECIMAL(15,2),"
          + "\"customer_code\" VARCHAR(100),"
          + "\"customer_segment\" VARCHAR(50),"
          + "\"payment_terms\" VARCHAR(100),"
          + "\"phone\" VARCHAR(50),"
          + "\"segment\" VARCHAR(50),"
          + "\"status\" VARCHAR(50),"
          + "\"deleted_at\" TIMESTAMP,"
          + "\"deleted_by\" VARCHAR(100),"
          + "\"first_order_date\" DATE,"
          + "\"last_order_date\" DATE,"
          + "\"lifecycle_stage\" VARCHAR(50),"
          + "\"tags\" CLOB,"
          + "\"health_score\" INTEGER,"
          + "\"total_orders\" INTEGER,"
          + "\"total_revenue\" DECIMAL(15,2),"
          + "\"type\" VARCHAR(50),"
          + "\"updated_at\" TIMESTAMP"
          + ")");

        s.executeUpdate("CREATE TABLE IF NOT EXISTS \"company_customers\" ("
          + "\"id\" BIGINT AUTO_INCREMENT PRIMARY KEY,"
          + "\"customer_id\" BIGINT,"
          + "\"company_name\" VARCHAR(255),"
          + "\"contact_person\" VARCHAR(255),"
          + "\"contact_person_email\" VARCHAR(255),"
          + "\"contact_person_phone\" VARCHAR(50),"
          + "\"industry\" VARCHAR(100),"
          + "\"registration_number\" VARCHAR(100),"
          + "\"tax_id\" VARCHAR(100)"
          + ")");

        s.executeUpdate("CREATE TABLE IF NOT EXISTS \"individual_customers\" ("
          + "\"id\" BIGINT AUTO_INCREMENT PRIMARY KEY,"
          + "\"customer_id\" BIGINT,"
          + "\"date_of_birth\" DATE,"
          + "\"first_name\" VARCHAR(100),"
          + "\"gender\" VARCHAR(20),"
          + "\"last_name\" VARCHAR(100),"
          + "\"national_id\" VARCHAR(100),"
          + "\"passport_number\" VARCHAR(100)"
          + ")");

        s.executeUpdate("CREATE TABLE IF NOT EXISTS \"partner_companies\" ("
          + "\"id\" BIGINT AUTO_INCREMENT PRIMARY KEY,"
          + "\"company_code\" VARCHAR(50),"
          + "\"company_name\" VARCHAR(255),"
          + "\"business_license\" VARCHAR(100),"
          + "\"contact_person\" VARCHAR(255),"
          + "\"email\" VARCHAR(255),"
          + "\"phone\" VARCHAR(50),"
          + "\"address\" CLOB,"
          + "\"partnership_type\" VARCHAR(50),"
          + "\"status\" VARCHAR(50),"
          + "\"created_at\" TIMESTAMP,"
          + "\"updated_at\" TIMESTAMP"
          + ")");

        s.executeUpdate("CREATE TABLE IF NOT EXISTS \"vehicles\" ("
          + "\"id\" BIGINT AUTO_INCREMENT PRIMARY KEY,"
          + "\"parent_vehicle_id\" BIGINT,"
          + "\"assigned_zone\" VARCHAR(255),"
          + "\"created_at\" TIMESTAMP,"
          + "\"fuel_consumption\" DOUBLE,"
          + "\"gps_device_id\" BIGINT,"
          + "\"last_inspection_date\" TIMESTAMP,"
          + "\"last_service_date\" TIMESTAMP,"
          + "\"license_plate\" VARCHAR(100),"
          + "\"manufacturer\" VARCHAR(255),"
          + "\"mileage\" BIGINT,"
          + "\"model\" VARCHAR(255),"
          + "\"next_service_due\" TIMESTAMP,"
          + "\"qty_pallets_capacity\" INT,"
          + "\"remarks\" CLOB,"
          + "\"required_license_class\" VARCHAR(50),"
          + "\"status\" VARCHAR(50),"
          + "\"truck_size\" VARCHAR(50),"
          + "\"type\" VARCHAR(50),"
          + "\"updated_at\" TIMESTAMP,"
          + "\"year_made\" INT"
          + ")");

        s.executeUpdate("CREATE TABLE IF NOT EXISTS \"tasks\" ("
          + "\"id\" BIGINT AUTO_INCREMENT PRIMARY KEY,"
          + "\"code\" VARCHAR(50),"
          + "\"title\" VARCHAR(200),"
          + "\"description\" CLOB,"
          + "\"status\" VARCHAR(30),"
          + "\"priority\" VARCHAR(20),"
          + "\"assigned_to_user_id\" BIGINT,"
          + "\"created_by_user_id\" BIGINT,"
          + "\"created_at\" TIMESTAMP,"
          + "\"updated_at\" TIMESTAMP"
          + ")");

        // work_orders table used by WorkOrderControllerIntegrationTest and JPA mappings
        s.executeUpdate("CREATE TABLE IF NOT EXISTS work_orders ("
          + "id BIGINT AUTO_INCREMENT PRIMARY KEY,"
          + "wo_number VARCHAR(100),"
          + "title VARCHAR(255),"
          + "description CLOB,"
          + "issue_summary VARCHAR(500),"
          + "status VARCHAR(50),"
          + "type VARCHAR(50),"
          + "priority VARCHAR(50),"
          + "requires_approval BOOLEAN DEFAULT FALSE,"
          + "approved BOOLEAN DEFAULT FALSE,"
          + "approved_at TIMESTAMP,"
          + "approved_by VARCHAR(255),"
          + "approval_remarks CLOB,"
          + "assigned_technician_id BIGINT,"
          + "supervisor_id BIGINT,"
          + "vehicle_id BIGINT,"
          + "driver_issue_id BIGINT,"
          + "pm_schedule_id BIGINT,"
          + "maintenance_task_id BIGINT,"
          + "scheduled_date DATE,"
          + "started_at TIMESTAMP,"
          + "technician_dispatched_at TIMESTAMP,"
          + "technician_arrived_at TIMESTAMP,"
          + "breakdown_reported_at TIMESTAMP,"
          + "completed_at TIMESTAMP,"
          + "breakdown_latitude DECIMAL(10,6),"
          + "breakdown_longitude DECIMAL(10,6),"
          + "breakdown_location VARCHAR(500),"
          + "downtime_minutes INTEGER,"
          + "labor_cost DECIMAL(15,2),"
          + "parts_cost DECIMAL(15,2),"
          + "estimated_cost DECIMAL(15,2),"
          + "actual_cost DECIMAL(15,2),"
          + "total_cost DECIMAL(15,2),"
          + "notes CLOB,"
          + "remarks CLOB,"
          + "rejection_reason VARCHAR(500),"
          + "is_deleted BOOLEAN DEFAULT FALSE,"
          + "created_by VARCHAR(255),"
          + "created_at TIMESTAMP,"
          + "updated_at TIMESTAMP"
          + ")");

    } catch (Exception e) {
      throw new RuntimeException("Failed creating test schema", e);
    }
  }
}
