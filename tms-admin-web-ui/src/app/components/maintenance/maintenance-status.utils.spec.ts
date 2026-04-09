import {
  getMaintenanceRequestStatusClass,
  getWorkOrderStatusClass,
} from './maintenance-status.utils';

describe('maintenance-status.utils', () => {
  it('returns MR approved class', () => {
    expect(getMaintenanceRequestStatusClass('APPROVED')).toContain('text-emerald-700');
  });

  it('returns MR default class for undefined', () => {
    expect(getMaintenanceRequestStatusClass(undefined)).toContain('text-amber-700');
  });

  it('returns WO in-progress class', () => {
    expect(getWorkOrderStatusClass('IN_PROGRESS')).toContain('text-blue-700');
  });

  it('returns WO default class for undefined', () => {
    expect(getWorkOrderStatusClass(undefined)).toContain('text-indigo-700');
  });
});
