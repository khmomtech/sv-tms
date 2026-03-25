# Incident Report Feature - Quick Start Guide

## 🚀 Quick Overview

The Incident Report feature allows drivers to report vehicle incidents (accidents, theft, vandalism, etc.) with full police case documentation support.

## 📱 User Flow

```
My Vehicle Screen
     ↓
[🚨 Report a Problem] Button
     ↓
Incident Report Screen
     ↓
Fill Form & Add Photos
     ↓
Submit Report
     ↓
Confirmation (Incident Number)
```

## 🖼️ Screen Layout

### Incident Report Screen Sections

```
┌─────────────────────────────────────┐
│  ← Report Incident                   │
├─────────────────────────────────────┤
│                                      │
│  📋 Incident Details                 │
│  ┌────────────────────────────────┐ │
│  │ Incident Type: [Dropdown]      │ │
│  │ Date & Time: [Picker]          │ │
│  │ Location: [Text Input]         │ │
│  │ Description: [Text Area]       │ │
│  │ ☐ Injuries Reported            │ │
│  └────────────────────────────────┘ │
│                                      │
│  🚔 Police Information               │
│  ┌────────────────────────────────┐ │
│  │ ☑ Police Involved              │ │
│  │ Police Station: [Text Input]   │ │
│  │ Officer Name: [Text Input]     │ │
│  │ Case Number: [Text Input]      │ │
│  └────────────────────────────────┘ │
│                                      │
│  👥 Witness Information              │
│  ┌────────────────────────────────┐ │
│  │ Witness Details: [Text Area]   │ │
│  └────────────────────────────────┘ │
│                                      │
│  📸 Photos & Evidence                │
│  ┌────────────────────────────────┐ │
│  │ [Photo] [Photo] [Photo]        │ │
│  │ [Photo] [Photo] [+Add]         │ │
│  └────────────────────────────────┘ │
│  [📷 Take Photo] [🖼️ Gallery]      │
│                                      │
│  ┌────────────────────────────────┐ │
│  │  Submit Incident Report        │ │
│  └────────────────────────────────┘ │
└─────────────────────────────────────┘
```

## 🎯 Key Features

### 1. Smart Form Validation
- Required fields marked clearly
- Minimum character counts enforced
- Conditional validation (police fields only required if police involved)
- At least 1 photo required

### 2. Photo Management
```
Take Photo → Camera opens → Capture → Auto-add to grid
Select from Gallery → Photo picker → Select → Auto-add to grid
Remove Photo → Tap X button → Photo removed
```

### 3. Police Case Documentation
```
Toggle "Police Involved" ON
  ↓
Police Station (required)
Officer Name (optional)
Case Number (required) ← Critical for insurance!
```

## 📝 How to Use

### Step 1: Access Incident Report
```
1. Open My Vehicle screen
2. Scroll to Maintenance section
3. Tap "🚨 Report a Problem"
```

### Step 2: Fill Incident Details
```
1. Select Incident Type:
   • Accident
   • Theft
   • Vandalism
   • Hit and Run
   • Vehicle Breakdown
   • Other

2. Select Date & Time
   - Tap date/time field
   - Choose when incident occurred
   - Cannot be future date

3. Enter Location
   - Type exact location
   - Example: "Highway 1, Exit 42"

4. Write Description
   - Minimum 20 characters
   - Be detailed and specific
   - Include all relevant facts

5. Toggle Injuries (if applicable)
```

### Step 3: Document Police Case (if applicable)
```
1. Toggle "Police Involved" ON

2. Enter Police Station
   - Name of station where report filed
   - Example: "Central Police Station"

3. Enter Officer Name (optional)
   - Attending officer
   - Example: "Officer Smith"

4. Enter Case Number (CRITICAL!)
   - Official police report number
   - Example: "POL-2025-1234"
   - Required for insurance claims
```

### Step 4: Add Witness Info (optional)
```
Enter witness details:
- Names
- Contact information
- Brief description

Example:
"Name: John Doe
Phone: 555-1234
Driver of other vehicle"
```

### Step 5: Add Photos (minimum 1 required)
```
Option A: Take Photo
  1. Tap "📷 Take Photo"
  2. Camera opens
  3. Take photo
  4. Photo appears in grid

Option B: Select from Gallery
  1. Tap "🖼️ Gallery"
  2. Photo picker opens
  3. Select photo(s)
  4. Photos appear in grid

Remove Photo:
  1. Tap X on photo thumbnail
  2. Photo removed from grid
```

### Step 6: Submit Report
```
1. Review all information
2. Tap "Submit Incident Report"
3. Loading indicator shows
4. Success message appears
5. Navigate back to My Vehicle
```

## Validation Rules

| Field | Rule | Error Message |
|-------|------|--------------|
| Location | Required | "Location is required" |
| Description | Required, min 20 chars | "Description is required" / "Please provide more details (at least 20 characters)" |
| Photos | At least 1 | "Please add at least one photo of the incident" |
| Police Station | Required if police involved | "Police station is required" |
| Case Number | Required if police involved | "Case number is required" |

## 🎨 UI Elements

### Colors
- **Primary**: #f05945 (Red)
- **Background**: #f5f7fc (Light blue-gray)
- **Cards**: #ffffff (White)
- **Input**: #f9f9f9 (Off-white)
- **Border**: #e0e0e0 (Light gray)
- **Success**: Green
- **Warning**: Orange
- **Error**: Red

### Icons
- 📋 Incident Details
- 🚔 Police Information
- 👥 Witness Information
- 📸 Photos & Evidence
- 📷 Camera
- 🖼️ Gallery

## 🔔 Feedback Messages

### Success
```
"Incident report submitted successfully"
Green snackbar, 2 seconds
```

### Errors
```
❌ "Please add at least one photo of the incident"
Orange snackbar (validation)

❌ "Failed to submit report: [error message]"
Red snackbar (submission failed)
```

### Info
```
ℹ️ "Vehicle data refreshed"
Green snackbar (when pulling to refresh)
```

## 🔒 Security & Privacy

### Client-Side Validation
- Form validation before submission
- Photo size validation
- Required field checks

### Data Protection
- Photos stored locally until submission
- Secure multipart upload (when backend ready)
- Driver authentication required

## 🚨 Common Use Cases

### Use Case 1: Traffic Accident
```
Incident Type: Accident
Date/Time: [When it happened]
Location: "Highway 1, Exit 42"
Description: "Rear-ended at red light. Other driver admitted fault."
Injuries: No
Police Involved: Yes
Police Station: "Highway Patrol Station #5"
Officer Name: "Officer Johnson"
Case Number: "HP-2025-0045"
Witness: "Name: Jane Smith, Phone: 555-9876"
Photos: [Damage to rear, other vehicle, scene, police report]
```

### Use Case 2: Vehicle Theft
```
Incident Type: Theft
Date/Time: [When discovered]
Location: "Parking lot at 123 Main St"
Description: "Vehicle broken into, GPS unit stolen from dashboard"
Injuries: No
Police Involved: Yes
Police Station: "Central Police Station"
Case Number: "CPS-2025-1234"
Photos: [Broken window, missing GPS mount, interior damage]
```

### Use Case 3: Hit and Run
```
Incident Type: Hit and Run
Date/Time: [When it happened]
Location: "Parked at customer location"
Description: "Vehicle struck while parked. No note left."
Injuries: No
Police Involved: Yes
Case Number: "Required for insurance"
Photos: [Damage, scene, any debris left behind]
```

## 📊 Data Captured

### Minimum Required
- Incident type
- Date & time
- Location
- Description (20+ chars)
- At least 1 photo

### If Police Involved
- Police station
- Case number
- ⚠️ Officer name (optional but recommended)

### Optional but Recommended
- Witness details
- Multiple photos (different angles)
- Injury details if applicable

## 🏁 After Submission

### What Happens Next?
1. Incident saved to database
2. Unique incident number generated (INC-YYYY-MM-DD-XXXX)
3. Email sent to driver (confirmation)
4. Email sent to dispatcher (alert)
5. Push notification to dispatcher
6. ⏳ Dispatcher reviews incident
7. ⏳ Admin contacts insurance (if needed)
8. ⏳ Status updates sent to driver

### Incident Number Format
```
INC-2025-12-06-0001
│   │    │  │  │
│   │    │  │  └─ Sequential number
│   │    │  └──── Day
│   │    └─────── Month
│   └──────────── Year
└──────────────── Prefix (Incident)
```

## 🔧 Troubleshooting

### "Please add at least one photo"
**Problem**: Trying to submit without photos  
**Solution**: Add minimum 1 photo using camera or gallery

### Camera/Gallery not opening
**Problem**: Permission denied  
**Solution**: Grant camera/storage permission in device settings

### "Description is required"
**Problem**: Description field empty or too short  
**Solution**: Write at least 20 characters describing the incident

### Police fields showing errors
**Problem**: Police involved but fields empty  
**Solution**: Fill required fields (Police Station, Case Number)

## 📱 Device Requirements

### Permissions Needed
- 📷 Camera (for taking photos)
- 🖼️ Storage/Gallery (for selecting photos)

### Platform Support
- iOS (image_picker ^1.1.2)
- Android (image_picker ^1.1.2)

## 💡 Tips for Best Results

### Photos
1. Take clear, well-lit photos
2. Capture multiple angles
3. Include vehicle damage
4. Photo the other vehicle (if accident)
5. Photo the scene/location
6. Photo any police report documents

### Description
1. Be specific and factual
2. Include time, location, weather
3. Describe sequence of events
4. Mention other parties involved
5. Note any witnesses
6. Avoid speculation, stick to facts

### Police Case
1. Get police report filed immediately
2. Keep case number safe
3. Take photo of police report
4. Note officer badge number
5. Request copy of report

## 🎓 Training Quick Reference

### For Drivers
```
WHAT TO DO AFTER AN INCIDENT:
1. Ensure safety first
2. Call police if needed
3. Take photos
4. Get witness info
5. Open app → My Vehicle → Report a Problem
6. Fill all required fields
7. Upload photos
8. Submit report
9. Note incident number
10. Wait for confirmation email
```

### For Dispatchers
```
WHEN INCIDENT REPORTED:
1. Receive email/push notification
2. Review incident details
3. Contact driver if needed
4. Notify insurance company
5. Update incident status
6. Add admin notes
7. Follow up until resolved
```

## 📞 Support

### If You Need Help
1. Check this guide
2. Review validation errors
3. Ensure all required fields filled
4. Contact dispatch if issues persist

## ✨ Future Features

### Coming Soon
- 📍 GPS auto-location
- 🎙️ Voice-to-text for description
- 📋 Incident templates
- 📊 Status tracking timeline
- 🏥 Medical report attachments
- 📄 Police report PDF upload
- ⚡ Emergency contact quick dial

---

**Need Help?** Contact dispatch or IT support.

**Technical Issues?** Check INCIDENT_REPORT_IMPLEMENTATION_SUMMARY.md
