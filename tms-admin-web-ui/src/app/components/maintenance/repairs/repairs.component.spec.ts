import { RepairsComponent } from './repairs.component';

describe('RepairsComponent', () => {
  const createComponent = () => new RepairsComponent({} as any);

  it('formats currency values', () => {
    const component = createComponent();
    expect(component.formatCurrency(1200)).toContain('$');
  });

  it('applies preset breakdown days and triggers reload', () => {
    const component = createComponent();
    spyOn(component, 'load');
    component.breakdownPresetDays = 90;

    component.onPresetChange();

    expect(component.breakdownDays).toBe(90);
    expect(component.load).toHaveBeenCalled();
  });
});
