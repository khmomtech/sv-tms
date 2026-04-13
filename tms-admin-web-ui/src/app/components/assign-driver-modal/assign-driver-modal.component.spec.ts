import { FormBuilder } from '@angular/forms';
import { of } from 'rxjs';

import { AssignDriverModalComponent } from './assign-driver-modal.component';

describe('AssignDriverModalComponent', () => {
  const dispatchServiceMock = {
    getAvailableDrivers: jasmine
      .createSpy('getAvailableDrivers')
      .and.returnValue(of({ data: [{ id: 1, name: 'Driver One' }] })),
  };
  const driverServiceMock = {
    searchDrivers: jasmine.createSpy('searchDrivers').and.returnValue(of({ data: [] })),
  };
  const toastrMock = {
    success: jasmine.createSpy('success'),
  };

  function createComponent(): AssignDriverModalComponent {
    return new AssignDriverModalComponent(
      new FormBuilder(),
      dispatchServiceMock as any,
      driverServiceMock as any,
      toastrMock as any,
    );
  }

  beforeEach(() => {
    dispatchServiceMock.getAvailableDrivers.calls.reset();
    driverServiceMock.searchDrivers.calls.reset();
    toastrMock.success.calls.reset();
  });

  it('should initialize forceReassignment with default input value', () => {
    const component = createComponent();
    component.defaultForceReassignment = true;

    component.ngOnInit();

    expect(component.form.get('forceReassignment')?.value).toBeTrue();
  });

  it('should emit both legacy and detailed submit events', () => {
    const component = createComponent();
    component.allowForceReassignment = true;
    component.defaultForceReassignment = false;
    component.drivers = [{ id: 7, name: 'Sok' }];
    component.currentDriverId = null;
    component.ngOnInit();

    const legacySpy = jasmine.createSpy('legacySpy');
    const detailedSpy = jasmine.createSpy('detailedSpy');
    component.submitAssign.subscribe(legacySpy);
    component.submitAssignDetailed.subscribe(detailedSpy);

    component.form.patchValue({
      driverId: 7,
      forceReassignment: true,
    });
    component.submit();

    expect(legacySpy).toHaveBeenCalledWith(7);
    expect(detailedSpy).toHaveBeenCalledWith({ driverId: 7, forceReassignment: true });
    expect(toastrMock.success).toHaveBeenCalled();
  });
});
