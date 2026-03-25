> [!WARNING]
> Legacy document notice: This file is kept for history and may be outdated.
> Use `/Users/sotheakh/Documents/develop/sv-tms/docs/README.md` for active documentation.

# Angular Frontend Phase 2 - Quick Testing Guide

**Purpose**: Test the newly implemented detail views and create/edit forms  
**Backend Required**: Yes - Spring Boot backend must be running on port 8080  
**Database**: MySQL with test data

---

## Prerequisites

1. **Backend Running**
   ```bash
   cd driver-app
   ./mvnw spring-boot:run
   # OR if using nohup:
   # Check: ps aux | grep java
   ```

2. **Frontend Dev Server**
   ```bash
   cd tms-frontend
   npm install  # if needed
   npm run start
   # Opens on http://localhost:4200
   ```

3. **Login Credentials**
   - Username: `admin`
   - Password: `admin123`

---

## Test Scenarios

### 1. Incident CRUD Operations

#### Create New Incident
1. Navigate to http://localhost:4200/incidents
2. Click **"Create Incident"** button
3. Fill form:
   - Title: "Test Incident - Delayed Delivery"
   - Description: "Customer reported late delivery"
   - Incident Group: Select "CUSTOMER_COMPLAINT"
   - Severity: Select "MEDIUM"
   - Incident Type: "Delivery"
   - Location: "123 Main St, Phnom Penh"
   - Driver ID: 1
   - Vehicle ID: 1
   - Notes: "Customer called at 2 PM"
4. Click **"Create Incident"**
5. **Expected**: Redirected to incident detail page, all fields displayed correctly

#### View Incident Detail
1. From incident list, click on any incident row
2. **Expected**: 
   - All incident details displayed
   - Status badge color-coded
   - Severity badge shown
   - Driver/vehicle info in sidebar
   - Timeline metadata visible
   - Action buttons (Edit, Validate, Close, Delete) shown

#### Edit Incident (Inline)
1. On incident detail page, click **"Edit"** button
2. Blue info alert appears with Save/Cancel buttons
3. Modify some fields (e.g., change severity to HIGH)
4. Click **"Save Changes"**
5. **Expected**: Changes saved, edit mode disabled, updated data displayed

#### Edit Incident (Form Page)
1. Navigate to `/incidents/:id/edit` (or add edit route to detail actions)
2. Form loads with current incident data
3. Make changes
4. Click **"Update Incident"**
5. **Expected**: Redirected to detail page with updates

#### Validate Incident
1. Create or find incident with status "NEW"
2. On detail page, click **"Validate"** button
3. **Expected**: Status changes to "VALIDATED", button disappears

#### Close Incident
1. Find incident with status "NEW" or "VALIDATED"
2. Click **"Close"** button
3. Modal appears with resolution notes field
4. Enter: "Issue resolved, customer satisfied"
5. Click **"Close Incident"**
6. **Expected**: Status changes to "CLOSED", resolution notes saved and displayed

#### Delete Incident
1. On incident detail page, click **"Delete"** button
2. Confirmation modal appears
3. Click **"Delete"**
4. **Expected**: Redirected to incident list, incident soft-deleted

---

### 2. Case CRUD Operations

#### Create New Case
1. Navigate to http://localhost:4200/cases
2. Click **"Create Case"** button
3. Fill form:
   - Title: "Investigation: Multiple Customer Complaints"
   - Description: "Several customers reported similar issues"
   - Case Category: Select "CUSTOMER_SERVICE"
   - Severity: Select "HIGH"
   - Assign To: 1 (admin user ID)
4. Click **"Create Case"**
5. **Expected**: Redirected to case detail page, all fields shown

#### View Case Detail
1. From case list, click on any case row
2. **Expected**:
   - All case details displayed
   - Statistics sidebar (incident count, task counts)
   - Linked incidents table (if any)
   - Tasks section
   - Timeline/audit log (if available)
   - Assignment info shown

#### Edit Case (Inline)
1. On case detail page, click **"Edit"** button
2. Modify fields (e.g., change severity, update description)
3. Click **"Save Changes"**
4. **Expected**: Changes persisted, edit mode exits

#### Create Case Task
1. On case detail page, click **"Add Task"** button
2. Modal appears with task form
3. Fill task data:
   - Title: "Review customer feedback logs"
   - Description: "Analyze all feedback from past week"
   - Due Date: Select tomorrow's date
4. Click **"Create Task"**
5. **Expected**: Modal closes, task appears in tasks table

#### Delete Case Task
1. Find task in tasks table
2. Click trash icon
3. Confirm deletion
4. **Expected**: Task removed from table

#### Delete Case
1. On case detail page, click **"Delete"** button
2. Confirmation modal appears
3. Click **"Delete"**
4. **Expected**: Redirected to case list, case soft-deleted

---

### 3. Incident → Case Escalation Flow

#### Full Escalation Workflow
1. Create new incident (or use existing)
2. View incident detail page
3. Verify incident is NOT escalated (no escalated case shown)
4. Click **"Escalate to Case"** button
5. Modal appears with "Create New Case" button
6. Click **"Create New Case"**
7. **Expected**: Redirected to `/cases/create?incidentId=X`
8. Green alert shows: "After creating this case, the incident will be automatically linked to it."
9. Fill case form:
   - Title: "Case for Incident #INC-001"
   - Description: "Escalated from incident"
   - Category: "INVESTIGATION"
   - Severity: "HIGH"
10. Click **"Create Case"**
11. **Expected**:
    - Case created
    - Incident automatically linked
    - Redirected to new case detail
    - Linked incidents table shows the incident

#### Verify Escalation
1. Navigate back to original incident detail page
2. **Expected**:
   - "Escalated To Case" section shows case link
   - Case code displayed (e.g., CSE-001)
   - Link to case works

#### Unlink Incident from Case
1. On case detail page, find linked incident in table
2. Click red X button (unlink)
3. Confirm action
4. **Expected**: Incident removed from linked incidents table
5. Go to incident detail page
6. **Expected**: "Escalated To Case" section no longer shows case link

---

### 4. Form Validation Testing

#### Incident Form Validation
1. Navigate to `/incidents/create`
2. Try to submit empty form
3. **Expected**: Red validation messages appear below each required field
4. Fill only title
5. **Expected**: Other fields still show validation errors
6. Fill all required fields (title, description, group, severity)
7. **Expected**: Form submittable, validation errors clear

#### Case Form Validation
1. Navigate to `/cases/create`
2. Try to submit empty form
3. **Expected**: Validation errors for required fields
4. Enter title exceeding 255 characters
5. **Expected**: Validation error for max length
6. Fill all required fields correctly
7. **Expected**: Form valid and submittable

---

### 5. UI/UX Verification

#### Responsive Layout
1. Resize browser window to tablet size (~768px)
2. **Expected**: Layout adjusts, forms stack vertically
3. Resize to mobile (~375px)
4. **Expected**: All content readable, no horizontal scroll

#### Loading States
1. Submit form (create incident)
2. **Expected**: Submit button shows spinner, disabled state
3. Create task in case
4. **Expected**: Button disabled during API call

#### Error Handling
1. Stop backend server
2. Try to create incident
3. **Expected**: Error alert appears with message
4. Try to load incident detail
5. **Expected**: Error message displayed

#### Badge Colors
1. View incidents with different statuses
2. **Expected**:
   - NEW: Blue (bg-primary)
   - VALIDATED: Green (bg-success)
   - UNDER_INVESTIGATION: Yellow (bg-warning)
   - RESOLVED: Light blue (bg-info)
   - CLOSED: Gray (bg-secondary)
   - ESCALATED: Red (bg-danger)

3. Check severity badges:
   - LOW: Green (bg-success)
   - MEDIUM: Yellow (bg-warning)
   - HIGH: Red (bg-danger)
   - CRITICAL: Dark (bg-dark)

---

### 6. Edge Cases

#### Edit Non-existent Incident
1. Navigate to `/incidents/99999`
2. **Expected**: Error message or 404 handling

#### Create Case with Invalid Incident Link
1. Navigate to `/cases/create?incidentId=99999`
2. Fill form and submit
3. **Expected**: Case created, but linking fails gracefully (alert shown, still navigates to case)

#### Concurrent Edits
1. Open incident detail in two browser tabs
2. Edit in tab 1, save
3. Edit same field in tab 2, save
4. **Expected**: Last save wins (no conflict resolution yet)

#### Large Text Fields
1. Create incident with very long description (5000+ characters)
2. **Expected**: Text wraps correctly, no UI breaking

#### Special Characters
1. Create incident with title: `Test & "Special" <Characters>`
2. **Expected**: Stored and displayed correctly (no HTML injection)

---

## Quick Smoke Test (5 minutes)

Run through this minimal test to verify basic functionality:

1. Login to frontend
2. Navigate to /incidents → see list
3. Click "Create Incident" → fill minimal form → submit → see detail
4. Click "Edit" on detail → change title → save → verify change
5. Click "Validate" → verify status change
6. Navigate to /cases → see list
7. Click "Create Case" → fill minimal form → submit → see detail
8. Click "Add Task" → create task → verify in table
9. Navigate back to incident → click "Escalate to Case" → create new case
10. Verify incident appears in case's linked incidents table

---

## Common Issues & Solutions

### Issue: "Cannot GET /incidents"
**Solution**: Check Angular router configuration, ensure routes are defined

### Issue: API calls fail with CORS errors
**Solution**: 
- Check backend CORS configuration
- Ensure backend running on port 8080
- Verify proxy.conf.json if using Angular proxy

### Issue: Form doesn't submit
**Solution**:
- Check browser console for errors
- Verify form validation (all required fields filled)
- Check network tab for API response

### Issue: Modal doesn't show
**Solution**:
- Verify Bootstrap CSS/JS loaded
- Check modal show flag in component
- Inspect modal-backdrop element

### Issue: Changes don't persist
**Solution**:
- Check API response in network tab
- Verify backend logs for errors
- Check database for changes

---

## Manual API Testing (Backup)

If frontend fails, test backend directly:

```bash
# Login
TOKEN=$(curl -s -X POST http://localhost:8080/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"username":"admin","password":"admin123"}' \
  | python3 -c "import sys, json; print(json.load(sys.stdin)['data']['token'])")

# Create incident
curl -X POST http://localhost:8080/api/incidents \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "title": "Test Incident",
    "description": "Test description",
    "incidentGroup": "CUSTOMER_COMPLAINT",
    "severity": "MEDIUM"
  }'

# Get incident
curl -X GET http://localhost:8080/api/incidents/1 \
  -H "Authorization: Bearer $TOKEN"

# Create case
curl -X POST http://localhost:8080/api/cases \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "title": "Test Case",
    "description": "Test description",
    "caseCategory": "CUSTOMER_SERVICE",
    "severity": "HIGH"
  }'
```

---

## Completion Criteria

Phase 2 is considered fully tested when:

- [ ] All CRUD operations work for incidents
- [ ] All CRUD operations work for cases
- [ ] Incident → Case escalation flow works end-to-end
- [ ] Forms validate correctly
- [ ] Error states display properly
- [ ] Loading states work
- [ ] Modals open and close correctly
- [ ] Navigation between pages works
- [ ] API integration verified
- [ ] No console errors during normal operations

---

**Total Test Time**: ~30-45 minutes for comprehensive testing  
**Smoke Test**: ~5 minutes for basic verification  

Ready to test! 🚀
