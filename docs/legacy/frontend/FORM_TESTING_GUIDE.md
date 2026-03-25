> [!WARNING]
> Legacy document notice: This file is kept for history and may be outdated.
> Use `/Users/sotheakh/Documents/develop/sv-tms/docs/README.md` for active documentation.

# 🧪 Form Testing Quick Reference

**Print this page for easy testing!**

---

## National ID Format Tests

### US (Social Security Number)
```
Format: XXX-XX-XXXX (11 characters with hyphens)
Pattern: /^\d{3}-\d{2}-\d{4}$/

VALID:     123-45-6789
❌ INVALID:   12345-6789 (missing leading zero)
❌ INVALID:   123456789 (no hyphens)
❌ INVALID:   123-456-6789 (wrong format)
```

### Cambodia
```
Format: 9-10 digits
Pattern: /^[0-9]{9,10}$/

VALID:     123456789 (9 digits)
VALID:     1234567890 (10 digits)
❌ INVALID:   12345678 (8 digits, too short)
❌ INVALID:   12345-6789 (has hyphen)
```

### Thailand
```
Format: 13 digits exactly
Pattern: /^[0-9]{13}$/

VALID:     1234567890123
❌ INVALID:   123456789012 (12 digits, too short)
❌ INVALID:   12345678901234 (14 digits, too long)
```

### Singapore
```
Format: Letter (S/T/F/G) + 7 digits + letter
Pattern: /^[STFG]\d{7}[A-Z]$/

VALID:     S1234567A
VALID:     T9876543Z
VALID:     F1111111M
❌ INVALID:   S12345678A (8 digits, too long)
❌ INVALID:   S123456A (6 digits, too short)
❌ INVALID:   1234567A (missing starting letter)
```

---

## Email Tests

```
Pattern: RFC 5322 compliant

VALID:     user@example.com
VALID:     driver123@company.co.uk
VALID:     john.doe+driver@gmail.com
❌ INVALID:   user@example (missing TLD)
❌ INVALID:   @example.com (missing username)
❌ INVALID:   user@.com (missing domain)
```

---

## Phone Tests

### US (+1)
```
Format: (123) 456-7890 or variations

VALID:     (555) 123-4567
VALID:     555-123-4567
VALID:     5551234567
❌ INVALID:   (55) 123-4567 (area code too short)
```

### Cambodia (+855)
```
Format: (12) 345-6789 or variations

VALID:     12 345-6789
VALID:     (12) 345-6789
❌ INVALID:   123456789 (no spacing)
```

### Thailand (+66)
```
Format: Similar to Cambodia

VALID:     (12) 345-6789
❌ INVALID:   (1) 2345-6789 (wrong format)
```

### Singapore (+65)
```
Format: 8 digits exactly

VALID:     6123 4567
VALID:     61234567
❌ INVALID:   612 34567 (spacing)
```

---

## 🧪 Test Scenarios

### **Scenario 1: Add US Driver**
```
Step 1: Click "Add New Driver"
Step 2: Fill form:
  - First Name: John
  - Last Name: Smith
  - Phone: (555) 123-4567
  - Country: US
  - National ID: 123-45-6789
  - Email: john@example.com
  - Address: 123 Main St, New York, NY
  - Emergency: (555) 987-6543
Step 3: Click "Add Driver"
Expected: Success, modal closes, driver appears in list
```

### **Scenario 2: Add Cambodia Driver**
```
Step 1: Click "Add New Driver"
Step 2: Fill form:
  - First Name: Sokea
  - Last Name: Phnom
  - Country: KH
  - Phone: (12) 345-6789
  - National ID: 1234567890
  - Email: sokea@example.com
Step 3: Click "Add Driver"
Expected: Success, modal closes, driver appears in list
```

### **Scenario 3: Test Validation Errors**
```
Step 1: Click "Add New Driver"
Step 2: Leave First Name empty
Step 3: Click elsewhere (blur)
Expected: Error: "First name is required"

Step 4: Enter "Jo" (too short)
Expected: Error: "First name must be at least 2 characters"

Step 5: Select Country: US
Step 6: Enter Phone: "123" (invalid for US)
Expected: Error about phone format
```

### **Scenario 4: Country-Specific Validation**
```
Step 1: Select Country: US
Step 2: Enter National ID: 123-45-6789 ✓ Accepted
Step 3: Change Country: KH
Step 4: Same ID now ✗ Rejected (wrong format for KH)
Step 5: Clear and enter: 1234567890 ✓ Accepted
Expected: Validation rules change with country
```

### **Scenario 5: Optional Fields**
```
Step 1: Fill only required fields:
  - First Name, Last Name
  - Phone (pick country)
  - National ID
Step 2: Leave optional fields blank:
  - Email
  - Address
  - Emergency Contact
  - Notes
Step 3: Submit form
Expected: Success! Optional fields not required
```

---

## 🔴 Error Messages to Expect

### National ID Errors
```
"Invalid National ID format for US. SSN: XXX-XX-XXXX 
 (Social Security Number). Example: 123-45-6789"

"Invalid National ID format for KH. ID Card: 9-10 digits 
 (Cambodian National ID). Example: 123456789"

"Invalid National ID format for TH. ID Card: 13 digits 
 (Thai National ID). Example: 1234567890123"

"Invalid National ID format for SG. NRIC: S/T/F/G + 7 digits + letter 
 (Singapore NRIC). Example: S1234567A"
```

### Email Errors
```
"Please enter a valid email address"
"Email must not exceed 100 characters"
```

### Phone Errors
```
"Phone number is required"
"Invalid phone format for US. Example: (123) 456-7890"
```

### Name Errors
```
"First name is required"
"First name must be at least 2 characters"
"First name must not exceed 50 characters"
"First name can only contain letters, spaces, hyphens, and apostrophes"
```

---

## 🎯 Checklist for Testing

### Basic Functionality
- [ ] Form opens in modal
- [ ] All 5 sections visible
- [ ] All icons render correctly
- [ ] Text is readable

### Required Fields
- [ ] First Name: Cannot be empty
- [ ] Last Name: Cannot be empty
- [ ] Phone: Cannot be empty
- [ ] National ID: Cannot be empty
- [ ] Active Status: Defaults to active

### Optional Fields
- [ ] Full Name: Can be empty
- [ ] Email: Can be empty
- [ ] Address: Can be empty
- [ ] Emergency Contact: Can be empty
- [ ] Notes: Can be empty
- [ ] Zone: Can be empty
- [ ] Rating: Can be empty (defaults to 5)

### Country-Specific Validation
- [ ] Switch country → formats change
- [ ] Each country validates its format
- [ ] Error messages are specific

### Form Submission
- [ ] Invalid form → Shows errors
- [ ] Valid form → Submits successfully
- [ ] Modal closes after success
- [ ] New driver appears in list
- [ ] List updates with new data

### Real-Time Validation
- [ ] Errors show on field blur
- [ ] Errors hide when fixed
- [ ] Can submit after fixing errors
- [ ] No console errors

### Mobile Testing
- [ ] Form usable on mobile
- [ ] Buttons easy to click
- [ ] Text readable
- [ ] Scrolling works
- [ ] No overflow issues

---

## 📊 Test Data Bank

### US Test Data
```
First Name: John
Last Name: Smith
Email: john.smith@example.com
Phone: (555) 123-4567
National ID: 123-45-6789
Address: 123 Main Street, New York, NY 10001
Emergency: (555) 987-6543
```

### Cambodia Test Data
```
First Name: Sokea
Last Name: Phnom
Email: sokea@example.com
Phone: (12) 345-6789
National ID: 1234567890
Address: Street 92, Phnom Penh
Emergency: (12) 987-6543
```

### Thailand Test Data
```
First Name: Somchai
Last Name: Thai
Email: somchai@example.com
Phone: (12) 345-6789
National ID: 1234567890123
Address: Bangkok, Thailand
Emergency: (12) 987-6543
```

### Singapore Test Data
```
First Name: Lim
Last Name: Singapore
Email: lim@example.com
Phone: 6123 4567
National ID: S1234567A
Address: Singapore
Emergency: 6198 7654
```

---

## 🐛 Known Behaviors

= Correct  
⚠️  = Expected but unusual  
❌ = Bug

```
Error messages appear on blur (not on keystroke)
Form errors clear when field becomes valid
Can submit form immediately after fixing last error
Optional fields default to empty values
⚠️  Phone format varies by country selector
⚠️  National ID field shows different help text per country
Star rating picker updates on click
Active status checkbox toggles on click
```

---

## 🔗 Quick Links

- **Main App:** http://localhost:4200/dispatcher/drivers
- **Source:** `/tms-frontend/src/app/components/drivers/`
- **Validators:** `/tms-frontend/src/app/services/driver-form-validators.ts`

---

**Print this page and keep it handy for testing!** 📋
