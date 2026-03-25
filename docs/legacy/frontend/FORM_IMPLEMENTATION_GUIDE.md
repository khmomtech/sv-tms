> [!WARNING]
> Legacy document notice: This file is kept for history and may be outdated.
> Use `/Users/sotheakh/Documents/develop/sv-tms/docs/README.md` for active documentation.

# Driver Form Production Implementation Guide

## Overview

This guide shows how to integrate the production-ready driver form improvements into your existing drivers component.

---

## Step 1: Update Component TypeScript

Replace the validation logic in `drivers.component.ts` with the new validators:

```typescript
import {
  DriverFormValidators,
  DriverFormModel,
} from "../../services/driver-form-validators";
import {
  FormBuilder,
  FormGroup,
  Validators,
  ReactiveFormsModule,
} from "@angular/forms";

export class DriversComponent implements OnInit, OnDestroy {
  // Use FormGroup instead of individual properties
  driverForm!: FormGroup;
  saveSuccess = "";
  isSubmitting = false;
  fieldWarnings: Record<string, string> = {};

  constructor(
    private readonly driverService: DriverService,
    private readonly router: Router,
    private readonly adminNotificationService: AdminNotificationService,
    private readonly fb: FormBuilder,
  ) {}

  ngOnInit(): void {
    this.initializeForm();
    // ... rest of init
  }

  /**
   * Initialize driver form with validation
   */
  private initializeForm(): void {
    this.driverForm = this.fb.group({
      firstName: ["", Validators.required],
      lastName: ["", Validators.required],
      email: [""],
      phone: ["", Validators.required],
      emergencyPhone: [""],
      licenseNumber: ["", Validators.required],
      licenseExpiryDate: [""],
      licenseClass: [""],
      address: [""],
      zone: [""],
      dateOfBirth: [""],
      notes: [""],
      rating: [5, [Validators.min(1), Validators.max(5)]],
      isActive: [true],
      countryCode: ["US"],
    });
  }

  /**
   * Validate single field (called on blur)
   */
  validateSingleField(fieldName: string): void {
    const value = this.driverForm.get(fieldName)?.value;
    const countryCode = this.driverForm.get("countryCode")?.value || "US";

    this.formErrors[fieldName] = "";
    this.fieldWarnings[fieldName] = "";

    // Skip empty optional fields
    if (
      !value &&
      fieldName !== "firstName" &&
      fieldName !== "lastName" &&
      fieldName !== "phone" &&
      fieldName !== "licenseNumber"
    ) {
      return;
    }

    let validation: any;

    switch (fieldName) {
      case "firstName":
        validation = DriverFormValidators.validateFirstName(value);
        break;
      case "lastName":
        validation = DriverFormValidators.validateLastName(value);
        break;
      case "email":
        validation = DriverFormValidators.validateEmail(value);
        break;
      case "phone":
        validation = DriverFormValidators.validatePhone(value, countryCode);
        break;
      case "emergencyPhone":
        if (value) {
          validation = DriverFormValidators.validatePhone(value, countryCode);
        }
        break;
      case "licenseNumber":
        validation = DriverFormValidators.validateLicenseNumber(
          value,
          countryCode,
        );
        break;
      case "licenseExpiryDate":
        validation = DriverFormValidators.validateLicenseExpiryDate(value);
        break;
      case "rating":
        validation = DriverFormValidators.validateRating(value);
        break;
    }

    if (validation && !validation.isValid) {
      this.formErrors[fieldName] = validation.message || "Invalid input";
    }

    if (validation?.severity === "warning") {
      this.fieldWarnings[fieldName] = validation.message || "";
    }
  }

  /**
   * Validate entire form before submission
   */
  validateDriverForm(): boolean {
    this.formErrors = {};
    this.fieldWarnings = {};

    const formData = this.driverForm.value;
    const countryCode = formData.countryCode || "US";

    // Validate all fields
    const errors = DriverFormValidators.validateFormData({
      firstName: formData.firstName,
      lastName: formData.lastName,
      email: formData.email,
      phone: formData.phone,
      licenseNumber: formData.licenseNumber,
      licenseExpiryDate: formData.licenseExpiryDate,
      rating: formData.rating,
      countryCode,
    });

    // Build error map
    Object.entries(errors).forEach(([field, result]) => {
      if (!result.isValid) {
        this.formErrors[field] = result.message || "Invalid input";
      } else if (result.severity === "warning") {
        this.fieldWarnings[field] = result.message || "";
      }
    });

    return Object.keys(this.formErrors).length === 0;
  }

  /**
   * Handle form submission
   */
  onSubmit(): void {
    if (!this.validateDriverForm()) {
      console.warn("Form validation failed", this.formErrors);
      return;
    }

    this.isSubmitting = true;
    this.saveSuccess = "";

    const formData = this.driverForm.value;
    const countryCode = formData.countryCode || "US";

    // Format phone numbers
    const formattedData = {
      ...formData,
      phone: DriverFormValidators.formatPhone(formData.phone, countryCode),
      emergencyPhone: formData.emergencyPhone
        ? DriverFormValidators.formatPhone(formData.emergencyPhone, countryCode)
        : undefined,
    };

    const observable = this.isEditing
      ? this.driverService.updateDriver(this.selectedDriver.id, formattedData)
      : this.driverService.addDriver(formattedData);

    observable.subscribe({
      next: (response) => {
        this.saveSuccess = `Driver ${this.isEditing ? "updated" : "created"} successfully`;
        setTimeout(() => {
          this.closeModal();
          this.loadDrivers();
        }, 1500);
      },
      error: (err) => {
        console.error("Error:", err);
        this.formErrors["general"] =
          err.error?.message || "Failed to save driver";
        this.isSubmitting = false;
      },
      complete: () => {
        this.isSubmitting = false;
      },
    });
  }

  /**
   * Check if field has validation error
   */
  hasFieldError(field: string): boolean {
    return !!this.formErrors[field];
  }

  /**
   * Get validation error message
   */
  getFieldError(field: string): string {
    return this.formErrors[field] || "";
  }

  /**
   * Check if field has warning
   */
  hasFieldWarning(field: string): boolean {
    return !!this.fieldWarnings[field];
  }

  /**
   * Get warning message
   */
  getFieldWarning(field: string): string {
    return this.fieldWarnings[field] || "";
  }

  /**
   * Open driver modal for create/edit
   */
  openDriverModal(driver?: Driver): void {
    this.isEditing = !!driver;
    this.saveSuccess = "";
    this.formErrors = {};
    this.fieldWarnings = {};

    if (driver) {
      // Populate form with existing data
      this.driverForm.patchValue({
        firstName: driver.firstName,
        lastName: driver.lastName,
        email: driver.email,
        phone: driver.phone,
        licenseNumber: driver.licenseNumber,
        licenseExpiryDate: driver.licenseExpiryDate,
        zone: driver.zone,
        rating: driver.rating || 5,
        isActive: driver.isActive ?? true,
      });
    } else {
      // Reset form for new driver
      this.driverForm.reset({
        rating: 5,
        isActive: true,
        countryCode: "US",
      });
    }

    this.selectedDriver = driver || this.getDefaultDriver();
    this.isModalOpen = true;
  }

  /**
   * Close modal and reset form
   */
  closeModal(): void {
    this.isModalOpen = false;
    this.isSubmitting = false;
    this.saveSuccess = "";
    this.driverForm.reset({
      rating: 5,
      isActive: true,
      countryCode: "US",
    });
    this.formErrors = {};
    this.fieldWarnings = {};
  }
}
```

---

## Step 2: Update Component Imports

```typescript
import { FormBuilder, FormGroup, Validators, ReactiveFormsModule } from '@angular/forms';
import { DriverFormValidators, DriverFormModel } from '../../services/driver-form-validators';

@Component({
  selector: 'app-drivers',
  standalone: true,
  imports: [
    CommonModule,
    FormsModule,
    ReactiveFormsModule,  // Add this
    MatFormFieldModule,
    MatInputModule,
    MatAutocompleteModule,
    MatIconModule,
    MatButtonModule,
    MatProgressSpinnerModule,
  ],
  // ...
})
```

---

## Step 3: Replace Template

Use the enhanced `drivers-form.component.html` template provided. Key improvements:

- FormGroup-based validation
- Field-level error messages
- Warning messages for soon-to-expire licenses
- Star rating picker
- Country code selector
- Better accessibility (ARIA labels)
- Loading states
- Success feedback
- Organized sections with fieldsets

---

## Step 4: CSS Styling (Add to Component)

```css
.star {
  font-size: 24px;
  cursor: pointer;
  color: #ccc;
  background: none;
  border: none;
  padding: 4px;
  transition: all 0.2s ease;
}

.star:hover,
.star.active {
  color: #ffc107;
  text-shadow: 0 0 2px #ffc107;
  transform: scale(1.1);
}

@keyframes spin {
  from {
    transform: rotate(0deg);
  }
  to {
    transform: rotate(360deg);
  }
}

.animate-spin {
  animation: spin 1s linear infinite;
}

input:focus,
textarea:focus,
select:focus {
  outline: none;
  box-shadow: 0 0 0 3px rgba(59, 130, 246, 0.1);
}

input[aria-invalid="true"],
textarea[aria-invalid="true"],
select[aria-invalid="true"] {
  border-color: #ef4444;
}
```

---

## Step 5: Create Account Modal Improvements

Update the account creation modal with password strength indicator:

```typescript
// In drivers.component.ts
newAccountPasswordStrength: { score: number; label: string; color: string } = {
  score: 0,
  label: 'Weak',
  color: '#dc2626',
};

onPasswordChange(password: string): void {
  const validation = DriverFormValidators.validatePassword(password);
  const strength = DriverFormValidators.getPasswordStrengthLabel(validation.score);

  this.newAccountPasswordStrength = {
    score: validation.score,
    label: strength.label,
    color: strength.color,
  };

  // Show feedback
  console.log('Password feedback:', validation.feedback);
}
```

```html
<!-- In create account modal -->
<div class="space-y-4">
  <div>
    <label class="block mb-1 text-sm font-semibold text-gray-700">
      <span class="text-red-500">*</span> Email
    </label>
    <input
      type="email"
      [(ngModel)]="newAccount.email"
      class="w-full px-4 py-2 border-2 border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
      required
    />
  </div>

  <div>
    <label class="block mb-1 text-sm font-semibold text-gray-700">
      <span class="text-red-500">*</span> Username
    </label>
    <input
      type="text"
      [(ngModel)]="newAccount.username"
      class="w-full px-4 py-2 border-2 border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
      required
    />
  </div>

  <div>
    <label class="block mb-1 text-sm font-semibold text-gray-700">
      <span class="text-red-500">*</span> Password
    </label>
    <input
      type="password"
      [(ngModel)]="newAccount.password"
      (change)="onPasswordChange(newAccount.password)"
      class="w-full px-4 py-2 border-2 border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
      required
    />

    <!-- Password strength indicator -->
    <div class="mt-2 space-y-2">
      <div class="flex items-center gap-2">
        <div class="h-2 flex-1 bg-gray-200 rounded-full overflow-hidden">
          <div
            class="h-full transition-all"
            [style.width.%]="newAccountPasswordStrength.score"
            [style.background-color]="newAccountPasswordStrength.color"
          ></div>
        </div>
        <span
          class="text-xs font-semibold"
          [style.color]="newAccountPasswordStrength.color"
        >
          {{ newAccountPasswordStrength.label }}
        </span>
      </div>
    </div>
  </div>

  <div>
    <label class="block mb-1 text-sm font-semibold text-gray-700">
      <span class="text-red-500">*</span> Confirm Password
    </label>
    <input
      type="password"
      [(ngModel)]="newAccount.confirmPassword"
      class="w-full px-4 py-2 border-2 border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
      required
    />
    <p
      *ngIf="newAccount.password !== newAccount.confirmPassword"
      class="mt-1 text-xs text-red-600"
    >
      Passwords do not match
    </p>
  </div>
</div>
```

---

## Step 6: Testing Checklist

### Unit Tests

```typescript
describe("DriverFormValidators", () => {
  it("should validate first name correctly", () => {
    expect(DriverFormValidators.validateFirstName("John").isValid).toBe(true);
    expect(DriverFormValidators.validateFirstName("").isValid).toBe(false);
    expect(DriverFormValidators.validateFirstName("J").isValid).toBe(false);
  });

  it("should validate phone numbers by country", () => {
    // US format
    expect(
      DriverFormValidators.validatePhone("(123) 456-7890", "US").isValid,
    ).toBe(true);

    // KH format
    expect(
      DriverFormValidators.validatePhone("(12) 345-6789", "KH").isValid,
    ).toBe(true);
  });

  it("should validate password strength", () => {
    const weak = DriverFormValidators.validatePassword("abc123");
    expect(weak.isValid).toBe(false);

    const strong = DriverFormValidators.validatePassword("MyP@ss123456");
    expect(strong.isValid).toBe(true);
  });
});
```

### Manual Testing

- [ ] Test form with various international phone formats
- [ ] Test license number validation by country
- [ ] Test password strength meter feedback
- [ ] Test form submission with invalid data
- [ ] Test form persistence on error
- [ ] Test modal open/close
- [ ] Test accessibility with screen reader
- [ ] Test on mobile devices
- [ ] Test keyboard navigation
- [ ] Test validation error messages

---

## Step 7: Deployment Notes

### Before Going Live:

1. Run full test suite
2. Test with production data
3. Verify no console errors
4. Test API error handling
5. Check performance with 1000+ drivers
6. Verify mobile responsiveness
7. Test accessibility compliance
8. Document expected data format
9. Create admin guide for form fields
10. Set up error monitoring/logging

---

## Migration from Old Form

If you have existing driver data, ensure:

```typescript
// Handle backward compatibility
private migrateDriverData(oldDriver: any): DriverFormModel {
  return {
    firstName: oldDriver.firstName || olddriver.fullName?.split(' ')[0] || '',
    lastName: oldDriver.lastName || olddriver.fullName?.split(' ')[1] || '',
    phone: oldDriver.phone || '',
    licenseNumber: oldDriver.licenseNumber || '',
    email: oldDriver.email,
    isActive: oldDriver.isActive ?? true,
    rating: oldDriver.rating || 5,
    // ... other fields
  };
}
```

---

## Support & Maintenance

### Common Issues:

**Q: Phone validation failing for valid numbers?**

- A: Check country code selector - ensure correct code is selected

**Q: Form submission hangs?**

- A: Check API endpoint - add timeout handling

**Q: Accessibility issues with screen readers?**

- A: Verify all inputs have proper `aria-label` and `aria-describedby`

### Future Enhancements:

- [ ] Phone number auto-formatting as user types
- [ ] License number duplicate detection
- [ ] Profile image upload
- [ ] Multi-language support for form labels
- [ ] Integration with address lookup API
- [ ] Document upload integration
