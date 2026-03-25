import { Injectable } from '@angular/core';
import { HttpEvent, HttpHandler, HttpInterceptor, HttpRequest, HttpErrorResponse } from '@angular/common/http';
import { Observable, from, throwError } from 'rxjs';
import { catchError, switchMap } from 'rxjs/operators';
import { AuthService } from './auth.service';

@Injectable()
export class AppHttpInterceptor implements HttpInterceptor {
  constructor(private auth: AuthService) {}

  intercept(req: HttpRequest<any>, next: HttpHandler): Observable<HttpEvent<any>> {
    const token = this.auth.token;
    const authReq = token ? req.clone({ setHeaders: { Authorization: `Bearer ${token}` } }) : req;

    return next.handle(authReq).pipe(
      catchError((err: HttpErrorResponse) => {
        if (err.status === 401) {
          // Attempt refresh and retry once
          return from(this.auth.refreshToken()).pipe(
            switchMap((ok) => {
              if (!ok) return throwError(() => err);
              const newToken = this.auth.token;
              const retryReq = newToken ? req.clone({ setHeaders: { Authorization: `Bearer ${newToken}` } }) : req;
              return next.handle(retryReq);
            })
          );
        }
        return throwError(() => err);
      })
    );
  }
}
