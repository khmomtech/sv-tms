import { TestBed } from '@angular/core/testing';
import { SafetyService } from './safety.service';
import { ApiService } from './api.service';

describe('SafetyService', () => {
  let service: SafetyService;
  beforeEach(()=>{
    TestBed.configureTestingModule({ providers: [SafetyService, ApiService] });
    service = TestBed.inject(SafetyService);
  });
  it('should be created', ()=> expect(service).toBeTruthy());
});
