> [!WARNING]
> Legacy document notice: This file is kept for history and may be outdated.
> Use `/Users/sotheakh/Documents/develop/sv-tms/docs/README.md` for active documentation.

# 🧪 Customer Validation Testing Guide

## Quick Test Plan

### Prerequisites
1. ✅ Backend running on `http://localhost:8080`
2. ✅ Frontend running on `http://localhost:4200`
3. ✅ MySQL database with existing customer data
4. ✅ Valid JWT token for authentication

---

## Test Scenarios

### 1. ✅ Test Duplicate Email Detection

**Steps:**
1. Navigate to Customers page
2. Click "Create Customer" or "New Customer" button
3. Fill in form:
   - Customer Code: (click Generate or enter unique)
   - Name: Test Customer
   - Email: `khetsothea@gmail.com` ← **Use existing email**
   - Phone: +855 12 999 999
   - Type: Individual
4. Click Save

**Expected Result:**
```
❌ Error displayed:
"Email: This email address is already in use. Please use a different email."

✅ Field highlighted with red border
✅ Error icon next to email field
✅ Error summary banner at top of form
✅ Form NOT submitted
```

**API Response:**
```json
{
  "timestamp": "2026-01-12T...",
  "status": 409,
  "error": "Duplicate Email",
  "message": "Customer with email 'khetsothea@gmail.com' already exists",
  "validationErrors": {
    "email": "This email is already in use"
  }
}
```

---

### 2. ✅ Test Duplicate Phone Detection

**Steps:**
1. Create new customer with:
   - Email: newemail@test.com (unique)
   - Phone: ← **Use existing phone number**

**Expected Result:**
```
❌ "Phone: This phone number is already in use. Please use a different number."
```

---

### 3. ✅ Test Duplicate Customer Code

**Steps:**
1. Create customer with:
   - Customer Code: CUST0001 ← **Use existing code**

**Expected Result:**
```
❌ "Customer Code: The code 'CUST0001' is already in use. Please choose a different code."
```

---

### 4. ✅ Test Invalid Email Format

**Steps:**
1. Enter email: `not-an-email`
2. Tab out of field (blur event)

**Expected Result:**
```
❌ Instant validation: "Email: Please enter a valid email address (e.g., user@example.com)"
✅ No API call made
✅ Red border appears immediately
```

---

### 5. ✅ Test Invalid Phone Format

**Steps:**
1. Enter phone: `123`
2. Tab out of field

**Expected Result:**
```
❌ "Phone: Please enter a valid phone number with at least 7 digits"
```

---

### 6. ✅ Test Required Fields

**Steps:**
1. Leave fields empty:
   - Customer Name: (empty)
   - Email: (empty)
   - Phone: (empty)
2. Click Save

**Expected Result:**
```
❌ Multiple errors:
- "Customer Name: This field is required"
- "Email: This field is required"
- "Phone: This field is required"

✅ Error count badge: "3 errors"
✅ All empty fields highlighted
```

---

### 7. ✅ Test Async Duplicate Check (On Blur)

**Steps:**
1. Enter email: `existing@email.com`
2. Tab out of field (don't submit)
3. Wait 1-2 seconds

**Expected Result:**
```
⏳ Loading indicator (optional)
   ↓
❌ Error appears: "Email: This email is already registered"
✅ API call made to check availability
✅ Error shown before form submission
```

---

### 8. ✅ Test Error Clearing

**Steps:**
1. Enter invalid email: `bad-email`
2. See error: "Invalid email format"
3. Click into email field (focus)
4. Correct to: `good@email.com`
5. Tab out (blur)

**Expected Result:**
```
✅ Error cleared on focus
✅ New validation triggered on blur
✅ Green checkmark if valid and available
```

---

### 9. ✅ Test Multiple Validation Errors

**Steps:**
1. Create customer with:
   - Email: `khetsothea@gmail.com` (duplicate)
   - Phone: (existing phone)
   - Customer Code: CUST0001 (duplicate)
2. Click Save

**Expected Result:**
```
❌ Error Summary:
"Please correct the following 3 errors:"

1. Email: This email is already in use
2. Phone: This phone number is already in use
3. Customer Code: The code 'CUST0001' is already in use

✅ All 3 fields highlighted in red
✅ Inline error under each field
✅ Form remains open for corrections
```

---

### 10. ✅ Test Successful Creation

**Steps:**
1. Fill form with all valid, unique data:
   - Customer Code: (click Generate)
   - Name: New Customer Test
   - Email: newcustomer@test.com
   - Phone: +855 12 888 888
   - Type: Individual
2. Click Save

**Expected Result:**
```
✅ Success!
- Form submits successfully
- Modal closes
- Customer list refreshes
- New customer appears in list
- No error messages
- API returns 201 Created
```

---

## Testing with Browser DevTools

### Console Logs to Monitor

```javascript
// Client-side validation
[CustomerService] Validating customer...
[CustomerService] ✅ Validation passed

// API Call
POST http://localhost:8080/api/admin/customers
Request Body: { customerName: "...", email: "...", ... }

// Error Response
Response: 409 Conflict
{
  "status": 409,
  "error": "Duplicate Email",
  "validationErrors": { "email": "This email is already in use" }
}

// Frontend Handling
[CustomerComponent] Save error: ...
[CustomerComponent] Extracted field errors: ["Email: This email is already in use"]
```

---

## Network Tab Checks

### Request
```
POST /api/admin/customers HTTP/1.1
Authorization: Bearer eyJ...
Content-Type: application/json

{
  "customerCode": "CUST0123",
  "customerName": "Test Customer",
  "email": "khetsothea@gmail.com",
  "phone": "+855123456789",
  "type": "INDIVIDUAL",
  "status": "ACTIVE"
}
```

### Response (Duplicate)
```
HTTP/1.1 409 Conflict
Content-Type: application/json

{
  "timestamp": "2026-01-12T13:32:44.391+07:00",
  "status": 409,
  "error": "Duplicate Email",
  "message": "Customer with email 'khetsothea@gmail.com' already exists",
  "validationErrors": {
    "email": "This email is already in use"
  }
}
```

---

## Automated Testing (Optional)

### Backend Unit Test
```java
@Test
void testDuplicateEmailException() {
    // Given: Existing customer with email
    Customer existing = new Customer();
    existing.setEmail("test@example.com");
    customerRepository.save(existing);
    
    // When: Create customer with same email
    Customer duplicate = new Customer();
    duplicate.setEmail("test@example.com");
    
    // Then: Should throw DuplicateCustomerException
    assertThrows(DuplicateCustomerException.class, () -> {
        customerService.saveCustomer(duplicate);
    });
}
```

### Frontend Integration Test (Playwright/Cypress)
```typescript
it('should show error for duplicate email', async () => {
  await page.click('button:has-text("New Customer")');
  await page.fill('input[name="email"]', 'existing@email.com');
  await page.fill('input[name="customerName"]', 'Test');
  await page.click('button:has-text("Save")');
  
  // Verify error message
  await expect(page.locator('.text-red-600')).toContainText(
    'This email is already in use'
  );
});
```

---

## Performance Checks

### Validation Speed
- ✅ Client-side format validation: < 10ms (instant)
- ✅ Async duplicate check: < 500ms (backend search)
- ✅ Form submission + validation: < 1s (full round trip)

### API Calls
- ✅ Format validation: 0 API calls (client-only)
- ✅ Duplicate check on blur: 1 API call per field
- ✅ Form submission: 1 API call

---

## Edge Cases to Test

1. **Network Timeout**
   - Disconnect network during async validation
   - Expected: Graceful error handling

2. **Rapid Field Changes**
   - Type → blur → type → blur quickly
   - Expected: Debounced validation, no duplicate calls

3. **Special Characters**
   - Email: `test+tag@example.com`
   - Phone: `+855 (12) 345-6789`
   - Expected: Valid formats accepted

4. **Unicode Characters**
   - Name: `កុមារ` (Khmer)
   - Expected: Accepted and saved correctly

5. **Long Inputs**
   - Email: 254 characters (max valid email length)
   - Expected: Accepted if within database limits

---

## Regression Checks

Ensure these still work after changes:
- ✅ Customer update (edit existing)
- ✅ Customer delete
- ✅ Customer search/filter
- ✅ Bulk operations
- ✅ Import from Excel
- ✅ Export to Excel

---

## Browser Compatibility

Test in:
- ✅ Chrome (latest)
- ✅ Firefox (latest)
- ✅ Safari (latest)
- ✅ Edge (latest)

---

## Accessibility Testing

- ✅ Screen reader announces errors
- ✅ Keyboard navigation works (Tab, Enter, Esc)
- ✅ Error messages have proper aria attributes
- ✅ Focus moves to first error field on validation failure

---

## Sign-off Checklist

- [ ] All 10 test scenarios passed
- [ ] Network tab shows correct HTTP status codes
- [ ] Console shows no JavaScript errors
- [ ] Error messages are user-friendly
- [ ] UI updates correctly on error/success
- [ ] Performance is acceptable (< 1s for submission)
- [ ] Mobile responsive (if applicable)
- [ ] Accessibility requirements met
- [ ] Backend logs show proper exception handling
- [ ] Database constraints are respected

---

## Known Issues / Limitations

- Async duplicate checks may result in race conditions if user types very fast
  - Mitigation: Debounce async checks by 500ms
- Backend search may be case-sensitive depending on database collation
  - Current: Email normalized to lowercase before comparison
- Phone number format varies by country
  - Current: Accepts any format with 7+ digits

---

**Testing Status**: Ready for QA ✅
