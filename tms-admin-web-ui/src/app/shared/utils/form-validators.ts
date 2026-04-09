import { AbstractControl, ValidationErrors, ValidatorFn } from '@angular/forms';

/**
 * Custom Form Validators
 *
 * Reusable validators for common form validation scenarios.
 * Use with Angular Reactive Forms.
 *
 * @example
 * this.form = this.fb.group({
 *   phone: ['', [Validators.required, FormValidators.phone()]],
 *   url: ['', [FormValidators.url()]],
 *   email: ['', [Validators.required, Validators.email, FormValidators.emailDomain(['company.com'])]],
 * });
 */
export class FormValidators {
  /**
   * Validates phone number format (supports international formats)
   */
  static phone(): ValidatorFn {
    return (control: AbstractControl): ValidationErrors | null => {
      if (!control.value) return null;

      // Supports: +1234567890, (123) 456-7890, 123-456-7890, etc.
      const phoneRegex = /^[\+]?[(]?[0-9]{1,4}[)]?[-\s\.]?[(]?[0-9]{1,4}[)]?[-\s\.]?[0-9]{1,9}$/;

      return phoneRegex.test(control.value) ? null : { phone: true };
    };
  }

  /**
   * Validates URL format
   */
  static url(): ValidatorFn {
    return (control: AbstractControl): ValidationErrors | null => {
      if (!control.value) return null;

      try {
        new URL(control.value);
        return null;
      } catch {
        return { url: true };
      }
    };
  }

  /**
   * Validates email domain against whitelist
   */
  static emailDomain(allowedDomains: string[]): ValidatorFn {
    return (control: AbstractControl): ValidationErrors | null => {
      if (!control.value) return null;

      const email = control.value.toLowerCase();
      const domain = email.split('@')[1];

      if (!domain) return { emailDomain: true };

      const isAllowed = allowedDomains.some(
        (allowed) =>
          domain === allowed.toLowerCase() || domain.endsWith('.' + allowed.toLowerCase()),
      );

      return isAllowed ? null : { emailDomain: { allowedDomains } };
    };
  }

  /**
   * Validates that value matches another control's value (password confirmation)
   */
  static matchField(fieldName: string): ValidatorFn {
    return (control: AbstractControl): ValidationErrors | null => {
      if (!control.parent) return null;

      const matchingControl = control.parent.get(fieldName);
      if (!matchingControl) return null;

      return control.value === matchingControl.value ? null : { matchField: { fieldName } };
    };
  }

  /**
   * Validates minimum age based on date of birth
   */
  static minAge(minAge: number): ValidatorFn {
    return (control: AbstractControl): ValidationErrors | null => {
      if (!control.value) return null;

      const birthDate = new Date(control.value);
      const today = new Date();
      const age = today.getFullYear() - birthDate.getFullYear();
      const monthDiff = today.getMonth() - birthDate.getMonth();

      const actualAge =
        monthDiff < 0 || (monthDiff === 0 && today.getDate() < birthDate.getDate()) ? age - 1 : age;

      return actualAge >= minAge ? null : { minAge: { required: minAge, actual: actualAge } };
    };
  }

  /**
   * Validates file size (in bytes)
   */
  static fileSize(maxSizeBytes: number): ValidatorFn {
    return (control: AbstractControl): ValidationErrors | null => {
      if (!control.value) return null;

      const file = control.value as File;
      if (!(file instanceof File)) return null;

      return file.size <= maxSizeBytes
        ? null
        : {
            fileSize: {
              max: maxSizeBytes,
              actual: file.size,
              maxMB: (maxSizeBytes / 1024 / 1024).toFixed(2),
              actualMB: (file.size / 1024 / 1024).toFixed(2),
            },
          };
    };
  }

  /**
   * Validates file type/extension
   */
  static fileType(allowedTypes: string[]): ValidatorFn {
    return (control: AbstractControl): ValidationErrors | null => {
      if (!control.value) return null;

      const file = control.value as File;
      if (!(file instanceof File)) return null;

      const extension = file.name.split('.').pop()?.toLowerCase();
      const isAllowed = allowedTypes.some(
        (type) =>
          type.toLowerCase() === extension || file.type.toLowerCase().includes(type.toLowerCase()),
      );

      return isAllowed ? null : { fileType: { allowed: allowedTypes, actual: file.type } };
    };
  }

  /**
   * Validates number is within range
   */
  static range(min: number, max: number): ValidatorFn {
    return (control: AbstractControl): ValidationErrors | null => {
      if (!control.value && control.value !== 0) return null;

      const value = Number(control.value);
      if (isNaN(value)) return { range: { min, max } };

      return value >= min && value <= max ? null : { range: { min, max, actual: value } };
    };
  }

  /**
   * Validates alphanumeric only (no special characters)
   */
  static alphanumeric(): ValidatorFn {
    return (control: AbstractControl): ValidationErrors | null => {
      if (!control.value) return null;

      const alphanumericRegex = /^[a-zA-Z0-9]*$/;
      return alphanumericRegex.test(control.value) ? null : { alphanumeric: true };
    };
  }

  /**
   * Validates no whitespace
   */
  static noWhitespace(): ValidatorFn {
    return (control: AbstractControl): ValidationErrors | null => {
      if (!control.value) return null;

      const hasWhitespace = /\s/.test(control.value);
      return !hasWhitespace ? null : { noWhitespace: true };
    };
  }

  /**
   * Get user-friendly error message for validation errors
   */
  static getErrorMessage(errors: ValidationErrors | null, fieldName = 'Field'): string {
    if (!errors) return '';

    if (errors['required']) return `${fieldName} is required`;
    if (errors['email']) return 'Please enter a valid email address';
    if (errors['phone']) return 'Please enter a valid phone number';
    if (errors['url']) return 'Please enter a valid URL';
    if (errors['minlength'])
      return `Minimum ${errors['minlength'].requiredLength} characters required`;
    if (errors['maxlength'])
      return `Maximum ${errors['maxlength'].requiredLength} characters allowed`;
    if (errors['min']) return `Minimum value is ${errors['min'].min}`;
    if (errors['max']) return `Maximum value is ${errors['max'].max}`;
    if (errors['pattern']) return 'Please enter a valid format';
    if (errors['emailDomain'])
      return `Only emails from ${errors['emailDomain'].allowedDomains.join(', ')} are allowed`;
    if (errors['matchField']) return `Must match ${errors['matchField'].fieldName}`;
    if (errors['minAge']) return `Minimum age is ${errors['minAge'].required} years`;
    if (errors['fileSize']) return `File size must be less than ${errors['fileSize'].maxMB} MB`;
    if (errors['fileType'])
      return `Only ${errors['fileType'].allowed.join(', ')} files are allowed`;
    if (errors['range'])
      return `Value must be between ${errors['range'].min} and ${errors['range'].max}`;
    if (errors['alphanumeric']) return 'Only letters and numbers are allowed';
    if (errors['noWhitespace']) return 'Whitespace is not allowed';

    return 'Invalid value';
  }
}
