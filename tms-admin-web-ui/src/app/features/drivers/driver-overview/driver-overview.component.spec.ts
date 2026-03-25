import { ComponentFixture, TestBed } from '@angular/core/testing';
import { of } from 'rxjs';
import { DriverOverviewComponent } from './driver-overview.component';
import { DriverOverviewService } from './driver-overview.service';
import type { DriverStatsDto } from './driver-overview.models';
import type { UncompliantDriverDto } from './uncompliant-driver.dto';

describe('DriverOverviewComponent', () => {
  let fixture: ComponentFixture<DriverOverviewComponent>;
  let component: DriverOverviewComponent;
  let overviewService: jasmine.SpyObj<DriverOverviewService>;

  const mockStats: DriverStatsDto = {
    totalDrivers: 5,
    svEmployees: 2,
    partnerDrivers: 2,
    exitDrivers: 1,
    activeDrivers: 4,
    suspendedDrivers: 0,
    onlineDrivers: 3,
    onTripDrivers: 1,
    offlineDrivers: 1,
    expiredDocuments: 0,
    nearExpiryDocuments: 1,
    utilizationRate: 25,
  };
  const mockUncompliantDrivers: UncompliantDriverDto[] = [];

  beforeEach(async () => {
    const spy = jasmine.createSpyObj('DriverOverviewService', [
      'getStats',
      'getUncompliantDrivers',
    ]);
    overviewService = spy;
    overviewService.getStats.and.returnValue(of(mockStats));
    overviewService.getUncompliantDrivers.and.returnValue(of(mockUncompliantDrivers));

    await TestBed.configureTestingModule({
      imports: [DriverOverviewComponent],
      providers: [{ provide: DriverOverviewService, useValue: overviewService }],
    }).compileComponents();

    fixture = TestBed.createComponent(DriverOverviewComponent);
    component = fixture.componentInstance;
    fixture.detectChanges();
  });

  it('loads stats on init', () => {
    expect(overviewService.getStats).toHaveBeenCalled();
    expect(overviewService.getUncompliantDrivers).toHaveBeenCalled();
    expect(component.stats).toEqual(mockStats);
    expect(component.errorMessage).toBeNull();
  });

  it('refresh re-fetches stats', () => {
    overviewService.getStats.calls.reset();
    overviewService.getUncompliantDrivers.calls.reset();
    component.refresh();
    expect(overviewService.getStats).toHaveBeenCalled();
    expect(overviewService.getUncompliantDrivers).toHaveBeenCalled();
  });
});
