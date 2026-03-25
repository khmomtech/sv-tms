import { MaintenanceRecordsComponent } from './maintenance-records.component';

describe('MaintenanceRecordsComponent', () => {
  const createComponent = () => new MaintenanceRecordsComponent({} as any, {} as any, {} as any);

  it('filters vehicles by license plate text', () => {
    const component = createComponent();
    component.vehicles = [
      { id: 1, licensePlate: '2AB-1111' } as any,
      { id: 2, licensePlate: '3CD-2222' } as any,
    ];
    component.vehicleSearch = '2ab';

    expect(component.filteredVehicles.length).toBe(1);
    expect(component.filteredVehicles[0].id).toBe(1);
  });

  it('builds summary from MR/WO lists', () => {
    const component = createComponent();
    component.mrs = { content: [{ requestedAt: '2026-01-01T00:00:00Z' }] } as any;
    component.wos = {
      content: [
        { status: 'OPEN', completedAt: null, scheduledDate: '2026-01-02T00:00:00Z' },
        { status: 'COMPLETED', completedAt: '2026-01-03T00:00:00Z' },
      ],
    } as any;

    expect(component.summary.totalMrs).toBe(1);
    expect(component.summary.totalWos).toBe(2);
    expect(component.summary.openWos).toBe(1);
    expect(component.summary.lastMaintenanceDate).not.toBe('-');
  });
});
