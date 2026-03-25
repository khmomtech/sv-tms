import { WorkOrdersComponent } from './work-orders.component';

describe('WorkOrdersComponent', () => {
  const createComponent = () =>
    new WorkOrdersComponent(
      {} as any,
      {} as any,
      {} as any,
      {} as any,
      {} as any,
      {} as any,
      {} as any,
    );

  it('computes work order KPIs from current page rows', () => {
    const component = createComponent();
    component.page = {
      content: [
        { status: 'OPEN' } as any,
        { status: 'IN_PROGRESS' } as any,
        { status: 'WAITING_PARTS' } as any,
        { status: 'COMPLETED' } as any,
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

    expect(component.kpis.open).toBe(1);
    expect(component.kpis.inProgress).toBe(1);
    expect(component.kpis.waitingParts).toBe(1);
    expect(component.kpis.completed).toBe(1);
  });

  it('filters rows by search text', () => {
    const component = createComponent();
    component.page = {
      content: [
        { woNumber: 'WO-1001', vehiclePlate: '2AB-1234', title: 'Brake repair' } as any,
        { woNumber: 'WO-1002', vehiclePlate: '2CD-7777', title: 'Oil change' } as any,
      ],
      number: 0,
      size: 10,
      totalElements: 2,
      totalPages: 1,
      first: true,
      last: true,
      empty: false,
      numberOfElements: 2,
    };

    component.filters.search = 'brake';
    expect(component.filteredRows.length).toBe(1);
    expect(component.filteredRows[0].woNumber).toBe('WO-1001');
  });
});
