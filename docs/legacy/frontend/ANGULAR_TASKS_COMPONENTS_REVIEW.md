> [!WARNING]
> Legacy document notice: This file is kept for history and may be outdated.
> Use `/Users/sotheakh/Documents/develop/sv-tms/docs/README.md` for active documentation.

# Angular Tasks Components Review & Smoke Test Results

## Executive Summary

**CRITICAL FINDING**: The Angular tasks components (`task-list`, `task-detail`, `task-form`) are built to consume a `/api/tasks` REST API that **does not exist** in the backend. 

## Component Analysis

### 1. TaskListComponent (`task-list.component.ts`)
- **Location**: `tms-frontend/src/app/components/tasks/task-list/`
- **Purpose**: Display paginated list of tasks with search and filtering
- **API Endpoints Used** (from TaskService):
  - `GET /api/tasks` - List tasks with pagination ❌ **NOT FOUND**
  - `GET /api/tasks/status/{status}` - Filter by status ❌ **NOT FOUND**
  - `GET /api/tasks/my-tasks` - Get assigned tasks ❌ **NOT FOUND**
  - `DELETE /api/tasks/{id}` - Delete task ❌ **NOT FOUND**

### 2. TaskDetailComponent (`task-detail.component.ts`)
- **Location**: `tms-frontend/src/app/components/tasks/task-detail/`
- **Purpose**: Display and manage individual task details
- **API Endpoints Used**:
  - `GET /api/tasks/{id}` - Get task details ❌ **NOT FOUND**
  - `PUT /api/tasks/{id}/status` - Update status ❌ **NOT FOUND**
  - `DELETE /api/tasks/{id}` - Delete task ❌ **NOT FOUND**

### 3. TaskFormComponent (`task-form.component.ts`)
- **Location**: `tms-frontend/src/app/components/tasks/task-form/`
- **Purpose**: Create and edit tasks
- **API Endpoints Used**:
  - `POST /api/tasks` - Create task ❌ **NOT FOUND**
  - `PUT /api/tasks/{id}` - Update task ❌ **NOT FOUND**
  - `GET /api/tasks/{id}` - Load for editing ❌ **NOT FOUND**

## Backend Reality Check

### What Actually Exists:

#### 1. Maintenance Tasks (Admin)
- **Base URL**: `/api/admin/maintenance-tasks`
- **Purpose**: Preventive maintenance task types
- **Controller**: `MaintenanceTaskController.java`

#### 2. Work Order Tasks (Technician)
- **Base URL**: `/api/technician/tasks`
- **Purpose**: Tasks assigned to technicians within work orders
- **Controller**: `TechnicianController.java`
- **Available Endpoints**:
  - `GET /api/technician/tasks` - Get technician's assigned tasks ✅
  - `GET /api/technician/tasks/pending` - Get pending tasks ✅
  - `PATCH /api/technician/tasks/{taskId}/status` - Update task status ✅
  - `PATCH /api/technician/tasks/{taskId}/hours` - Update hours ✅

## Model Mismatch

### Angular Model: `IncidentTask`
```typescript
interface IncidentTask {
  id?: number;
  title: string;
  description?: string;
  taskType: TaskType;
  status: TaskStatus;
  priority: TaskPriority;
  incidentId?: number;
  assignedToId?: number;
  dueDate?: string;
  createdDate?: string;
  // ... more fields
}
```

### Backend Model: `WorkOrderTask`
```java
class WorkOrderTask {
  private Long id;
  private WorkOrder workOrder;
  private MaintenanceTaskType taskType;
  private TaskStatus status;
  private User assignedTechnician;
  private Double estimatedHours;
  private Double actualHours;
  private LocalDateTime completedAt;
  // ... different structure
}
```

## Issues Identified

### 1. API Endpoint Mismatch ⚠️ **CRITICAL**
- Angular expects: `/api/tasks/*`
- Backend provides: `/api/admin/maintenance-tasks/*` and `/api/technician/tasks/*`
- **Impact**: Components will fail at runtime with 404 errors

### 2. Data Model Incompatibility ⚠️ **HIGH**
- `IncidentTask` vs `WorkOrderTask` - completely different structures
- Different field names and types
- **Impact**: Even if endpoints existed, data mapping would fail

### 3. Missing CRUD Operations ⚠️ **HIGH**
- Backend technician endpoints are read-only (GET/PATCH only)
- No CREATE or full UPDATE endpoints for tasks
- **Impact**: Task form component cannot create new tasks

### 4. Role-Based Access Not Aligned ⚠️ **MEDIUM**
- Angular uses generic `/api/tasks`
- Backend uses role-specific routes (`/api/admin/*`, `/api/technician/*`)
- **Impact**: Authorization logic mismatch

## Recommendations

### Option 1: Create Missing Backend API (Recommended)
1. Create `/api/tasks` controller with full CRUD operations
2. Implement `IncidentTask` entity and repository
3. Add proper authorization and validation
4. Maintain backward compatibility with existing work order tasks

### Option 2: Update Angular Components
1. Rename components to `work-order-task-*`
2. Update TaskService to use `/api/technician/tasks`
3. Change model from `IncidentTask` to `WorkOrderTaskDto`
4. Remove create/update functionality (read-only view)
5. Update UI to reflect work order task concepts

### Option 3: Hybrid Approach
1. Keep components for future "incident task" feature
2. Create separate work order task components
3. Use existing `/api/technician/tasks` for technician view
4. Plan for incident management system later

## Smoke Test Results

**Test File**: `tms-frontend/test-tasks-angular.sh`

```
==== Test Summary ====
Total Tests: 26
Passed: 2 (7.7%)
Failed: 24 (92.3%)
```

### Tests That Passed ✅
1. Invalid status handling (404 as expected)
2. Unauthorized access returns 401

### Tests That Failed ❌
All endpoint tests failed with **HTTP 404** because the API doesn't exist:
- Task list retrieval
- Task search
- Status filtering
- Task statistics
- Task creation
- Task update
- Task deletion
- My tasks
- Pagination

## Conclusion

The Angular tasks components are **non-functional** in the current system. They were likely:
1. Built for a planned feature that wasn't implemented in the backend
2. Copied from another project without backend integration
3. Part of incomplete development work

### Immediate Action Required:
⚠️ **Do not deploy these components to production** - they will fail

### Next Steps:
1. **Decision needed**: Which option to implement (1, 2, or 3 above)
2. Remove or disable task routes from Angular routing
3. Either implement backend API or update components
4. Update documentation to reflect actual capabilities

## Files Reviewed

### Angular Components
- `tms-frontend/src/app/components/tasks/task-list/task-list.component.ts` (272 lines)
- `tms-frontend/src/app/components/tasks/task-detail/task-detail.component.ts` (137 lines)
- `tms-frontend/src/app/components/tasks/task-form/task-form.component.ts` (1269 lines)

### Angular Services
- `tms-frontend/src/app/services/task.service.ts` (211 lines)

### Backend Controllers (Actual)
- `tms-backend/.../MaintenanceTaskController.java`
- `tms-backend/.../TechnicianController.java`

### Test Files Created
- `tms-frontend/test-tasks-angular.sh` - Comprehensive smoke tests (demonstrates API mismatch)

## Technical Debt Impact

**Estimated effort to fix**:
- Option 1 (Backend API): 2-3 days
- Option 2 (Update Angular): 1-2 days
- Option 3 (Hybrid): 3-4 days

**Risk Level**: HIGH - Components appear functional but fail at runtime
