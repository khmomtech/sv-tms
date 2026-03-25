> [!WARNING]
> Legacy document notice: This file is kept for history and may be outdated.
> Use `/Users/sotheakh/Documents/develop/sv-tms/docs/README.md` for active documentation.

# Frontend Validation & Error Handling Improvements

## Overview
Comprehensive improvements to the frontend customer validation and error handling to gracefully handle duplicate email/phone/customer code errors from the backend.

---

## Changes Made

### 1. Backend Exception Handler (Java/Spring Boot)

**File:** `tms-backend/src/main/java/com/svtrucking/logistics/exception/GlobalExceptionHandler.java`

#### Added Handler for `DuplicateCustomerException`
```java
@ExceptionHandler(DuplicateCustomerException.class)
public ResponseEntity<ErrorResponse> handleDuplicateCustomer(DuplicateCustomerException ex) {
    // Maps exception to structured error response with:
    // - HTTP Status: 409 (CONFLICT)
    // - Error type classification (Duplicate Email/Phone/Code)
    // - Field-level validation errors map
    // - Clear, user-friendly error messages
}
```

**Benefits:**
- Returns HTTP 409 (CONFLICT) instead of generic 500 errors
- Provides structured `validationErrors` map with field-specific messages
- Enables frontend to display field-level errors with context
- Distinguishes between email, phone, and customer code duplicates

**Response Format:**
```json
{
  "status": 409,
  "error": "Duplicate Email",
  "message": "Customer with email 'khetsothea@gmail.com' already exists",
  "validationErrors": {
    "email": "This email is already in use"
  }
}
```

---

### 2. Frontend Customer Service Enhancements

**File:** `tms-frontend/src/app/services/custommer.service.ts`

#### Added Validation Methods

1. **`validateCustomer(customer: Customer): string[]`**
   - Client-side validation before submission
   - Checks: required fields, email format, phone format, customer code
   - Returns array of validation error messages
   - Prevents unnecessary API calls for obviously invalid data

2. **`isEmailAvailable(email: string, currentCustomerId?: number): Observable<boolean>`**
   - Real-time email availability check via search API
   - Excludes current customer when updating
   - Used for live field validation feedback

3. **`isPhoneAvailable(phone: string, currentCustomerId?: number): Observable<boolean>`**
   - Real-time phone availability check via search API
   - Normalizes phone numbers for comparison (removes dashes/spaces)
   - Excludes current customer when updating

4. **`isCustomerCodeAvailable(code: string, currentCustomerId?: number): Observable<boolean>`**
   - Real-time customer code availability check
   - Case-insensitive comparison
   - Excludes current customer when updating

#### Helper Validation Methods

- **`isValidEmail(email: string): boolean`** - Regex-based email format validation
- **`isValidPhone(phone: string): boolean`** - Accepts 7+ digits with common separators

**Benefits:**
- Fail-fast approach with client-side validation
- Real-time feedback on field availability
- Reduces roundtrips to backend for obvious validation failures

---

### 3. Frontend Customer Component Updates

**File:** `tms-frontend/src/app/components/customer/customer.component.ts`

#### Enhanced `saveCustomer()` Method

**Three-Layer Error Handling:**

1. **Client-Side Validation (First Pass)**
   ```typescript
   const clientErrors = this.customerService.validateCustomer(this.selectedCustomer);
   if (clientErrors.length > 0) {
     this.validationErrors = clientErrors;
     this.isSaving = false;
     return; // Stop before API call
   }
   ```
   - Validates data before submitting to backend
   - Provides immediate feedback without network delay

2. **Structured Error Response Handling (Primary)**
   - Extracts errors from `error.validationErrors` map
   - Maps field names to user-friendly messages:
     - `email` → "Email: This email is already in use..."
     - `phone` → "Phone: This phone number is already in use..."
     - `customerCode` → "Customer Code: The code '...' is already in use..."
   - Maintains field context for error display

3. **Fallback Error Handling (Secondary)**
   - Parses error message string if structured errors unavailable
   - Extracts duplicate field from error text
   - Handles legacy array-based error formats
   - Generic fallback message if all else fails

#### New Validation Helper Methods

1. **`hasFieldError(fieldName: string): boolean`**
   - Check if specific field has validation error
   - Used for styling form fields red on error

2. **`getFieldErrorMessage(fieldName: string): string`**
   - Extract error message for specific field
   - Returns clean message without field prefix

3. **`getGlobalErrors(): string[]`**
   - Get non-field-specific errors
   - Useful for displaying general errors separate from field errors

4. **`checkEmailAvailability(): void`**
   - Real-time email validation on field blur/change
   - Calls service to check if email taken
   - Adds/removes error message dynamically
   - Clears outdated email errors

5. **`checkPhoneAvailability(): void`**
   - Real-time phone validation on field blur/change
   - Similar to email check
   - Normalizes phone numbers before comparison

**Benefits:**
- Graceful error handling at multiple levels
- User-friendly error messages with context
- Real-time validation feedback
- Clear distinction between client and server errors

---

## Error Response Examples

### Backend API Response - Duplicate Email
```json
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

### Backend API Response - Duplicate Phone
```json
{
  "timestamp": "2026-01-12T13:32:44.391+07:00",
  "status": 409,
  "error": "Duplicate Phone Number",
  "message": "Customer with phone number '0123456789' already exists",
  "validationErrors": {
    "phone": "This phone number is already in use"
  }
}
```

### Backend API Response - Duplicate Customer Code
```json
{
  "timestamp": "2026-01-12T13:32:44.391+07:00",
  "status": 409,
  "error": "Duplicate Customer Code",
  "message": "Customer with customer code 'CUST0001' already exists",
  "validationErrors": {
    "customerCode": "This customer code is already in use"
  }
}
```

---

## Frontend Error Display in Component

### Before (Generic Error)
```
Failed to save customer. Please check all fields and try again.
```

### After (Field-Specific Error)
```
Email: This email address is already in use. Please use a different email.
Phone: This phone number is already in use. Please use a different number.
Customer Code: The code 'CUST0001' is already in use. Please choose a different code.
```

---

## Usage Guide

### For Form Component Template

**Display validation errors:**
```html
<!-- Global errors -->
<div *ngIf="getGlobalErrors().length > 0" class="error-container">
  <div *ngFor="let error of getGlobalErrors()" class="error-message">
    {{ error }}
  </div>
</div>

<!-- Field-specific errors -->
<div class="form-group">
  <input 
    [(ngModel)]="selectedCustomer.email"
    (blur)="checkEmailAvailability()"
    [class.field-error]="hasFieldError('Email')"
  />
  <span *ngIf="hasFieldError('Email')" class="error-text">
    {{ getFieldErrorMessage('Email') }}
  </span>
</div>

<div class="form-group">
  <input 
    [(ngModel)]="selectedCustomer.phone"
    (blur)="checkPhoneAvailability()"
    [class.field-error]="hasFieldError('Phone')"
  />
  <span *ngIf="hasFieldError('Phone')" class="error-text">
    {{ getFieldErrorMessage('Phone') }}
  </span>
</div>

<div class="form-group">
  <input 
    [(ngModel)]="selectedCustomer.customerCode"
    [class.field-error]="hasFieldError('Customer Code')"
  />
  <span *ngIf="hasFieldError('Customer Code')" class="error-text">
    {{ getFieldErrorMessage('Customer Code') }}
  </span>
</div>
```

### Example CSS for Error States
```css
.field-error {
  border-color: #d32f2f;
  background-color: #ffebee;
}

.error-text {
  color: #d32f2f;
  font-size: 0.875rem;
  margin-top: 4px;
  display: block;
}

.error-container {
  background-color: #ffebee;
  border: 1px solid #d32f2f;
  border-radius: 4px;
  padding: 12px;
  margin-bottom: 16px;
}

.error-message {
  color: #d32f2f;
  margin: 4px 0;
}
```

---

## Benefits Summary

1. **Better UX**
   - Clear, field-specific error messages
   - Real-time validation feedback
   - Reduced frustration from generic errors

2. **Reduced Load**
   - Client-side validation prevents unnecessary API calls
   - Early failure detection before network roundtrip

3. **Consistency**
   - Standardized error response format
   - Predictable error message structure
   - Works across all client types (Angular, Flutter, etc.)

4. **Maintainability**
   - Centralized validation logic in service
   - Reusable validation methods
   - Clear separation of concerns

5. **Debugging**
   - Structured error responses aid troubleshooting
   - Field-level errors pinpoint exact issues
   - HTTP status codes indicate error types (409 for conflicts)

---

## Testing Scenarios

### Test Case 1: Duplicate Email
1. Create customer with email `test@example.com`
2. Attempt to create another customer with same email
3. **Expected:** Error message "Email: This email address is already in use..."
4. **Status Code:** 409 (CONFLICT)

### Test Case 2: Duplicate Phone
1. Create customer with phone `0123456789`
2. Attempt to create another customer with same phone
3. **Expected:** Error message "Phone: This phone number is already in use..."
4. **Status Code:** 409 (CONFLICT)

### Test Case 3: Duplicate Customer Code
1. Create customer with code `CUST0001`
2. Attempt to create another customer with same code
3. **Expected:** Error message "Customer Code: The code 'CUST0001' is already in use..."
4. **Status Code:** 409 (CONFLICT)

### Test Case 4: Client-Side Validation
1. Leave required fields empty
2. Click save without filling in data
3. **Expected:** Local validation errors without API call
4. **No Network Request Made**

### Test Case 5: Real-Time Email Check
1. Enter valid but already-used email
2. Blur field to trigger `checkEmailAvailability()`
3. **Expected:** Real-time error feedback within 1-2 seconds
4. **Status Code:** 200 (search results processed)

---

## Files Modified

1. ✅ `tms-backend/src/main/java/com/svtrucking/logistics/exception/GlobalExceptionHandler.java`
   - Added `@ExceptionHandler` for `DuplicateCustomerException`
   - Returns structured error response with validationErrors map

2. ✅ `tms-frontend/src/app/services/custommer.service.ts`
   - Added `validateCustomer()` method
   - Added `isEmailAvailable()` method
   - Added `isPhoneAvailable()` method
   - Added `isCustomerCodeAvailable()` method
   - Added helper validation methods

3. ✅ `tms-frontend/src/app/components/customer/customer.component.ts`
   - Enhanced `saveCustomer()` with three-layer error handling
   - Added `hasFieldError()` method
   - Added `getFieldErrorMessage()` method
   - Added `getGlobalErrors()` method
   - Added `checkEmailAvailability()` method
   - Added `checkPhoneAvailability()` method

---

## Next Steps

1. **Update customer form template** to use new helper methods
2. **Add CSS styling** for error states
3. **Test all validation scenarios** with multiple browsers
4. **Update API documentation** with new error response format
5. **Consider similar improvements** for other entities (Driver, Vehicle, etc.)

