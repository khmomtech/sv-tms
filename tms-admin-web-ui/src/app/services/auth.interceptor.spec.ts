import type { HttpHandler, HttpEvent } from '@angular/common/http';
import { HttpErrorResponse, HttpRequest, HttpResponse } from '@angular/common/http';
import { of, throwError } from 'rxjs';
import type { Observable } from 'rxjs';

import { AuthInterceptor } from './auth.interceptor';
import type { AuthService } from './auth.service';

class MockHandler implements HttpHandler {
  constructor(private readonly response: HttpResponse<any> | HttpErrorResponse) {}
  handle(req: HttpRequest<any>): Observable<HttpEvent<any>> {
    return this.response instanceof HttpResponse
      ? of(this.response as HttpEvent<any>)
      : throwError(() => this.response);
  }
}

describe('AuthInterceptor', () => {
  let authService: jasmine.SpyObj<AuthService>;
  let interceptor: AuthInterceptor;

  beforeEach(() => {
    authService = jasmine.createSpyObj<AuthService>('AuthService', [
      'getToken',
      'isTokenExpired',
      'refreshToken',
      'logout',
    ]);
    // Use Injector mock for constructor
    const injectorMock = { get: () => authService } as any;
    interceptor = new AuthInterceptor(injectorMock);
  });

  it('should refresh and retry once on TOKEN_EXPIRED 401', (done) => {
    authService.getToken.and.returnValue('old.access.token');
    authService.isTokenExpired.and.returnValue(false);
    authService.refreshToken.and.returnValue(Promise.resolve('new.access.token'));

    const req = new HttpRequest('GET', '/api/protected');

    const expiredBody = { error: 'TOKEN_EXPIRED', message: 'Access token expired' };
    const error = new HttpErrorResponse({
      status: 401,
      statusText: 'Unauthorized',
      url: '/api/protected',
      error: expiredBody,
    });

    // First call returns 401 TOKEN_EXPIRED, retry should be attempted once
    const handler = new MockHandler(error);

    // Replace handler after refresh to simulate success on retry
    const successHandler: HttpHandler = {
      handle: () =>
        of(new HttpResponse({ status: 200, body: { ok: true } })) as unknown as Observable<
          HttpEvent<any>
        >,
    } as any;

    // Wrap to switch handler after refreshToken is called
    const spyHandle = spyOn(handler, 'handle').and.callFake((request: HttpRequest<any>) => {
      // If X-Retried is true, use success handler
      if (request.headers.get('X-Retried') === 'true') {
        return successHandler.handle(request);
      }
      return throwError(() => error);
    });

    interceptor.intercept(req, handler).subscribe({
      next: (event) => {
        if (event instanceof HttpResponse) {
          expect(event.status).toBe(200);
          expect(authService.refreshToken).toHaveBeenCalledTimes(1);
          expect(spyHandle).toHaveBeenCalledTimes(2); // original + retry
          done();
        }
      },
      error: (err) => {
        fail('Expected success after refresh, got error: ' + err);
        done();
      },
    });
  });

  it('should propagate 401 without TOKEN_EXPIRED when a token exists', (done) => {
    authService.getToken.and.returnValue('old.access.token');
    authService.isTokenExpired.and.returnValue(false);

    const req = new HttpRequest('GET', '/api/protected');
    const error = new HttpErrorResponse({
      status: 401,
      statusText: 'Unauthorized',
      url: '/api/protected',
      error: { error: 'INVALID_TOKEN' },
    });
    const handler = new MockHandler(error);

    interceptor.intercept(req, handler).subscribe({
      next: () => {
        fail('Expected error, got success');
        done();
      },
      error: (err) => {
        expect(authService.logout).not.toHaveBeenCalled();
        expect(authService.refreshToken).not.toHaveBeenCalled();
        expect(err.status).toBe(401);
        done();
      },
    });
  });
});
