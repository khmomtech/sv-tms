> [!WARNING]
> Legacy document notice: This file is kept for history and may be outdated.
> Use `/Users/sotheakh/Documents/develop/sv-tms/docs/README.md` for active documentation.

# Customer Validation UI Implementation Guide

## Overview
This guide provides HTML template examples for implementing user-friendly validation in the customer form modal.

## Features Implemented

### Backend
✅ `DuplicateCustomerException` handler in `GlobalExceptionHandler`
✅ Returns structured error response with HTTP 409 Conflict
✅ Field-specific error mapping (email, phone, customerCode)

### Frontend Service
✅ Client-side validation methods
✅ Email format validation
✅ Phone format validation  
✅ Async duplicate checking (email, phone, customerCode)
✅ Field availability checking

### Frontend Component
✅ Client-side pre-validation before submission
✅ Structured error handling from backend
✅ Field-specific error display methods
✅ Inline validation on blur
✅ Error clearing on field change
✅ CSS class helpers for styling

---

## HTML Template Examples

### 1. Error Summary Banner (Top of Form)

```html
<!-- Validation Error Summary -->
<div *ngIf="hasErrors()" class="mb-4 p-4 bg-red-50 border border-red-200 rounded-lg">
  <div class="flex items-start">
    <svg class="w-5 h-5 text-red-600 mt-0.5" fill="currentColor" viewBox="0 0 20 20">
      <path fill-rule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zM8.707 7.293a1 1 0 00-1.414 1.414L8.586 10l-1.293 1.293a1 1 0 101.414 1.414L10 11.414l1.293 1.293a1 1 0 001.414-1.414L11.414 10l1.293-1.293a1 1 0 00-1.414-1.414L10 8.586 8.707 7.293z" clip-rule="evenodd"/>
    </svg>
    <div class="ml-3 flex-1">
      <h3 class="text-sm font-medium text-red-800">
        Please correct the following {{ getErrorCount() }} error(s):
      </h3>
      <ul class="mt-2 text-sm text-red-700 list-disc list-inside space-y-1">
        <li *ngFor="let error of getGroupedErrors()">
          <span class="font-semibold">{{ error.field }}:</span> {{ error.message }}
        </li>
      </ul>
    </div>
  </div>
</div>
```

### 2. Customer Code Field with Validation

```html
<!-- Customer Code -->
<div class="mb-4">
  <label class="block text-sm font-medium text-gray-700 mb-2">
    Customer Code
    <span class="text-red-500">*</span>
  </label>
  <div class="flex gap-2">
    <input
      type="text"
      [(ngModel)]="selectedCustomer.customerCode"
      [class]="'flex-1 px-3 py-2 border rounded-lg focus:outline-none focus:ring-2 ' + getFieldClass('customerCode')"
      placeholder="e.g., CUST0001"
      (blur)="checkCustomerCodeDuplicate()"
      (focus)="clearFieldError('customerCode')"
      [title]="getFieldTooltip('customerCode')"
    />
    <button
      type="button"
      (click)="generateCustomerCode()"
      class="px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 focus:outline-none focus:ring-2 focus:ring-blue-500"
      title="Generate next sequential code"
    >
      Generate
    </button>
  </div>
  
  <!-- Inline Error Message -->
  <div *ngIf="hasCustomerCodeError()" class="mt-1 flex items-center text-sm text-red-600">
    <svg class="w-4 h-4 mr-1" fill="currentColor" viewBox="0 0 20 20">
      <path fill-rule="evenodd" d="M18 10a8 8 0 11-16 0 8 8 0 0116 0zm-7 4a1 1 0 11-2 0 1 1 0 012 0zm-1-9a1 1 0 00-1 1v4a1 1 0 102 0V6a1 1 0 00-1-1z" clip-rule="evenodd"/>
    </svg>
    {{ getFieldErrorMessage('customerCode') }}
  </div>
  
  <!-- Help Text (when no error) -->
  <p *ngIf="!hasCustomerCodeError()" class="mt-1 text-xs text-gray-500">
    Unique identifier for this customer. Click "Generate" for auto-generated code.
  </p>
</div>
```

### 3. Email Field with Real-time Validation

```html
<!-- Email -->
<div class="mb-4">
  <label class="block text-sm font-medium text-gray-700 mb-2">
    Email Address
    <span class="text-red-500">*</span>
  </label>
  <div class="relative">
    <input
      type="email"
      [(ngModel)]="selectedCustomer.email"
      [class]="'w-full pl-10 pr-3 py-2 border rounded-lg focus:outline-none focus:ring-2 ' + getFieldClass('email')"
      placeholder="user@example.com"
      (blur)="validateEmailFormat(); checkEmailDuplicate()"
      (focus)="clearFieldError('email')"
      [title]="getFieldTooltip('email')"
    />
    <!-- Icon -->
    <svg class="absolute left-3 top-3 w-5 h-5 text-gray-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
      <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M3 8l7.89 5.26a2 2 0 002.22 0L21 8M5 19h14a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 00-2 2v10a2 2 0 002 2z"/>
    </svg>
    
    <!-- Success Check Icon -->
    <svg *ngIf="selectedCustomer.email && !hasEmailError()" class="absolute right-3 top-3 w-5 h-5 text-green-500" fill="currentColor" viewBox="0 0 20 20">
      <path fill-rule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zm3.707-9.293a1 1 0 00-1.414-1.414L9 10.586 7.707 9.293a1 1 0 00-1.414 1.414l2 2a1 1 0 001.414 0l4-4z" clip-rule="evenodd"/>
    </svg>
  </div>
  
  <!-- Inline Error -->
  <div *ngIf="hasEmailError()" class="mt-1 flex items-center text-sm text-red-600">
    <svg class="w-4 h-4 mr-1" fill="currentColor" viewBox="0 0 20 20">
      <path fill-rule="evenodd" d="M18 10a8 8 0 11-16 0 8 8 0 0116 0zm-7 4a1 1 0 11-2 0 1 1 0 012 0zm-1-9a1 1 0 00-1 1v4a1 1 0 102 0V6a1 1 0 00-1-1z" clip-rule="evenodd"/>
    </svg>
    {{ getFieldErrorMessage('email') }}
  </div>
  
  <!-- Help Text -->
  <p *ngIf="!hasEmailError()" class="mt-1 text-xs text-gray-500">
    We'll check if this email is available when you finish typing.
  </p>
</div>
```

### 4. Phone Field with Validation

```html
<!-- Phone -->
<div class="mb-4">
  <label class="block text-sm font-medium text-gray-700 mb-2">
    Phone Number
    <span class="text-red-500">*</span>
  </label>
  <div class="relative">
    <input
      type="tel"
      [(ngModel)]="selectedCustomer.phone"
      [class]="'w-full pl-10 pr-3 py-2 border rounded-lg focus:outline-none focus:ring-2 ' + getFieldClass('phone')"
      placeholder="+1 (555) 123-4567"
      (blur)="validatePhoneFormat(); checkPhoneDuplicate()"
      (focus)="clearFieldError('phone')"
      [title]="getFieldTooltip('phone')"
    />
    <!-- Icon -->
    <svg class="absolute left-3 top-3 w-5 h-5 text-gray-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
      <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M3 5a2 2 0 012-2h3.28a1 1 0 01.948.684l1.498 4.493a1 1 0 01-.502 1.21l-2.257 1.13a11.042 11.042 0 005.516 5.516l1.13-2.257a1 1 0 011.21-.502l4.493 1.498a1 1 0 01.684.949V19a2 2 0 01-2 2h-1C9.716 21 3 14.284 3 6V5z"/>
    </svg>
    
    <!-- Success Check -->
    <svg *ngIf="selectedCustomer.phone && !hasPhoneError()" class="absolute right-3 top-3 w-5 h-5 text-green-500" fill="currentColor" viewBox="0 0 20 20">
      <path fill-rule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zm3.707-9.293a1 1 0 00-1.414-1.414L9 10.586 7.707 9.293a1 1 0 00-1.414 1.414l2 2a1 1 0 001.414 0l4-4z" clip-rule="evenodd"/>
    </svg>
  </div>
  
  <!-- Inline Error -->
  <div *ngIf="hasPhoneError()" class="mt-1 flex items-center text-sm text-red-600">
    <svg class="w-4 h-4 mr-1" fill="currentColor" viewBox="0 0 20 20">
      <path fill-rule="evenodd" d="M18 10a8 8 0 11-16 0 8 8 0 0116 0zm-7 4a1 1 0 11-2 0 1 1 0 012 0zm-1-9a1 1 0 00-1 1v4a1 1 0 102 0V6a1 1 0 00-1-1z" clip-rule="evenodd"/>
    </svg>
    {{ getFieldErrorMessage('phone') }}
  </div>
  
  <!-- Help Text -->
  <p *ngIf="!hasPhoneError()" class="mt-1 text-xs text-gray-500">
    Enter phone number with country code. Minimum 7 digits required.
  </p>
</div>
```

### 5. Customer Name Field

```html
<!-- Customer Name -->
<div class="mb-4">
  <label class="block text-sm font-medium text-gray-700 mb-2">
    Customer Name
    <span class="text-red-500">*</span>
  </label>
  <input
    type="text"
    [(ngModel)]="selectedCustomer.customerName"
    [class]="'w-full px-3 py-2 border rounded-lg focus:outline-none focus:ring-2 ' + getFieldClass('customerName')"
    placeholder="Enter full name or company name"
    (focus)="clearFieldError('customerName')"
    [title]="getFieldTooltip('customerName')"
  />
  
  <!-- Inline Error -->
  <div *ngIf="hasCustomerNameError()" class="mt-1 flex items-center text-sm text-red-600">
    <svg class="w-4 h-4 mr-1" fill="currentColor" viewBox="0 0 20 20">
      <path fill-rule="evenodd" d="M18 10a8 8 0 11-16 0 8 8 0 0116 0zm-7 4a1 1 0 11-2 0 1 1 0 012 0zm-1-9a1 1 0 00-1 1v4a1 1 0 102 0V6a1 1 0 00-1-1z" clip-rule="evenodd"/>
    </svg>
    {{ getFieldErrorMessage('customerName') }}
  </div>
</div>
```

### 6. Form Actions with Loading State

```html
<!-- Modal Footer Actions -->
<div class="flex justify-end gap-3 mt-6 pt-4 border-t border-gray-200">
  <button
    type="button"
    (click)="closeModal()"
    [disabled]="isSaving"
    class="px-4 py-2 text-gray-700 bg-white border border-gray-300 rounded-lg hover:bg-gray-50 focus:outline-none focus:ring-2 focus:ring-gray-500 disabled:opacity-50 disabled:cursor-not-allowed"
  >
    Cancel
  </button>
  
  <button
    type="submit"
    (click)="saveCustomer()"
    [disabled]="isSaving"
    class="px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 focus:outline-none focus:ring-2 focus:ring-blue-500 disabled:opacity-50 disabled:cursor-not-allowed flex items-center"
  >
    <svg *ngIf="isSaving" class="animate-spin -ml-1 mr-2 h-4 w-4 text-white" fill="none" viewBox="0 0 24 24">
      <circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4"></circle>
      <path class="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"></path>
    </svg>
    {{ isSaving ? 'Saving...' : (selectedCustomer.id ? 'Update Customer' : 'Create Customer') }}
  </button>
</div>
```

---

## Validation Flow Diagram

```
User Action → Client Validation → Server Validation → UI Feedback
     ↓              ↓                    ↓                ↓
  Input Field → Format Check → HTTP Request → Display Error
     ↓              ↓                    ↓                ↓
  On Blur → Async Check → Backend Check → Inline Message
     ↓              ↓                    ↓                ↓
  On Focus → Clear Error → Return 409 → Red Border
```

---

## Key UX Improvements

### ✅ **Proactive Validation**
- Format validation on blur
- Async duplicate checking
- Clear errors on focus

### ✅ **Visual Feedback**
- Red border for errors
- Green checkmark for valid fields
- Error icons with messages
- Loading spinner during save

### ✅ **Clear Error Messages**
- Field-specific messages
- Action-oriented text
- Context-sensitive help

### ✅ **Error Summary**
- Count of errors
- Grouped by field
- Dismissible banner

---

## Testing Checklist

- [ ] Create customer with duplicate email - shows proper error
- [ ] Create customer with duplicate phone - shows proper error
- [ ] Create customer with duplicate code - shows proper error
- [ ] Invalid email format - shows format error
- [ ] Invalid phone format - shows format error
- [ ] Empty required fields - shows required error
- [ ] Multiple validation errors - all displayed
- [ ] Error clears when field is corrected
- [ ] Success checkmark appears for valid fields
- [ ] Loading state shows during save
- [ ] Modal closes after successful save

---

## Backend Error Response Format

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

---

## Next Steps

1. ✅ Apply HTML template changes to `customer.component.html`
2. ✅ Test all validation scenarios
3. ✅ Add accessibility attributes (aria-labels, aria-invalid)
4. ✅ Implement keyboard navigation support
5. ✅ Add success notification after save
6. ✅ Consider adding field-level loading indicators for async checks

---

## Related Files

- **Backend**: `GlobalExceptionHandler.java` - DuplicateCustomerException handler
- **Service**: `custommer.service.ts` - Validation methods
- **Component**: `customer.component.ts` - Validation logic
- **Template**: `customer.component.html` - UI implementation
