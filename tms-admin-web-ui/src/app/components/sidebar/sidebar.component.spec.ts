import { NO_ERRORS_SCHEMA } from '@angular/core';
import { ComponentFixture, TestBed } from '@angular/core/testing';
import { TranslateFakeLoader, TranslateLoader, TranslateModule } from '@ngx-translate/core';
import { RouterTestingModule } from '@angular/router/testing';
import { of } from 'rxjs';

import { AdminNotificationService } from '../../services/admin-notification.service';
import { AuthService } from '../../services/auth.service';
import { UiLanguageService } from '../../shared/services/ui-language.service';
import { SIDEBAR_MENU_CONFIG } from './sidebar-menu.config';
import { SidebarComponent } from './sidebar.component';
import { filterMenuTree } from './sidebar-menu.utils';

describe('SidebarComponent', () => {
  let fixture: ComponentFixture<SidebarComponent>;
  let component: SidebarComponent;

  let allowAllPermissions = true;
  let grantedPermissions = new Set<string>();

  const authServiceMock = {
    getUser: jasmine.createSpy('getUser').and.returnValue({ roles: ['ADMIN'] }),
    hasPermission: jasmine.createSpy('hasPermission').and.callFake((permission: string) => {
      return allowAllPermissions || grantedPermissions.has(permission);
    }),
  };

  const adminNotificationServiceMock = {
    unreadCount$: of(0),
  };

  const uiLanguageServiceMock = {
    language: 'en' as const,
    language$: of<'en' | 'kh'>('en'),
    translateLabel: (value: string) => value,
    translateText: (value: string) => value,
  };

  beforeEach(async () => {
    allowAllPermissions = true;
    grantedPermissions = new Set<string>();
    authServiceMock.hasPermission.calls.reset();

    await TestBed.configureTestingModule({
      imports: [
        SidebarComponent,
        RouterTestingModule,
        TranslateModule.forRoot({
          loader: { provide: TranslateLoader, useClass: TranslateFakeLoader },
        }),
      ],
      providers: [
        { provide: AuthService, useValue: authServiceMock },
        { provide: AdminNotificationService, useValue: adminNotificationServiceMock },
        { provide: UiLanguageService, useValue: uiLanguageServiceMock },
      ],
      schemas: [NO_ERRORS_SCHEMA],
    }).compileComponents();

    fixture = TestBed.createComponent(SidebarComponent);
    component = fixture.componentInstance;

    spyOn<any>(component, 'fetchCounts').and.stub();
  });

  it('should initialize and render without errors', () => {
    fixture.detectChanges();
    expect(component).toBeTruthy();
    expect(component.navItems.length).toBeGreaterThan(0);
    expect(component.filteredNavItems.length).toBeGreaterThan(0);
  });

  it('should hide item when missing single permission', () => {
    allowAllPermissions = false;
    const dashboard = component.navItems
      .find((item) => item.id === 'overview')
      ?.children?.find((child) => child.label === 'Dashboard');

    expect(dashboard).toBeDefined();
    expect(component.isNavItemVisible(dashboard!)).toBeFalse();
  });

  it('should show item when required single permission exists', () => {
    allowAllPermissions = false;
    grantedPermissions.add('dashboard:read');

    const dashboard = component.navItems
      .find((item) => item.id === 'overview')
      ?.children?.find((child) => child.label === 'Dashboard');

    expect(dashboard).toBeDefined();
    expect(component.isNavItemVisible(dashboard!)).toBeTrue();
  });

  it('should allow any-of permission arrays when one permission exists', () => {
    allowAllPermissions = false;
    grantedPermissions.add('driver:manage');

    const fleet = component.navItems.find((item) => item.id === 'fleet-drivers');
    const assignments = fleet?.children?.find((item) => item.label === 'Vehicle Assignments');

    expect(assignments).toBeDefined();
    expect(component.isNavItemVisible(assignments!)).toBeTrue();
  });

  it('should show driver messages when driver messages permission exists', () => {
    allowAllPermissions = false;
    grantedPermissions.add('driver:messages:read');

    const fleet = component.navItems.find((item) => item.id === 'fleet-drivers');
    const driverChat = fleet?.children?.find((item) => item.label === 'Driver Chat');

    expect(driverChat).toBeDefined();
    expect(component.isNavItemVisible(driverChat!)).toBeTrue();
  });

  it('should keep parent visible when query matches parent label', () => {
    component.searchQuery = 'dispatch';
    component.filterMenuItems();

    const dispatch = component.filteredNavItems.find((item) => item.id === 'dispatch-safety');
    expect(dispatch).toBeDefined();
  });

  it('should keep parent and matching child when query matches child label', () => {
    component.searchQuery = 'employees';
    component.filterMenuItems();

    const admin = component.filteredNavItems.find((item) => item.id === 'admin-settings');
    expect(admin).toBeDefined();
    expect(admin?.children?.length).toBe(1);
    expect(admin?.children?.[0].label).toBe('Employees');
  });

  it('should open dropdown for filtered section with children', () => {
    component.searchQuery = 'employees';
    component.filterMenuItems();

    expect(component.dropdowns['admin-settings']).toBeTrue();
  });

  it('should keep ancestor chain when query matches driver attendance', () => {
    component.searchQuery = 'driver attendance';
    component.filterMenuItems();

    const fleetDrivers = component.filteredNavItems.find((item) => item.id === 'fleet-drivers');
    expect(fleetDrivers).toBeDefined();
    expect(fleetDrivers?.children?.length).toBe(1);
    expect(fleetDrivers?.children?.[0].label).toBe('Driver Attendance');
  });

  it('should reset filtered items on blank query', () => {
    fixture.detectChanges();
    component.searchQuery = 'employees';
    component.filterMenuItems();
    expect(component.filteredNavItems.length).toBeLessThan(component.navItems.length);

    component.searchQuery = '   ';
    component.filterMenuItems();

    expect(component.filteredNavItems.length).toBeGreaterThan(0);
  });

  it('should reset to permission-visible items when query is cleared', () => {
    allowAllPermissions = false;
    grantedPermissions.add('dashboard:read');

    fixture.detectChanges();
    component.searchQuery = 'dispatch';
    component.filterMenuItems();
    expect(component.filteredNavItems.length).toBe(0);

    component.clearSearch();
    expect(component.filteredNavItems.length).toBe(1);
    expect(component.filteredNavItems[0].id).toBe('overview');
  });

  it('should return no results for query when matching items are unauthorized', () => {
    allowAllPermissions = false;
    grantedPermissions.add('dashboard:read');

    fixture.detectChanges();
    component.searchQuery = 'dispatch';
    component.filterMenuItems();

    expect(component.filteredNavItems.length).toBe(0);
  });

  it('should not mutate menu config during filtering', () => {
    const before = JSON.stringify(SIDEBAR_MENU_CONFIG);

    const filtered = filterMenuTree(SIDEBAR_MENU_CONFIG, 'employees', () => true);

    expect(filtered.length).toBeGreaterThan(0);
    expect(JSON.stringify(SIDEBAR_MENU_CONFIG)).toBe(before);
  });

  it('should auto-expand dropdown containing current route', () => {
    spyOnProperty((component as any).router, 'url', 'get').and.returnValue('/admin/roles');

    component.navItems
      .filter((item) => item.children && item.id)
      .forEach((item) => {
        component.dropdowns[item.id!] = false;
      });

    (component as any).expandActiveGroups();

    expect(component.dropdowns['admin-settings']).toBeTrue();
  });

  it('should auto-expand nested section for fleet-drivers sub-routes', () => {
    spyOnProperty((component as any).router, 'url', 'get').and.returnValue(
      '/fleet/drivers/attendance',
    );

    component.navItems
      .filter((item) => item.children && item.id)
      .forEach((item) => {
        component.dropdowns[item.id!] = false;
      });

    (component as any).expandActiveGroups();

    expect(component.dropdowns['fleet-drivers']).toBeTrue();
  });

  it('should keep only selected dropdown open when toggling', () => {
    component.dropdowns = {
      overview: true,
      'dispatch-safety': false,
    };

    component.toggleDropdown('dispatch-safety');

    expect(component.dropdowns['overview']).toBeFalse();
    expect(component.dropdowns['dispatch-safety']).toBeTrue();

    component.toggleDropdown('dispatch-safety');
    expect(component.dropdowns['dispatch-safety']).toBeFalse();
  });

  it('should hide advanced entries by default and show them when toggled on', () => {
    fixture.detectChanges();

    component.searchQuery = 'dynamic permissions';
    component.filterMenuItems();
    expect(component.filteredNavItems.length).toBe(0);

    component.toggleAdvanced();
    component.searchQuery = 'dynamic permissions';
    component.filterMenuItems();

    const admin = component.filteredNavItems.find((item) => item.id === 'admin-settings');
    expect(admin).toBeDefined();
  });

  it('should emit requestClose on mobile nav click', () => {
    const emitSpy = spyOn(component.requestClose, 'emit');
    spyOnProperty(window, 'innerWidth', 'get').and.returnValue(700);

    component.onNavItemClick();

    expect(emitSpy).toHaveBeenCalled();
  });
});
