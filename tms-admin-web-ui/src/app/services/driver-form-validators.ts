/**
 * Enhanced Driver Form Validators
 * Production-ready validation utilities
 */

export interface ValidationResult {
  isValid: boolean;
  message?: string;
  severity?: 'error' | 'warning';
}

export interface PhoneValidationConfig {
  countryCode: string;
  allowInternational: boolean;
}

export class DriverFormValidators {
  private static readonly EMAIL_PATTERN = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
  private static readonly PERSON_NAME_PATTERN = /^[\p{L}\p{M}\s'’-]+$/u;

  private static readonly PHONE_PATTERNS: Record<
    string,
    {
      pattern: RegExp;
      example: string;
      minDigits: number;
      maxDigits: number;
    }
  > = {
    US: {
      pattern: /^(\+1)?[\s.-]?(\d{3})[\s.-]?(\d{3})[\s.-]?(\d{4})$/,
      example: '(123) 456-7890',
      minDigits: 10,
      maxDigits: 11,
    },
    KH: {
      pattern: /^(\+855)?[\s.-]?([0-9]{1,2})[\s.-]?([0-9]{3})[\s.-]?([0-9]{4})$/,
      example: '(12) 345-6789',
      minDigits: 8,
      maxDigits: 10,
    },
    TH: {
      pattern: /^(\+66)?[\s.-]?([0-9]{1,2})[\s.-]?([0-9]{3})[\s.-]?([0-9]{4})$/,
      example: '(12) 345-6789',
      minDigits: 9,
      maxDigits: 10,
    },
    SG: {
      pattern: /^(\+65)?[\s.-]?(\d{4})[\s.-]?(\d{4})$/,
      example: '6123 4567',
      minDigits: 8,
      maxDigits: 8,
    },
  };

  private static readonly NATIONAL_ID_PATTERNS: Record<
    string,
    {
      pattern: RegExp;
      example: string;
      description: string;
      mask: string;
    }
  > = {
    US: {
      pattern: /^\d{3}-\d{2}-\d{4}$/,
      example: '123-45-6789',
      description: 'SSN: XXX-XX-XXXX (Social Security Number)',
      mask: 'XXX-XX-XXXX',
    },
    KH: {
      pattern: /^[0-9]{9,10}$/,
      example: '123456789',
      description: 'ID Card: 9-10 digits (Cambodian National ID)',
      mask: 'XXXXXXXXX',
    },
    TH: {
      pattern: /^[0-9]{13}$/,
      example: '1234567890123',
      description: 'ID Card: 13 digits (Thai National ID)',
      mask: 'XXXXXXXXXXXXX',
    },
    SG: {
      pattern: /^[STFG]\d{7}[A-Z]$/,
      example: 'S1234567A',
      description: 'NRIC: S/T/F/G + 7 digits + letter (Singapore NRIC)',
      mask: 'SXXXXXXXXA',
    },
  };

  /**
   * Validate first name
   */
  static validateFirstName(value: string): ValidationResult {
    if (!value || !value.trim()) {
      return { isValid: false, message: 'First name is required' };
    }

    if (value.trim().length < 2) {
      return { isValid: false, message: 'First name must be at least 2 characters' };
    }

    if (value.trim().length > 50) {
      return { isValid: false, message: 'First name must not exceed 50 characters' };
    }

    // Allow names in any language, including Khmer, plus common separators.
    if (!this.PERSON_NAME_PATTERN.test(value.trim())) {
      return {
        isValid: false,
        message: 'First name can only contain letters, spaces, hyphens, and apostrophes',
      };
    }

    return { isValid: true };
  }

  /**
   * Validate last name
   */
  static validateLastName(value: string): ValidationResult {
    if (!value || !value.trim()) {
      return { isValid: false, message: 'Last name is required' };
    }

    if (value.trim().length < 2) {
      return { isValid: false, message: 'Last name must be at least 2 characters' };
    }

    if (value.trim().length > 50) {
      return { isValid: false, message: 'Last name must not exceed 50 characters' };
    }

    if (!this.PERSON_NAME_PATTERN.test(value.trim())) {
      return {
        isValid: false,
        message: 'Last name can only contain letters, spaces, hyphens, and apostrophes',
      };
    }

    return { isValid: true };
  }

  /**
   * Validate email address
   */
  static validateEmail(value: string): ValidationResult {
    if (!value || !value.trim()) {
      return { isValid: true }; // Email is optional for driver
    }

    if (!this.EMAIL_PATTERN.test(value)) {
      return { isValid: false, message: 'Please enter a valid email address' };
    }

    if (value.length > 100) {
      return { isValid: false, message: 'Email must not exceed 100 characters' };
    }

    return { isValid: true };
  }

  /**
   * Validate phone number with country support
   */
  static validatePhone(value: string, countryCode: string = 'US'): ValidationResult {
    if (!value || !value.trim()) {
      return { isValid: false, message: 'Phone number is required' };
    }

    // Relaxed phone validation: do not enforce a strict visual format.
    // Accept values containing at least the minimum number of digits for the country,
    // and at most the maximum. This permits international formats and user-entered spacing/characters.
    const pattern = this.PHONE_PATTERNS[countryCode] || this.PHONE_PATTERNS['US'];
    const digitCount = value.replace(/\D/g, '').length;
    if (digitCount < pattern.minDigits || digitCount > pattern.maxDigits) {
      return {
        isValid: false,
        message: `Phone number must contain ${pattern.minDigits}-${pattern.maxDigits} digits`,
      };
    }

    return { isValid: true };
  }

  /**
   * Validate national ID number
   */
  static validateNationalId(value: string, countryCode: string = 'US'): ValidationResult {
    if (!value || !value.trim()) {
      return { isValid: false, message: 'National ID is required' };
    }

    const trimmed = value.trim().toUpperCase();

    if (trimmed.length < 5) {
      return { isValid: false, message: 'National ID is too short' };
    }

    if (trimmed.length > 20) {
      return { isValid: false, message: 'National ID is too long' };
    }

    // Validate format if pattern exists for country
    const pattern = this.NATIONAL_ID_PATTERNS[countryCode];
    if (pattern && !pattern.pattern.test(trimmed)) {
      return {
        isValid: false,
        message: `Invalid National ID format for ${countryCode}. ${pattern.description}. Example: ${pattern.example}`,
      };
    }

    return { isValid: true };
  }

  /**
   * Validate license number (deprecated - use validateNationalId instead)
   */
  static validateLicenseNumber(value: string, countryCode: string = 'US'): ValidationResult {
    // Backwards compatibility - delegates to National ID validation
    return this.validateNationalId(value, countryCode);
  }

  /**
   * Validate rating
   */
  static validateRating(value?: number): ValidationResult {
    if (!value) {
      return { isValid: true }; // Rating is optional, defaults to 5
    }

    if (!Number.isInteger(value)) {
      return { isValid: false, message: 'Rating must be a whole number' };
    }

    if (value < 1 || value > 5) {
      return { isValid: false, message: 'Rating must be between 1 and 5' };
    }

    return { isValid: true };
  }

  /**
   * Validate license expiry date
   */
  static validateLicenseExpiryDate(value?: Date): ValidationResult {
    if (!value) {
      return { isValid: true }; // Optional field
    }

    const expiryDate = new Date(value);
    const today = new Date();

    if (expiryDate < today) {
      return { isValid: false, message: 'License has expired', severity: 'error' };
    }

    // Warn if expiring within 6 months
    const sixMonthsFromNow = new Date(today.getTime() + 6 * 30 * 24 * 60 * 60 * 1000);
    if (expiryDate < sixMonthsFromNow) {
      return {
        isValid: true,
        message: 'License will expire soon',
        severity: 'warning',
      };
    }

    return { isValid: true };
  }

  /**
   * Validate password strength
   */
  static validatePassword(value: string): {
    isValid: boolean;
    score: number;
    feedback: string[];
  } {
    const feedback: string[] = [];
    let score = 0;

    if (!value) {
      return { isValid: false, score: 0, feedback: ['Password is required'] };
    }

    // Length checks
    if (value.length >= 8) score += 20;
    else feedback.push('Password must be at least 8 characters');

    if (value.length >= 12) score += 20;
    if (value.length >= 16) score += 10;

    // Character type checks
    if (/[a-z]/.test(value)) score += 15;
    else feedback.push('Add lowercase letters');

    if (/[A-Z]/.test(value)) score += 15;
    else feedback.push('Add uppercase letters');

    if (/\d/.test(value)) score += 15;
    else feedback.push('Add numbers');

    if (/[!@#$%^&*()_+\-=\[\]{};':"\\|,.<>\/?]/.test(value)) score += 15;
    else feedback.push('Add special characters (!@#$%^&*)');

    // Common patterns to avoid
    const weakPatterns = ['123456', 'password', 'qwerty', '111111', 'admin'];
    if (weakPatterns.some((p) => value.toLowerCase().includes(p))) {
      feedback.push('Avoid common patterns');
      score = Math.max(0, score - 20);
    }

    return {
      isValid: score >= 50,
      score: Math.min(score, 100),
      feedback,
    };
  }

  /**
   * Format phone number for display
   */
  static formatPhone(value: string, countryCode: string = 'US'): string {
    const digits = value.replace(/\D/g, '');

    const formatters: Record<string, (digits: string) => string> = {
      US: (d) => {
        if (d.length === 10) return `(${d.slice(0, 3)}) ${d.slice(3, 6)}-${d.slice(6)}`;
        if (d.length === 11 && d[0] === '1')
          return `+1 (${d.slice(1, 4)}) ${d.slice(4, 7)}-${d.slice(7)}`;
        return d;
      },
      KH: (d) => {
        if (d.length === 9) return `(${d.slice(0, 2)}) ${d.slice(2, 5)}-${d.slice(5)}`;
        if (d.length === 10) return `${d.slice(0, 3)}-${d.slice(3, 6)}-${d.slice(6)}`;
        return d;
      },
      TH: (d) => {
        if (d.length === 10) return `${d.slice(0, 2)}-${d.slice(2, 5)}-${d.slice(5)}`;
        return d;
      },
    };

    const formatter = formatters[countryCode] || formatters['US'];
    return formatter(digits);
  }

  /**
   * Get password strength label
   */
  static getPasswordStrengthLabel(score: number): {
    label: string;
    color: string;
    variant: 'error' | 'warning' | 'info' | 'success';
  } {
    if (score < 25) {
      return { label: 'Very Weak', color: '#dc2626', variant: 'error' };
    }
    if (score < 50) {
      return { label: 'Weak', color: '#f97316', variant: 'warning' };
    }
    if (score < 75) {
      return { label: 'Fair', color: '#eab308', variant: 'warning' };
    }
    if (score < 90) {
      return { label: 'Good', color: '#22c55e', variant: 'success' };
    }
    return { label: 'Strong', color: '#16a34a', variant: 'success' };
  }

  /**
   * Validate entire form object
   */
  static validateFormData(data: {
    firstName?: string;
    lastName?: string;
    email?: string;
    phone?: string;
    licenseNumber?: string;
    licenseExpiryDate?: Date;
    rating?: number;
    countryCode?: string;
  }): Record<string, ValidationResult> {
    const country = data.countryCode || 'US';
    const errors: Record<string, ValidationResult> = {};

    if (data.firstName !== undefined) {
      errors['firstName'] = this.validateFirstName(data.firstName);
    }

    if (data.lastName !== undefined) {
      errors['lastName'] = this.validateLastName(data.lastName);
    }

    if (data.email !== undefined) {
      errors['email'] = this.validateEmail(data.email);
    }

    if (data.phone !== undefined) {
      errors['phone'] = this.validatePhone(data.phone, country);
    }

    if (data.licenseNumber !== undefined) {
      errors['licenseNumber'] = this.validateLicenseNumber(data.licenseNumber, country);
    }

    if (data.licenseExpiryDate !== undefined) {
      errors['licenseExpiryDate'] = this.validateLicenseExpiryDate(data.licenseExpiryDate);
    }

    if (data.rating !== undefined) {
      errors['rating'] = this.validateRating(data.rating);
    }

    return errors;
  }
}

/**
 * Driver Form Model - Enhanced for production
 */
export interface DriverFormModel {
  // Basic Info
  firstName: string;
  lastName: string;
  email?: string;
  phone: string;
  emergencyPhone?: string;

  // License & Documentation
  licenseNumber: string;
  licenseExpiryDate?: Date;
  licenseClass?: 'A' | 'B' | 'C' | 'D';

  // Location
  address?: string;
  zone?: string;
  countryCode?: string;

  // Status & Rating
  isActive: boolean;
  rating: number;

  // Additional
  notes?: string;
  dateOfBirth?: Date;
  bankAccountName?: string;
  bankAccountNumber?: string;

  // Metadata
  id?: number;
  createdAt?: Date;
  updatedAt?: Date;
}

/**
 * Driver Account Model - Enhanced
 */
export interface DriverAccountModel {
  email: string;
  username: string;
  password: string;
  confirmPassword: string;
  roles: string[];
  twoFactorEnabled?: boolean;
  twoFactorMethod?: 'sms' | 'email';
}

/**
 * Form State Management
 */
export type FormStatusType = 'idle' | 'loading' | 'success' | 'error' | 'validating';

export interface FormState {
  status: FormStatusType;
  errors: Record<string, ValidationResult>;
  success?: string;
  errorMessage?: string;
  isDirty: boolean;
  isSubmitting: boolean;
}

export interface PasswordStrengthFeedback {
  score: number;
  label: string;
  color: string;
  feedback: string[];
}
