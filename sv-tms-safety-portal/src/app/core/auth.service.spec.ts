import { TestBed } from '@angular/core/testing';
import { AuthService } from './auth.service';
import { ApiService } from './api.service';

describe('AuthService', () => {
  let service: AuthService;
  beforeEach(() => {
    TestBed.configureTestingModule({ providers: [AuthService, ApiService] });
    service = TestBed.inject(AuthService);
  });
  it('should be created', () => { expect(service).toBeTruthy(); });
});
