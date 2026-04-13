import { of, throwError } from 'rxjs';
import { TranslateService } from '@ngx-translate/core';

import { LoginComponent } from './login.component';

describe('LoginComponent', () => {
  const authService = jasmine.createSpyObj('AuthService', ['login']);
  const permissionGuardService = jasmine.createSpyObj('PermissionGuardService', ['loadEffectivePermissions']);
  const router = jasmine.createSpyObj('Router', ['navigate']);
  const translate = jasmine.createSpyObj<TranslateService>('TranslateService', ['instant']);

  beforeEach(() => {
    authService.login.calls.reset();
    permissionGuardService.loadEffectivePermissions.calls.reset();
    router.navigate.calls.reset();
    router.navigate.and.returnValue(Promise.resolve(true));
    translate.instant.calls.reset();
    translate.instant.and.callFake((key: string) => key);
    permissionGuardService.loadEffectivePermissions.and.returnValue(of(void 0));
  });

  it('redirects to dashboard when admin login succeeds', () => {
    const component = new LoginComponent(authService as any, permissionGuardService as any, router as any, translate);
    component.username = 'superadmin';
    component.password = 'password';
    authService.login.and.returnValue(
      of({
        token: 't',
        user: { roles: ['ADMIN'] },
      }),
    );

    component.onLogin();

    expect(authService.login).toHaveBeenCalledWith('superadmin', 'password');
    expect(router.navigate).toHaveBeenCalledWith(['/dashboard']);
  });

  it('does not call login when username or password is missing', () => {
    const component = new LoginComponent(authService as any, permissionGuardService as any, router as any, translate);
    component.username = '';
    component.password = '';

    component.onLogin();

    expect(authService.login).not.toHaveBeenCalled();
    expect(component.errorMessage).toContain('required');
  });

  it('shows invalid credentials message for 401', () => {
    const component = new LoginComponent(authService as any, permissionGuardService as any, router as any, translate);
    component.username = 'bad-user';
    component.password = 'bad-pass';
    authService.login.and.returnValue(
      throwError(() => ({
        status: 401,
        error: { message: 'Invalid username or password' },
      })),
    );

    component.onLogin();

    expect(component.errorMessage).toContain('Invalid username or password');
  });
});
