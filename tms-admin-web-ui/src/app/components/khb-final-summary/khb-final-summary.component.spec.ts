import { TestBed } from '@angular/core/testing';
import { HttpClient } from '@angular/common/http';

import { AuthService } from '../../services/auth.service';
import { KhbFinalSummaryComponent } from './khb-final-summary.component';

describe('KhbFinalSummaryComponent', () => {
  beforeEach(async () => {
    const authSpy = jasmine.createSpyObj('AuthService', ['getToken']);
    authSpy.getToken.and.returnValue('token');
    const httpSpy = jasmine.createSpyObj('HttpClient', ['get']);

    await TestBed.configureTestingModule({
      imports: [KhbFinalSummaryComponent],
      providers: [
        { provide: AuthService, useValue: authSpy },
        { provide: HttpClient, useValue: httpSpy },
      ],
    }).compileComponents();
  });

  it('renders driverName when present', () => {
    const fixture = TestBed.createComponent(KhbFinalSummaryComponent);
    const component = fixture.componentInstance;
    component.summaryData = [
      {
        trip: 'T1',
        truckNo: 'KH-1',
        driverName: 'Driver A',
        location: '',
        distributorName: '',
        soNumber: '',
      },
    ];
    fixture.detectChanges();

    expect(fixture.nativeElement.textContent).toContain('Driver A');
  });

  it('falls back to driverFullName then assignedDriver then Unassigned', () => {
    const fixture = TestBed.createComponent(KhbFinalSummaryComponent);
    const component = fixture.componentInstance;
    component.summaryData = [
      {
        trip: 'T1',
        truckNo: 'KH-1',
        driverFullName: 'Driver Full',
        location: '',
        distributorName: '',
        soNumber: '',
      },
      {
        trip: 'T2',
        truckNo: 'KH-2',
        assignedDriver: 'Assigned Driver',
        location: '',
        distributorName: '',
        soNumber: '',
      },
      { trip: 'T3', truckNo: 'KH-3', location: '', distributorName: '', soNumber: '' },
    ];
    fixture.detectChanges();

    const text = fixture.nativeElement.textContent;
    expect(text).toContain('Driver Full');
    expect(text).toContain('Assigned Driver');
    expect(text).toContain('Unassigned');
  });
});
