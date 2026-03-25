import { Component } from '@angular/core';
import { RouterOutlet } from '@angular/router';
import { TranslateService, TranslateModule } from '@ngx-translate/core';


@Component({
  selector: 'app-root',
  standalone: true,
  imports: [RouterOutlet, TranslateModule],
  template: `
  <div class="flex h-full">
    <aside class="w-64 bg-gray-800 text-white p-4">
      <h1 class="text-xl font-bold">SV-TMS សុវត្ថិភាព</h1>
      <nav class="mt-6">
        <a routerLink="/" class="block py-2">Dashboard</a>
        <a routerLink="/safety/checks" class="block py-2">Checks</a>
        <a routerLink="/safety/items" class="block py-2">Items</a>
        <a routerLink="/safety/issues" class="block py-2">Issues</a>
        <a routerLink="/safety/vehicles" class="block py-2">Vehicles</a>
        <a routerLink="/safety/overrides" class="block py-2">Overrides</a>
        <a routerLink="/safety/reports" class="block py-2">Reports</a>
        <a routerLink="/audit" class="block py-2">Audit</a>
      </nav>
    </aside>
    <main class="flex-1 p-6 bg-gray-50">
      <header class="flex justify-between items-center mb-6">
        <div>
          <button class="px-3 py-2 bg-blue-600 text-white rounded" (click)="useKh()">KH</button>
          <button class="px-3 py-2 ml-2 border" (click)="useEn()">EN</button>
        </div>
        <div>
          <span class="text-sm">{{'APP_TITLE' | translate}}</span>
        </div>
      </header>
      <section class="bg-white rounded shadow p-4 min-h-[600px]">
        <router-outlet></router-outlet>
      </section>
    </main>
  </div>
  `
})
export class AppComponent {
  constructor(private translate: TranslateService) {
    this.translate.addLangs(['kh', 'en']);
    this.translate.setDefaultLang('kh');
    const browserLang = this.translate.getBrowserLang();
    this.translate.use(browserLang?.startsWith('en') ? 'en' : 'kh');
  }

  useKh(){ this.translate.use('kh'); }
  useEn(){ this.translate.use('en'); }
}
