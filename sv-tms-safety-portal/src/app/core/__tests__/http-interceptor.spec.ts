import { AppHttpInterceptor } from '../http-interceptor';
import { AuthService } from '../auth.service';
import { HttpHandler, HttpRequest, HttpEvent, HttpErrorResponse, HttpResponse } from '@angular/common/http';
import { of, throwError } from 'rxjs';

describe('AppHttpInterceptor', () => {
  it('calls refreshToken on 401 and retries the request', (done) => {
    // mock AuthService
    const mockAuth: Partial<AuthService> = {
      token: null,
      refreshToken: jasmine.createSpy('refreshToken').and.callFake(() => {
        (mockAuth as any).token = 'new-token';
        return Promise.resolve(true);
      })
    };

    // track requests seen by handler
    const seenRequests: HttpRequest<any>[] = [];
    let call = 0;

    const handler: HttpHandler = {
      handle(req: HttpRequest<any>) {
        seenRequests.push(req);
        call++;
        if (call === 1) {
          return throwError(() => new HttpErrorResponse({ status: 401, statusText: 'Unauthorized' }));
        }
        return of(new HttpResponse({ status: 200, body: { ok: true } })) as any;
      }
    };

    const interceptor = new AppHttpInterceptor(mockAuth as AuthService);
    const req = new HttpRequest('GET', '/test');

    const res$ = interceptor.intercept(req, handler);
    res$.subscribe({
      next: (ev: HttpEvent<any>) => {
        expect((mockAuth.refreshToken as jasmine.Spy).calls.count()).toBe(1, 'refreshToken called once');
        expect(seenRequests.length).toBe(2, 'request retried');
        // second request should include Authorization header set to new token
        const second = seenRequests[1];
        expect(second.headers.get('Authorization')).toBe('Bearer new-token');
        done();
      },
      error: (err) => done.fail(err)
    });
  });
});
