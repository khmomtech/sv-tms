import { Injectable } from '@angular/core';
import { TranslateService } from '@ngx-translate/core';
import { BehaviorSubject } from 'rxjs';

export type UiLanguage = 'en' | 'kh';

type LocalizedLabel = { en: string; kh: string };

const STORAGE_KEY = 'svtms.ui.language';

@Injectable({ providedIn: 'root' })
export class UiLanguageService {
  private readonly languageSubject = new BehaviorSubject<UiLanguage>(this.readInitialLanguage());
  readonly language$ = this.languageSubject.asObservable();

  constructor(private readonly translateService: TranslateService) {}

  get language(): UiLanguage {
    return this.languageSubject.value;
  }

  init(): void {
    this.translateService.addLangs(['en', 'kh']);
    this.translateService.setDefaultLang('en');
    this.translateService.use(this.language);
  }

  setLanguage(language: UiLanguage): void {
    this.languageSubject.next(language);
    this.translateService.use(language);
    const storage = this.getStorage();
    storage?.setItem(STORAGE_KEY, language);
  }

  toggleLanguage(): void {
    this.setLanguage(this.language === 'en' ? 'kh' : 'en');
  }

  translateLabel(label: string | LocalizedLabel): string {
    if (typeof label !== 'string') {
      return this.language === 'kh' ? label.kh : label.en;
    }
    return this.translateByNamespaces(label, ['menu.labels', 'routes', 'common']);
  }

  translateText(text: string): string {
    return this.translateByNamespaces(text, [
      'common',
      'layout.header',
      'layout.sidebar',
      'routes',
    ]);
  }

  translateRouteLabel(text: string): string {
    return this.translateByNamespaces(text, ['routes', 'menu.labels', 'common']);
  }

  instant(key: string, params?: Record<string, unknown>): string {
    return this.translateService.instant(key, params);
  }

  private translateByNamespaces(text: string, namespaces: string[]): string {
    const normalizedKey = this.normalizeKey(text);
    for (const namespace of namespaces) {
      const key = `${namespace}.${normalizedKey}`;
      const translated = this.translateService.instant(key);
      if (translated !== key) {
        return translated;
      }
    }
    return text;
  }

  private normalizeKey(text: string): string {
    return text
      .trim()
      .toLowerCase()
      .replace(/&/g, ' and ')
      .replace(/[^a-z0-9]+/g, '_')
      .replace(/^_+|_+$/g, '');
  }

  private readInitialLanguage(): UiLanguage {
    const storage = this.getStorage();
    const saved = storage?.getItem(STORAGE_KEY);
    if (saved === 'kh' || saved === 'en') {
      return saved;
    }
    return 'en';
  }

  private getStorage(): Storage | null {
    if (typeof window === 'undefined') {
      return null;
    }
    try {
      return window.localStorage;
    } catch {
      return null;
    }
  }
}
