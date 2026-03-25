import { HttpClient } from '@angular/common/http';
import { TranslateLoader } from '@ngx-translate/core';
import { Observable } from 'rxjs';

export class AppTranslateLoader implements TranslateLoader {
  constructor(private http: HttpClient, private prefix = '/assets/i18n/', private suffix = '.json') {}
  getTranslation(lang: string): Observable<any> {
    return this.http.get(`${this.prefix}${lang}${this.suffix}`);
  }
}

export function HttpLoaderFactory(http: HttpClient) {
  return new AppTranslateLoader(http);
}
