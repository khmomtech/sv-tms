# Home Screen Layout Management System

## Overview

This system enables admin users to control the visibility and display order of sections on the driver app home screen through the admin panel. Sections can be reordered, shown, or hidden without requiring app updates.

## Architecture

### Backend Components

#### 1. Database Schema

**Table:** `home_layout_sections`

```sql
CREATE TABLE home_layout_sections (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    section_key VARCHAR(50) NOT NULL UNIQUE,
    section_name VARCHAR(100) NOT NULL,
    section_name_kh VARCHAR(100),
    description VARCHAR(500),
    description_kh VARCHAR(500),
    display_order INT NOT NULL DEFAULT 0,
    visible BOOLEAN NOT NULL DEFAULT TRUE,
    is_mandatory BOOLEAN NOT NULL DEFAULT FALSE,
    icon VARCHAR(50),
    category VARCHAR(50) DEFAULT 'general',
    config_json TEXT,
    created_by VARCHAR(100),
    created_at DATETIME NOT NULL,
    updated_by VARCHAR(100),
    updated_at DATETIME NOT NULL
);
```

**Migration file:** `tms-backend/src/main/resources/db/migration/V2026_03_10__create_home_layout_sections.sql`

#### 2. Backend API Endpoints

**Admin Endpoints** (`/api/admin/home-layout`)

- `GET /` - Get all sections with full details
- `GET /{id}` - Get section by ID
- `GET /key/{sectionKey}` - Get section by unique key
- `POST /` - Create new section
- `PUT /{id}` - Update section
- `DELETE /{id}` - Delete section (cannot delete mandatory sections)
- `PATCH /{id}/toggle-visibility` - Toggle section visibility
- `PATCH /reorder` - Reorder all sections in batch
- `POST /initialize-defaults` - Initialize default sections

**Driver Endpoint** (`/api/driver/home-layout`)

- `GET /sections` - Get visible sections (minimal data, ordered by displayOrder)

#### 3. Default Sections

| Section Key          | Name               | Mandatory | Default Order | Description                     |
| -------------------- | ------------------ | --------- | ------------- | ------------------------------- |
| `header`             | Header             | Yes       | 0             | User greeting and notifications |
| `maintenance_banner` | Maintenance Banner | No        | 1             | System announcements            |
| `shift_status`       | Shift Status       | No        | 2             | Current shift information       |
| `safety_status`      | Safety Status      | No        | 3             | Pre-trip safety check status    |
| `important_updates`  | Important Updates  | No        | 4             | Banners from admin              |
| `current_trip`       | Current Trip       | No        | 5             | Active trip information         |
| `quick_actions`      | Quick Actions      | No        | 6             | Frequently used features        |

### Driver App Components

#### 1. Models

**File:** `lib/models/home_layout_section_model.dart`

```dart
class HomeLayoutSectionModel {
  final String sectionKey;
  final int displayOrder;
  final bool visible;
  final String? configJson;
}

class HomeSectionKey {
  static const String header = 'header';
  static const String maintenanceBanner = 'maintenance_banner';
  static const String shiftStatus = 'shift_status';
  static const String safetyStatus = 'safety_status';
  static const String importantUpdates = 'important_updates';
  static const String currentTrip = 'current_trip';
  static const String quickActions = 'quick_actions';
}
```

#### 2. Service

**File:** `lib/services/home_layout_service.dart`

- Fetches layout configuration from backend
- Caches for 24 hours
- Falls back to default layout if API fails
- Returns only visible sections, sorted by displayOrder

#### 3. State Management

**File:** `lib/screens/shipment/home/home_state.dart`

Added to `HomeState`:

```dart
final List<String> layoutOrder; // Section keys in display order
final Set<String> visibleSections; // Set of visible section keys
```

#### 4. UI Rendering

**File:** `lib/screens/shipment/home_screen.dart`

- `_buildHomeSections()` method dynamically builds widgets based on layout
- Iterates through `layoutOrder` and only renders sections in `visibleSections`
- Always shows error view at bottom if present

## Usage Guide

### For Developers

#### Initialize Default Sections

```bash
curl -X POST http://localhost:8080/api/admin/home-layout/initialize-defaults \
  -H "Authorization: Bearer $TOKEN"
```

#### Run Database Migration

```bash
cd tms-backend
./mvnw flyway:migrate
```

#### Flutter Dependencies

The driver app already has all required dependencies. No additional packages needed.

### For Admin Users (via API)

#### Get All Sections

```bash
GET /api/admin/home-layout
```

Response:

```json
{
  "success": true,
  "message": "Layout sections retrieved successfully",
  "data": [
    {
      "id": 1,
      "sectionKey": "header",
      "sectionName": "Header",
      "sectionNameKh": "ក្បាល",
      "displayOrder": 0,
      "visible": true,
      "isMandatory": true,
      "icon": "person",
      "category": "system"
    }
    // ... more sections
  ]
}
```

#### Reorder Sections

```bash
PATCH /api/admin/home-layout/reorder
Content-Type: application/json

{
  "orderedIds": [3, 1, 5, 2, 4, 6, 7]
}
```

This sets the display order to:

1. Safety Status (id: 3)
2. Header (id: 1)
3. Important Updates (id: 5)
4. Maintenance Banner (id: 2)
5. Shift Status (id: 4)
6. Current Trip (id: 6)
7. Quick Actions (id: 7)

#### Hide a Section

```bash
PATCH /api/admin/home-layout/3/toggle-visibility
Authorization: Bearer $TOKEN
```

Response:

```json
{
  "success": true,
  "message": "Section visibility toggled",
  "data": {
    "id": 3,
    "sectionKey": "safety_status",
    "visible": false
  }
}
```

#### Update Section Details

```bash
PUT /api/admin/home-layout/5
Content-Type: application/json

{
  "sectionKey": "important_updates",
  "sectionName": "Company Announcements",
  "sectionNameKh": "ការប្រកាសក្រុមហ៊ុន",
  "description": "Important company-wide announcements",
  "displayOrder": 4,
  "visible": true,
  "icon": "campaign",
  "category": "content"
}
```

### For Driver App Users

The driver app automatically:

1. Fetches layout configuration on home screen load
2. Caches configuration for 24 hours
3. Renders sections in admin-configured order
4. Hides sections marked as not visible
5. Falls back to default layout if API fails

**No action required from drivers.** Layout changes from admin are reflected on next app launch or pull-to-refresh.

## Admin UI Implementation (Angular)

### Required Components

#### 1. Home Layout Management Component

**Path:** `tms-frontend/src/app/components/home-layout-management/`

Features:

- List view with drag-and-drop reordering
- Toggle switches for visibility
- Edit dialog for section details
- Bilingual labels (EN/KM)
- Category filtering
- Icon preview

#### 2. Service

**Path:** `tms-frontend/src/app/services/home-layout.service.ts`

Methods:

```typescript
getAllSections(): Observable<HomeLayoutSection[]>
getSectionById(id: number): Observable<HomeLayoutSection>
createSection(request: HomeLayoutSectionRequest): Observable<HomeLayoutSection>
updateSection(id: number, request: HomeLayoutSectionRequest): Observable<HomeLayoutSection>
deleteSection(id: number): Observable<void>
toggleVisibility(id: number): Observable<HomeLayoutSection>
reorderSections(orderedIds: number[]): Observable<HomeLayoutSection[]>
initializeDefaults(): Observable<void>
```

#### 3. UI Components

**List View:**

```html
<div class="layout-section-list">
  <div cdkDropList (cdkDropListDropped)="onSectionReorder($event)">
    <div *ngFor="let section of sections" cdkDrag>
      <mat-card>
        <mat-card-header>
          <mat-icon>{{ section.icon }}</mat-icon>
          <mat-card-title>{{ section.sectionName }}</mat-card-title>
          <mat-slide-toggle
            [checked]="section.visible"
            [disabled]="section.isMandatory"
            (change)="toggleVisibility(section)"
          >
          </mat-slide-toggle>
        </mat-card-header>
        <mat-card-content> {{ section.description }} </mat-card-content>
        <mat-card-actions>
          <button mat-button (click)="editSection(section)">Edit</button>
          <button
            mat-button
            (click)="deleteSection(section)"
            [disabled]="section.isMandatory"
          >
            Delete
          </button>
        </mat-card-actions>
      </mat-card>
    </div>
  </div>
</div>
```

**Required Angular Material Modules:**

- MatCardModule
- MatIconModule
- MatButtonModule
- MatSlideToggleModule
- MatDialogModule
- MatFormFieldModule
- MatInputModule
- MatSelectModule
- DragDropModule (@angular/cdk/drag-drop)

## Testing

### Backend Tests

```java
@Test
public void testGetVisibleSections() {
    // Arrange
    setupTestData();

    // Act
    ResponseEntity<ApiResponse<List<HomeLayoutSectionDto>>> response =
        driverController.getVisibleSections();

    // Assert
    assertEquals(HttpStatus.OK, response.getStatusCode());
    assertTrue(response.getBody().getSuccess());
    assertEquals(5, response.getBody().getData().size());
}

@Test
public void testReorderSections() {
    // Arrange
    List<Long> orderedIds = Arrays.asList(3L, 1L, 2L, 5L, 4L);

    // Act
    ResponseEntity<ApiResponse<List<HomeLayoutSectionDto>>> response =
        adminController.reorderSections(
            Map.of("orderedIds", orderedIds),
            authentication
        );

    // Assert
    List<HomeLayoutSectionDto> sections = response.getBody().getData();
    assertEquals(0, sections.get(0).getDisplayOrder());
    assertEquals(1, sections.get(1).getDisplayOrder());
}
```

### Flutter Tests

```dart
void main() {
  group('HomeLayoutService', () {
    test('fetches and caches layout', () async {
      final service = HomeLayoutService();
      final layout = await service.fetchLayout();

      expect(layout, isNotEmpty);
      expect(layout.first.sectionKey, isNotEmpty);
    });

    test('returns default layout on API failure', () async {
      // Mock API failure
      final service = HomeLayoutService();
      final layout = await service.fetchLayout();

      expect(layout.length, equals(7));
      expect(layout.first.sectionKey, equals('header'));
    });
  });
}
```

## Troubleshooting

### Driver App Shows All Sections (Ignoring Config)

**Cause:** Layout API failed, using default fallback

**Solution:**

1. Check backend logs for `/api/driver/home-layout/sections` endpoint
2. Verify database has sections: `SELECT * FROM home_layout_sections;`
3. Run initialization: `POST /api/admin/home-layout/initialize-defaults`
4. Clear driver app cache and refresh

### Section Not Hiding After Toggle

**Cause:** Driver app cached old configuration

**Solution:**

1. Pull-to-refresh on driver app home screen
2. Wait 24 hours for cache expiration
3. Or restart driver app

### Reorder Not Saving

**Cause:** Frontend not calling `/reorder` endpoint correctly

**Solution:**
Verify payload format:

```json
{
  "orderedIds": [3, 1, 5, 2, 4, 6, 7]
}
```

All section IDs must be included in the array.

## Future Enhancements

1. **Per-Driver Layouts:** Different layouts for different driver roles
2. **A/B Testing:** Test different layouts with driver cohorts
3. **Analytics:** Track which sections drivers interact with most
4. **Dynamic Section Config:** Allow sections to have custom settings (e.g., update frequency)
5. **Preview Mode:** Preview layout changes before applying
6. **Version History:** Track and rollback layout changes
7. **Templates:** Save and reuse layout configurations

## Files Created/Modified

### Backend

- `tms-backend/src/main/java/com/svtrucking/logistics/entity/HomeLayoutSection.java`
- `tms-backend/src/main/java/com/svtrucking/logistics/repository/HomeLayoutSectionRepository.java`
- `tms-backend/src/main/java/com/svtrucking/logistics/dto/HomeLayoutSectionDto.java`
- `tms-backend/src/main/java/com/svtrucking/logistics/dto/HomeLayoutSectionRequest.java`
- `tms-backend/src/main/java/com/svtrucking/logistics/service/HomeLayoutSectionService.java`
- `tms-backend/src/main/java/com/svtrucking/logistics/controller/admin/HomeLayoutController.java`
- `tms-backend/src/main/java/com/svtrucking/logistics/controller/driver/DriverHomeLayoutController.java`
- `tms-backend/src/main/resources/db/migration/V2026_03_10__create_home_layout_sections.sql`

### Driver App (Flutter)

- `tms_driver_app/lib/models/home_layout_section_model.dart`
- `tms_driver_app/lib/services/home_layout_service.dart`
- `tms_driver_app/lib/screens/shipment/home/home_state.dart` (modified)
- `tms_driver_app/lib/screens/shipment/home/home_controller.dart` (modified)
- `tms_driver_app/lib/screens/shipment/home_screen.dart` (modified)

### Admin UI (Angular) - To Be Created

- `tms-frontend/src/app/components/home-layout-management/home-layout-management.component.ts`
- `tms-frontend/src/app/components/home-layout-management/home-layout-management.component.html`
- `tms-frontend/src/app/components/home-layout-management/home-layout-management.component.scss`
- `tms-frontend/src/app/services/home-layout.service.ts`
- `tms-frontend/src/app/models/home-layout-section.model.ts`

## API Reference

See individual controller files for complete API documentation with request/response schemas.
