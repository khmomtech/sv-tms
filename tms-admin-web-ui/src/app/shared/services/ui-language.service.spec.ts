import { TestBed } from '@angular/core/testing';
import { TranslateService } from '@ngx-translate/core';

import { UiLanguageService } from './ui-language.service';

describe('UiLanguageService', () => {
  let service: UiLanguageService;
  let translateService: jasmine.SpyObj<TranslateService>;

  beforeEach(() => {
    localStorage.clear();

    translateService = jasmine.createSpyObj<TranslateService>('TranslateService', [
      'addLangs',
      'setDefaultLang',
      'use',
      'instant',
    ]);
    translateService.instant.and.callFake((key: string) => key);

    TestBed.configureTestingModule({
      providers: [UiLanguageService, { provide: TranslateService, useValue: translateService }],
    });

    service = TestBed.inject(UiLanguageService);
  });

  it('defaults to english when storage is empty', () => {
    expect(service.language).toBe('en');
  });

  it('loads the saved language from storage', () => {
    localStorage.setItem('svtms.ui.language', 'kh');

    service = TestBed.runInInjectionContext(() => new UiLanguageService(translateService));

    expect(service.language).toBe('kh');
  });

  it('initializes the translation service and uses the current language', () => {
    service.init();

    expect(translateService.addLangs).toHaveBeenCalledWith(['en', 'kh']);
    expect(translateService.setDefaultLang).toHaveBeenCalledWith('en');
    expect(translateService.use).toHaveBeenCalledWith('en');
  });

  it('updates translation service and persists when language changes', () => {
    service.setLanguage('kh');

    expect(service.language).toBe('kh');
    expect(translateService.use).toHaveBeenCalledWith('kh');
    expect(localStorage.getItem('svtms.ui.language')).toBe('kh');
  });
});
