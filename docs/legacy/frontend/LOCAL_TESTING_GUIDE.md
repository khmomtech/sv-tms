> [!WARNING]
> Legacy document notice: This file is kept for history and may be outdated.
> Use `/Users/sotheakh/Documents/develop/sv-tms/docs/README.md` for active documentation.

# 🧪 Local Testing Guide - Driver Documents Management

**Date:** November 15, 2025  
**Status:** READY FOR TESTING  
**Component:** Driver Documents Management System  
**Route:** `/fleet-drivers/drivers/documents`

---

## 🚀 Quick Start

### 1. Start the Development Server

```bash
cd /Users/sotheakh/Documents/develop/sv-tms/tms-frontend
npm start
```

**Expected Output:**
```
Application bundle generation complete. [11.072 seconds]
➜  Local:   http://localhost:4200/
```

The server should start on **http://localhost:4200**

### 2. Navigate to the Component

Open your browser and go to:
```
http://localhost:4200/fleet-drivers/drivers/documents
```

Or navigate through the menu:
1. **Login** with your admin credentials
2. Click **"Fleet & Drivers"** in the sidebar
3. Click **"Driver Management"**
4. Click **"Documents & Licenses"**

---

## Testing Checklist

### Phase 1: Page Load & Initial State

- [ ] Page loads without errors (check browser console)
- [ ] Component displays the title "Driver Documents Management"
- [ ] Driver selector dropdown appears and is empty (waiting for selection)
- [ ] Upload button is visible at the top right
- [ ] No error messages in the console

**Expected Console:** No errors, only warnings about CommonJS dependencies (safe to ignore)

---

### Phase 2: Driver Selection

- [ ] Click the "Select a driver..." dropdown
- [ ] List of drivers appears
- [ ] Can scroll through the driver list
- [ ] Select a driver from the list
- [ ] Driver appears as selected in the dropdown

**Expected Behavior:**
- Once a driver is selected, documents should start loading
- A loading spinner should appear temporarily
- Documents list should populate below

---

### Phase 3: Statistics Dashboard

After selecting a driver, check:

- [ ] **Total Documents** card shows a number (can be 0)
- [ ] **Active Documents** card shows count
- [ ] **Expiring Soon** card shows count (≤30 days)
- [ ] **Expired Documents** card shows count

**Expected Values:**
- Statistics should be non-negative numbers
- "Expiring Soon" = documents with expiry ≤ 30 days
- "Expired" = documents with expiry date in the past

---

### Phase 4: Document List Display

- [ ] Document cards appear in a grid layout
- [ ] Each card shows:
  - [ ] Document icon (emoji or Material icon)
  - [ ] Document name
  - [ ] Status badge (green/yellow/red)
  - [ ] Category label
  - [ ] Upload/Expiry dates
  - [ ] Download and Delete buttons
  - [ ] Notes section (if available)

**Status Badges:**
- 🟢 **Green** = Active (not expired)
- 🟡 **Yellow** = Expiring Soon (≤30 days)
- 🔴 **Red** = Expired

---

### Phase 5: Search & Filtering

#### Search Functionality
- [ ] Type in the "Search documents..." field
- [ ] Results filter in real-time
- [ ] Clear button appears when searching
- [ ] Click clear button to reset search

**Test Cases:**
- Search by document name
- Search by partial name (e.g., "license" should find "Driver License")
- Search by description

#### Category Filter
- [ ] Click "Category" dropdown
- [ ] See options: License, Insurance, Registration, Medical, Training, Passport, Permit, Other
- [ ] Select a category
- [ ] Documents filter to show only selected category
- [ ] "All Categories" option resets filter

#### Status Filter
- [ ] Click "Status" dropdown
- [ ] Options: Active, Expiring Soon, Expired, All
- [ ] Select a status
- [ ] Documents filter accordingly

#### Sorting
- [ ] Select "Sort by" dropdown
- [ ] Options: Name, Category, Expiry Date, Upload Date
- [ ] Click "Ascending/Descending" to change sort order
- [ ] Documents reorder instantly

#### Clear Filters
- [ ] Click "Clear All Filters" button
- [ ] All filters reset to default
- [ ] Full document list displays

---

### Phase 6: Document Operations

#### View Document Details
- [ ] Click on a document card
- [ ] Detail modal opens showing:
  - [ ] Full document information
  - [ ] Status badge
  - [ ] Expiry tracking
  - [ ] Notes section
  - [ ] Download button
  - [ ] Delete button
- [ ] Close button or click outside to close modal

#### Download Document
- [ ] Click "Download" button on document card or modal
- [ ] File downloads to your computer
- [ ] File name matches the document name

**Note:** Download functionality requires backend to serve files from `/api/uploads/` or similar.

#### Delete Document
- [ ] Click "Delete" button on document card
- [ ] Confirmation dialog appears: "Are you sure you want to delete..."
- [ ] Click "OK" to confirm deletion
- [ ] Document disappears from list
- [ ] Success notification appears
- [ ] Statistics update (count decreases)

**Test Cancellation:**
- [ ] Click "Delete" button
- [ ] Click "Cancel" in confirmation
- [ ] Document remains in list

---

### Phase 7: Upload Document

#### Upload Modal
- [ ] Click "Upload Document" button at top right
- [ ] Upload modal appears with:
  - [ ] Drag-and-drop area
  - [ ] "Click to select file" text
  - [ ] Category dropdown
  - [ ] Upload button

#### Drag & Drop
- [ ] Drag a file over the drop area
- [ ] Drop zone highlights (visual feedback)
- [ ] File is selected after drop
- [ ] Selected file name appears in the modal
- [ ] File size displays

#### Click to Browse
- [ ] Click inside the drop area
- [ ] File browser dialog opens
- [ ] Select a file
- [ ] File name appears in modal

#### Upload Process
- [ ] Select a document category from dropdown
- [ ] Click "Upload" button
- [ ] Loading indicator appears
- [ ] Success message appears (toast notification)
- [ ] Modal closes automatically
- [ ] New document appears in the list
- [ ] Statistics update (total count increases)

**Test Cases:**
- [ ] Upload different file types (.pdf, .jpg, .png, .doc, etc.)
- [ ] Upload files of various sizes
- [ ] Try uploading without selecting a category (should show error)
- [ ] Try uploading without selecting a file (should show error)

---

### Phase 8: Responsive Design

#### Mobile View (< 640px)
- [ ] Resize browser to mobile size
- [ ] Layout adapts to single column
- [ ] All buttons remain accessible
- [ ] Text is readable without zooming
- [ ] Touch areas are large enough (48px+)

#### Tablet View (640-1024px)
- [ ] Resize to tablet size
- [ ] Layout shows 2-column grid
- [ ] All elements are properly spaced
- [ ] Responsive breakpoints work smoothly

#### Desktop View (> 1024px)
- [ ] Full desktop layout appears
- [ ] Multi-column grid displays
- [ ] Optimal readability and spacing

---

### Phase 9: Accessibility

- [ ] **Keyboard Navigation:**
  - [ ] Use Tab key to navigate between elements
  - [ ] Use Shift+Tab to go backward
  - [ ] Enter key activates buttons
  - [ ] Space key toggles checkboxes
  - [ ] Escape key closes modals

- [ ] **Screen Reader:**
  - [ ] Test with a screen reader (VoiceOver on Mac)
  - [ ] All interactive elements are announced
  - [ ] Form labels are associated with inputs
  - [ ] Status badges are descriptive

- [ ] **Focus Indicators:**
  - [ ] Clear focus rings appear on buttons
  - [ ] Easy to see keyboard focus
  - [ ] Focus order is logical

- [ ] **Color Contrast:**
  - [ ] All text is readable
  - [ ] Status colors are not the only indicator
  - [ ] Badges have text labels

---

### Phase 10: Error Handling

#### Network Errors
- [ ] Stop the backend API server
- [ ] Try to select a driver
- [ ] Error message should appear
- [ ] Component should not crash
- [ ] User can retry

#### Empty State
- [ ] If a driver has no documents
- [ ] "No documents found" message appears
- [ ] Helpful message with action (upload button)

#### File Upload Errors
- [ ] Try uploading without a file
- [ ] Error message: "Please select a file"
- [ ] Try uploading without a category
- [ ] Component handles gracefully

---

### Phase 11: User Feedback

- [ ] **Loading Indicators:**
  - [ ] Spinner appears while loading data
  - [ ] "Loading documents..." message shows
  - [ ] Spinner disappears when done

- [ ] **Toast Notifications:**
  - [ ] Success message appears after operations
  - [ ] Error messages are clear and helpful
  - [ ] Notifications auto-dismiss after 2 seconds
  - [ ] Toast appears in bottom-right corner

- [ ] **Visual Feedback:**
  - [ ] Buttons change appearance on hover
  - [ ] Modal dialogs fade in/out smoothly
  - [ ] Cards have smooth transitions
  - [ ] Loading spinner animates smoothly

---

## 🐛 Troubleshooting

### Issue: Page shows blank or 404

**Solution:**
1. Check if dev server is running: `lsof -i :4200`
2. Verify route in URL: `/fleet-drivers/drivers/documents`
3. Check browser console for errors
4. Hard refresh: `Cmd+Shift+R` (Mac) or `Ctrl+Shift+R` (Windows)

### Issue: Driver dropdown is empty

**Solution:**
1. Check backend API is running (`http://localhost:8080`)
2. Verify proxy configuration in `proxy.conf.json`
3. Check network tab in browser DevTools
4. Verify API endpoint: `GET /api/admin/drivers`

### Issue: Documents don't appear after selecting driver

**Solution:**
1. Check browser console for errors
2. Verify driver ID is being passed correctly
3. Check network tab: `GET /api/admin/drivers/{driverId}/documents`
4. Ensure backend returns valid document list

### Issue: Upload doesn't work

**Solution:**
1. Check backend endpoint: `POST /api/admin/drivers/{driverId}/documents/upload`
2. Verify FormData is being sent correctly
3. Check file size limits on backend
4. Ensure document category is selected

### Issue: Download button doesn't work

**Solution:**
1. Check browser console for errors
2. Verify backend serves files from correct path
3. Check network tab: `GET /api/uploads/...`
4. Ensure file exists on server

### Issue: Delete shows permission error

**Solution:**
1. Verify user has admin permissions
2. Check JWT token is valid
3. Verify backend authorization logic
4. Check endpoint: `DELETE /api/admin/drivers/documents/{documentId}`

---

## 📊 Performance Testing

### Load Time
- [ ] Initial page load time (should be < 3 seconds)
- [ ] Document list loads (should be < 1 second)
- [ ] Filters respond instantly
- [ ] Search filters in real-time

### Memory Usage
- [ ] Open DevTools → Performance tab
- [ ] Monitor memory while navigating
- [ ] Memory should not grow excessively
- [ ] No memory leaks

### Network Requests
- [ ] Check DevTools → Network tab
- [ ] Verify only necessary requests are made
- [ ] No duplicate requests
- [ ] Cache headers are respected

---

## 📝 Test Report Template

Use this template to document your testing:

```markdown
# Test Report - Driver Documents Component

**Date:** [Date]
**Tester:** [Your Name]
**Environment:** Local Development
**Browser:** [Browser & Version]

## Results Summary
- Passed: [ ] / [ ] tests
- Failed: [ ]
- Issues: [ ]

## Detailed Results

### Phase 1: Page Load / ❌
- Comments: [Any observations]

### Phase 2: Driver Selection / ❌
- Comments: [Any observations]

[Continue for each phase...]

## Issues Found

1. **Issue Title**
   - Description: [What happened]
   - Steps to Reproduce: [How to trigger]
   - Expected Behavior: [What should happen]
   - Actual Behavior: [What actually happens]
   - Severity: [Critical/High/Medium/Low]

## Recommendations

[Any improvements or fixes needed]

## Sign-off

- [ ] Component is production ready
- [ ] All tests passed
- [ ] No critical issues found

Tester: ________________  Date: ________________
```

---

## 🎯 Success Criteria

Your testing is **COMPLETE** when:

All features load without errors  
All CRUD operations work (Create/Read/Update/Delete)  
Filters and search work correctly  
Statistics calculate accurately  
Responsive design works on all screen sizes  
Accessibility features work  
Error handling is graceful  
User feedback is clear  
No console errors  
Build passes without errors  

---

## 📞 Support

If you encounter any issues during testing:

1. **Check the browser console** (F12 → Console tab)
2. **Check the network tab** (F12 → Network tab)
3. **Review the error message** carefully
4. **Check backend logs** for API errors
5. **Refer to the troubleshooting section** above

For detailed documentation:
- See `DRIVER_DOCUMENTS_COMPLETE_GUIDE.md` for architecture details
- See `DRIVER_DOCUMENTS_QUICK_REF.md` for quick reference
- Check `app.routes.ts` for routing configuration
- Check `driver.service.ts` for API methods

---

**Happy Testing! 🚀**

*If all tests pass, the component is ready for production deployment.*
