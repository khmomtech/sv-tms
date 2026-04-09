export interface IndividualDetails {
  firstName: string;
  lastName: string;
  dateOfBirth?: string; // Use ISO string format 'YYYY-MM-DD'
  gender: 'MALE' | 'FEMALE' | 'OTHER';
  nationalId?: string;
  passportNumber?: string;
}
