import { MaintenanceRequestsComponent } from './maintenance-requests.component';

describe('MaintenanceRequestsComponent', () => {
  const createComponent = () =>
    new MaintenanceRequestsComponent(
      {} as any,
      {} as any,
      {} as any,
      {} as any,
      {} as any,
      {} as any,
      {} as any,
      {} as any,
      {} as any,
      {} as any,
    );

  it('computes KPI counts from page content', () => {
    const component = createComponent();
    component.page = {
      content: [
        { status: 'DRAFT' } as any,
        { status: 'SUBMITTED' } as any,
        { status: 'APPROVED', workOrderId: 10 } as any,
        { status: 'REJECTED' } as any,
      ],
      number: 0,
      size: 10,
      totalElements: 4,
      totalPages: 1,
      first: true,
      last: true,
      empty: false,
      numberOfElements: 4,
    };

    expect(component.kpis.draft).toBe(1);
    expect(component.kpis.submitted).toBe(1);
    expect(component.kpis.approved).toBe(1);
    expect(component.kpis.rejected).toBe(1);
    expect(component.kpis.withWo).toBe(1);
  });

  it('filters rows by needs WO and PM only toggles', () => {
    const component = createComponent();
    component.page = {
      content: [
        { requestType: 'PM', workOrderId: null } as any,
        { requestType: 'REPAIR', workOrderId: null } as any,
        { requestType: 'PM', workOrderId: 1 } as any,
      ],
      number: 0,
      size: 10,
      totalElements: 3,
      totalPages: 1,
      first: true,
      last: true,
      empty: false,
      numberOfElements: 3,
    };

    component.filters.needsWoOnly = true;
    component.filters.pmOnly = true;

    expect(component.filteredRows.length).toBe(1);
    expect(component.filteredRows[0].requestType).toBe('PM');
    expect(component.filteredRows[0].workOrderId).toBeNull();
  });
});
