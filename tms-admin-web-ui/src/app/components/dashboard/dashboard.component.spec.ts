import { HttpClientTestingModule } from '@angular/common/http/testing';
import type { ComponentFixture } from '@angular/core/testing';
import { TestBed } from '@angular/core/testing';
import { FormsModule } from '@angular/forms';
import { GoogleMapsModule } from '@angular/google-maps';
import { Router } from '@angular/router';

import { AuthService } from '../../services/auth.service';

import { DashboardComponent } from './dashboard.component';

describe('DashboardComponent', () => {
  let component: DashboardComponent;
  let fixture: ComponentFixture<DashboardComponent>;
  let authServiceSpy: jasmine.SpyObj<AuthService>;
  let routerSpy: jasmine.SpyObj<Router>;

  beforeEach(async () => {
    const authSpy = jasmine.createSpyObj('AuthService', ['getToken']);
    const routerMock = jasmine.createSpyObj('Router', ['navigate']);

    await TestBed.configureTestingModule({
      imports: [HttpClientTestingModule, FormsModule, GoogleMapsModule, DashboardComponent],
      providers: [
        { provide: AuthService, useValue: authSpy },
        { provide: Router, useValue: routerMock },
      ],
    }).compileComponents();

    fixture = TestBed.createComponent(DashboardComponent);
    component = fixture.componentInstance;
    authServiceSpy = TestBed.inject(AuthService) as jasmine.SpyObj<AuthService>;
    routerSpy = TestBed.inject(Router) as jasmine.SpyObj<Router>;
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });

  it('should initialize with default values', () => {
    expect(component.loadingSummary).toEqual([]);
    expect(component.summaryStats).toEqual([]);
    expect(component.topDrivers).toEqual([]);
    expect(component.liveDrivers).toEqual([]);
    expect(component.isLoading).toBeFalsy();
  });

  it('should have default filter values', () => {
    expect(component.filters.fromDate).toBe('');
    expect(component.filters.toDate).toBe('');
    expect(component.filters.truckType).toBe('');
    expect(component.filters.customerName).toBe('');
  });

  it('should have default map center', () => {
    expect(component.mapCenter.lat).toBe(11.5564);
    expect(component.mapCenter.lng).toBe(104.9282);
    expect(component.mapZoom).toBe(12);
  });

  it('should calculate totals correctly', () => {
    // Simulate the data that would come from the API
    component.loadingSummary = [
      { totalTrip: 10, completedLoading: 8, pending: 2, truckArrived: 7, truckNotArrived: 3 },
      { totalTrip: 5, completedLoading: 3, pending: 2, truckArrived: 4, truckNotArrived: 1 },
    ];

    // Manually call calculateTotals (we'll need to make it public or test through loadSummaryStats)
    (component as any).calculateTotals();

    expect(component.loadingSummaryTotals.totalTrip).toBe(15);
    expect(component.loadingSummaryTotals.completedLoading).toBe(11);
    expect(component.loadingSummaryTotals.pending).toBe(4);
    expect(component.loadingSummaryTotals.truckArrived).toBe(11);
    expect(component.loadingSummaryTotals.truckNotArrived).toBe(4);
    expect(component.loadingSummaryTotals.achievedPercentage).toBeCloseTo(73.33, 1);
  });

  it('should handle zero total trips in percentage calculation', () => {
    component.loadingSummary = [
      { totalTrip: 0, completedLoading: 0, pending: 0, truckArrived: 0, truckNotArrived: 0 },
    ];

    (component as any).calculateTotals();

    expect(component.loadingSummaryTotals.achievedPercentage).toBe(0);
  });
});
