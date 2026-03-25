import { TestBed } from '@angular/core/testing';
import { ApiService } from '../api.service';
import { AuthService } from '../auth.service';

describe('AuthService (refresh)', () => {
  let service: AuthService;
  let apiSpy: jasmine.SpyObj<ApiService>;

  beforeEach(() => {
    const spy = jasmine.createSpyObj('ApiService', ['post']);
    TestBed.configureTestingModule({ providers: [AuthService, { provide: ApiService, useValue: spy }] });
    service = TestBed.inject(AuthService);
    apiSpy = TestBed.inject(ApiService) as jasmine.SpyObj<ApiService>;
  });

  it('performs refreshToken and updates token on success', async () => {
    // arrange
    sessionStorage.setItem('refreshToken', 'mock-refresh-1');
    apiSpy.post.and.returnValue(Promise.resolve({ token: 'new-token', refreshToken: 'mock-refresh-2', user: { id: 1 } }));

    // act
    const ok = await service.refreshToken();

    // assert
    expect(ok).toBeTrue();
    expect(service.token).toBe('new-token');
    expect(sessionStorage.getItem('refreshToken')).toBe('mock-refresh-2');
  });

  it('logs out when refresh fails', async () => {
    sessionStorage.setItem('refreshToken', 'invalid');
    apiSpy.post.and.returnValue(Promise.reject(new Error('401')));

    const ok = await service.refreshToken();

    expect(ok).toBeFalse();
    expect(service.token).toBeNull();
    expect(sessionStorage.getItem('refreshToken')).toBeNull();
  });
});
