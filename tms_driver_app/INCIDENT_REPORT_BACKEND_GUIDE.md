# Incident Report Feature - Backend Integration Guide

## Overview
The Incident Report feature allows drivers to report accidents, theft, vandalism, and other incidents involving their assigned vehicle, with special focus on police case documentation.

## Backend DTO Structure

### IncidentReportDto (Request)
```java
public class IncidentReportDto {
    private Long driverId;
    private Long vehicleId;
    
    // Incident Details
    private String incidentType; // ACCIDENT, THEFT, VANDALISM, HIT_AND_RUN, VEHICLE_BREAKDOWN, OTHER
    private LocalDateTime incidentDateTime;
    private String location;
    private String description;
    private Boolean injuriesReported;
    
    // Police Information
    private Boolean policeInvolved;
    private String policeStation;
    private String officerName;
    private String caseNumber;
    
    // Witness Information
    private String witnessDetails;
    
    // Photos (file uploads)
    private List<MultipartFile> photos;
    
    // Metadata
    private LocalDateTime reportedAt;
    private String reportedBy; // Driver name
}
```

### IncidentReportResponseDto
```java
public class IncidentReportResponseDto {
    private Long incidentId;
    private String incidentNumber; // Auto-generated: INC-YYYY-MM-DD-XXXX
    private String status; // SUBMITTED, UNDER_REVIEW, RESOLVED, CLOSED
    private LocalDateTime submittedAt;
    private String message;
}
```

### IncidentStatus Enum
```java
public enum IncidentStatus {
    SUBMITTED,
    UNDER_REVIEW,
    INVESTIGATION,
    RESOLVED,
    CLOSED
}
```

### IncidentType Enum
```java
public enum IncidentType {
    ACCIDENT,
    THEFT,
    VANDALISM,
    HIT_AND_RUN,
    VEHICLE_BREAKDOWN,
    OTHER
}
```

## API Endpoints

### 1. Submit Incident Report
**POST** `/api/driver/incident/report`

**Request**: Multipart form data
- `incidentData` (JSON): IncidentReportDto without photos
- `photos[]` (Files): Multiple image files

**Response**: 201 Created
```json
{
  "incidentId": 123,
  "incidentNumber": "INC-2025-12-06-0001",
  "status": "SUBMITTED",
  "submittedAt": "2025-12-06T10:30:00",
  "message": "Incident report submitted successfully. Case number: INC-2025-12-06-0001"
}
```

### 2. Get Incident History
**GET** `/api/driver/incident/history`

**Response**: 200 OK
```json
{
  "incidents": [
    {
      "incidentId": 123,
      "incidentNumber": "INC-2025-12-06-0001",
      "incidentType": "ACCIDENT",
      "incidentDateTime": "2025-12-06T08:15:00",
      "location": "Highway 1, near Exit 42",
      "status": "UNDER_REVIEW",
      "policeInvolved": true,
      "caseNumber": "POL-2025-1234",
      "submittedAt": "2025-12-06T10:30:00",
      "photos": [
        "/uploads/incidents/123/photo1.jpg",
        "/uploads/incidents/123/photo2.jpg"
      ]
    }
  ]
}
```

### 3. Get Incident Details
**GET** `/api/driver/incident/{incidentId}`

**Response**: 200 OK
```json
{
  "incidentId": 123,
  "incidentNumber": "INC-2025-12-06-0001",
  "driverId": 45,
  "driverName": "John Doe",
  "vehicleId": 78,
  "licensePlate": "ABC-1234",
  "incidentType": "ACCIDENT",
  "incidentDateTime": "2025-12-06T08:15:00",
  "location": "Highway 1, near Exit 42",
  "description": "Rear-end collision at traffic light...",
  "injuriesReported": false,
  "policeInvolved": true,
  "policeStation": "Central Police Station",
  "officerName": "Officer Smith",
  "caseNumber": "POL-2025-1234",
  "witnessDetails": "Name: Jane Doe, Phone: 555-1234",
  "status": "UNDER_REVIEW",
  "submittedAt": "2025-12-06T10:30:00",
  "photos": [
    {
      "photoId": 1,
      "url": "/uploads/incidents/123/photo1.jpg",
      "uploadedAt": "2025-12-06T10:30:00"
    }
  ],
  "adminNotes": "Insurance contacted, awaiting assessment",
  "updatedAt": "2025-12-06T14:00:00"
}
```

## Database Schema

### incidents Table
```sql
CREATE TABLE incidents (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    incident_number VARCHAR(50) UNIQUE NOT NULL,
    driver_id BIGINT NOT NULL,
    vehicle_id BIGINT NOT NULL,
    
    -- Incident Details
    incident_type VARCHAR(50) NOT NULL,
    incident_datetime DATETIME NOT NULL,
    location VARCHAR(500) NOT NULL,
    description TEXT NOT NULL,
    injuries_reported BOOLEAN DEFAULT FALSE,
    
    -- Police Information
    police_involved BOOLEAN DEFAULT FALSE,
    police_station VARCHAR(200),
    officer_name VARCHAR(200),
    case_number VARCHAR(100),
    
    -- Witness
    witness_details TEXT,
    
    -- Status
    status VARCHAR(50) NOT NULL DEFAULT 'SUBMITTED',
    
    -- Metadata
    submitted_at DATETIME NOT NULL,
    updated_at DATETIME,
    resolved_at DATETIME,
    admin_notes TEXT,
    
    FOREIGN KEY (driver_id) REFERENCES drivers(id),
    FOREIGN KEY (vehicle_id) REFERENCES vehicles(id),
    INDEX idx_driver (driver_id),
    INDEX idx_vehicle (vehicle_id),
    INDEX idx_status (status),
    INDEX idx_incident_date (incident_datetime)
);
```

### incident_photos Table
```sql
CREATE TABLE incident_photos (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    incident_id BIGINT NOT NULL,
    file_path VARCHAR(500) NOT NULL,
    file_name VARCHAR(255) NOT NULL,
    file_size BIGINT,
    mime_type VARCHAR(100),
    uploaded_at DATETIME NOT NULL,
    
    FOREIGN KEY (incident_id) REFERENCES incidents(id) ON DELETE CASCADE,
    INDEX idx_incident (incident_id)
);
```

## File Upload Configuration

### Storage Path
```
/uploads/incidents/{incidentId}/
```

### Allowed File Types
- image/jpeg
- image/png
- image/jpg
- image/heic (iOS)

### File Size Limits
- Max file size: 10MB per photo
- Max photos: 10 per incident

### File Naming Convention
```
{incidentId}_{timestamp}_{random}.{extension}
Example: 123_1733475000_a1b2c3.jpg
```

## Security & Permissions

### Access Control
- Drivers can only submit and view their own incidents
- Dispatchers can view all incidents
- Admins can view, edit, and update incident status

### Required Permissions
- `DRIVER_INCIDENT_REPORT_CREATE`
- `DRIVER_INCIDENT_REPORT_VIEW_OWN`
- `DISPATCHER_INCIDENT_REPORT_VIEW_ALL`
- `ADMIN_INCIDENT_REPORT_MANAGE`

## Notifications

### Email Notifications
1. **Driver Submission Confirmation**
   - To: Driver email
   - Subject: "Incident Report Submitted - [Incident Number]"
   - Content: Confirmation with incident number and next steps

2. **Dispatcher Alert**
   - To: Dispatcher team email
   - Subject: "New Incident Report - [Incident Type]"
   - Content: Summary with driver, vehicle, and incident details

3. **Status Updates**
   - To: Driver email
   - Subject: "Incident Report Update - [Incident Number]"
   - Content: Status change notification

### Push Notifications
1. **Submission Confirmation** (Driver)
2. **New Incident Alert** (Dispatchers)
3. **Status Update** (Driver)

## Flutter DTO Implementation

### IncidentReportRequest
```dart
class IncidentReportRequest {
  final String incidentType;
  final DateTime incidentDateTime;
  final String location;
  final String description;
  final bool injuriesReported;
  final bool policeInvolved;
  final String? policeStation;
  final String? officerName;
  final String? caseNumber;
  final String? witnessDetails;
  final List<File> photos;

  Map<String, dynamic> toJson() => {
    'incidentType': incidentType,
    'incidentDateTime': incidentDateTime.toIso8601String(),
    'location': location,
    'description': description,
    'injuriesReported': injuriesReported,
    'policeInvolved': policeInvolved,
    'policeStation': policeStation,
    'officerName': officerName,
    'caseNumber': caseNumber,
    'witnessDetails': witnessDetails,
  };
}
```

## Integration Steps

1. **Create Backend Entities**
   - `Incident.java`
   - `IncidentPhoto.java`

2. **Create Repositories**
   - `IncidentRepository.java`
   - `IncidentPhotoRepository.java`

3. **Create DTOs**
   - `IncidentReportDto.java`
   - `IncidentReportResponseDto.java`

4. **Create Service**
   - `IncidentService.java`
   - Methods: submitReport(), getIncidentHistory(), getIncidentDetails()

5. **Create Controller**
   - `IncidentController.java`
   - Endpoints: POST /report, GET /history, GET /{id}

6. **Configure File Upload**
   - Update `application.properties` for max file size
   - Create upload directory structure

7. **Add Permissions**
   - Update security configuration
   - Add incident-related permissions to roles

8. **Update Flutter Provider**
   - Add `submitIncidentReport()` method to DriverProvider
   - Handle multipart form data upload

## Testing Checklist

### Frontend Tests
- [ ] Form validation works correctly
- [ ] Photo upload/removal works
- [ ] Date/time picker functions
- [ ] Police fields show/hide based on toggle
- [ ] Submit button disabled during submission
- [ ] Success/error messages display correctly

### Backend Tests
- [ ] Report submission creates incident record
- [ ] Photos uploaded and saved correctly
- [ ] Incident number auto-generated
- [ ] Email notifications sent
- [ ] Driver can view own incidents only
- [ ] Dispatcher can view all incidents

### Integration Tests
- [ ] End-to-end submission flow works
- [ ] File upload size limits enforced
- [ ] Invalid file types rejected
- [ ] Concurrent submissions handled

## Future Enhancements

1. **GPS Location Auto-fill**
   - Auto-populate location using GPS coordinates
   - Show incident location on map

2. **Incident Templates**
   - Quick templates for common incidents
   - Pre-filled common fields

3. **Status Tracking**
   - Timeline view of incident updates
   - Real-time status notifications

4. **Insurance Integration**
   - Auto-notify insurance company
   - Track insurance claim status

5. **Document Attachments**
   - Attach police reports
   - Insurance documents
   - Medical reports (if injuries)

6. **Voice-to-Text**
   - Dictate incident description
   - Useful for urgent situations

7. **Emergency Contacts**
   - Quick access to emergency numbers
   - One-tap call to police/insurance
