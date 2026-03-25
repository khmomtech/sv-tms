import { TestBed } from '@angular/core/testing';
import { FormBuilder, FormControl } from '@angular/forms';
import { of } from 'rxjs';

import { NotificationService } from '../../../../services/notification.service';
import { SettingsService } from '../../../../services/settings.service';
import { AppManagementComponent } from './app-management.component';

describe('AppManagementComponent', () => {
  let component: AppManagementComponent;
  let notificationSpy: jasmine.SpyObj<NotificationService>;
  let settingsSpy: jasmine.SpyObj<SettingsService>;

  beforeEach(() => {
    notificationSpy = jasmine.createSpyObj<NotificationService>('NotificationService', [
      'success',
      'error',
      'warn',
    ]);
    settingsSpy = jasmine.createSpyObj<SettingsService>('SettingsService', [
      'getAppManagementCatalog',
      'listValues',
      'upsert',
      'audit',
      'getAppManagementEffective',
    ]);

    settingsSpy.getAppManagementCatalog.and.returnValue(
      of({
        scopes: ['GLOBAL'],
        items: [],
        resolutionOrder: 'USER > ROLE > GLOBAL',
      }),
    );
    settingsSpy.listValues.and.returnValue(of([]));
    settingsSpy.upsert.and.returnValue(
      of({
        groupCode: 'app.policies',
        keyCode: 'nav.bottom.items',
        type: 'STRING',
        value: 'home,trips,report,profile,more',
        scope: 'GLOBAL',
      }),
    );
    settingsSpy.audit.and.returnValue(of({ content: [] }));
    settingsSpy.getAppManagementEffective.and.returnValue(
      of({
        user: { id: 1, roles: ['DRIVER'], derivedSegments: [] },
        screens: {},
        features: {},
        policies: {},
        meta: { generatedAt: new Date().toISOString(), resolutionTraceVersion: 'test' },
      }),
    );

    TestBed.configureTestingModule({
      providers: [
        FormBuilder,
        { provide: NotificationService, useValue: notificationSpy },
        { provide: SettingsService, useValue: settingsSpy },
      ],
    });

    component = TestBed.runInInjectionContext(() => new AppManagementComponent());
  });

  it('rejects invalid drawer item values', () => {
    const error = (component as any).validateDynamicPolicyByFullKey(
      'app.policies.nav.drawer.items',
      'home,invalid_item,help',
    ) as string | null;

    expect(error).toContain('Invalid drawer item');
  });

  it('rejects bottom nav without home as first item', () => {
    const error = (component as any).validateDynamicPolicyByFullKey(
      'app.policies.nav.bottom.items',
      'trips,home,profile',
    ) as string | null;

    expect(error).toContain('Bottom nav should start with "home"');
  });

  it('accepts valid quick actions', () => {
    const error = (component as any).validateDynamicPolicyByFullKey(
      'app.policies.nav.home.quick_actions',
      'my_trips,report_issue,help_center',
    ) as string | null;

    expect(error).toBeNull();
  });

  it('applyRecommended writes expected control values', () => {
    const controlName = 'app_policies_nav_bottom_items';
    component.valueForm.addControl(controlName, new FormControl(''));

    const item = {
      fullKey: 'app.policies.nav.bottom.items',
      controlName,
      valueType: 'STRING',
      spec: {
        groupCode: 'app.policies',
        keyCode: 'nav.bottom.items',
        type: 'STRING',
        defaultValue: '',
        label: 'Bottom Nav',
        description: 'Bottom nav config',
      },
    };

    component.applyRecommended(item as any);
    expect(component.valueForm.get(controlName)?.value).toBe('home,trips,report,profile,more');
  });

  it('preview simulator parses and validates effective policy values', () => {
    component.previewData = {
      user: { id: 99, roles: ['DRIVER'], derivedSegments: [] },
      screens: {},
      features: {},
      policies: {
        'nav.drawer.items': 'home,my_vehicle,settings',
        'nav.bottom.items': 'home,trips,profile,more',
        'nav.home.quick_actions': 'my_trips,documents,trip_report',
        'dispatch.actions.hidden_statuses': 'CANCELLED',
        'dispatch.actions.allowed_statuses': 'ARRIVED_LOADING,LOADING',
        'dispatch.actions.require_driver_initiated': true,
      },
      meta: { generatedAt: new Date().toISOString(), resolutionTraceVersion: 'v1' },
    };

    expect(component.previewDrawerItems()).toEqual(['home', 'my_vehicle', 'settings']);
    expect(component.previewBottomItems()).toEqual(['home', 'trips', 'profile', 'more']);
    expect(component.previewQuickActionItems()).toEqual(['my_trips', 'documents', 'trip_report']);
    expect(component.previewHiddenStatuses()).toEqual(['CANCELLED']);
    expect(component.previewAllowedStatuses()).toEqual(['ARRIVED_LOADING', 'LOADING']);
    expect(component.previewDispatchPolicyError()).toBeNull();
  });
});
