import { CommonModule } from '@angular/common';
import type { OnInit, OnDestroy } from '@angular/core';
import { Component, EventEmitter, HostListener, Output, Input, inject } from '@angular/core';
import { Title } from '@angular/platform-browser';
import { Router } from '@angular/router';
import { ActivatedRoute } from '@angular/router';
import { RouterModule } from '@angular/router';
import { NavigationEnd } from '@angular/router';
import { TranslateModule } from '@ngx-translate/core';
import type { Subscription } from 'rxjs';
import { filter, map, mergeMap } from 'rxjs/operators';

import type { AdminNotification } from '../../services/admin-notification.service';
import { AuthService } from '../../services/auth.service';
import { InAppNotificationService } from '../../services/in-app-notification.service';
import { UiLanguageService, type UiLanguage } from '../../shared/services/ui-language.service';
import { NotificationDropdownComponent } from '../notification-dropdown/notification-dropdown.component';

@Component({
  selector: 'app-header',
  standalone: true,
  imports: [CommonModule, RouterModule, NotificationDropdownComponent, TranslateModule],
  templateUrl: './header.component.html',
  styleUrls: ['./header.component.css'],
})
export class HeaderComponent implements OnInit, OnDestroy {
  @Output() sidebarToggled = new EventEmitter<void>();

  unreadCount = 0;
  previousUnreadCount = 0;
  hasInteracted = false;

  notificationDropdownOpen = false;
  isDropdownOpen = false;
  notificationList: AdminNotification[] = [];

  user: { username: string } | null = null;
  @Input() pageTitle: string | null = null;
  breadcrumbs: { label: string; url: string }[] = [];
  private _routeSub?: Subscription;
  private _langSub?: Subscription;
  currentLanguage: UiLanguage = 'en';

  // Use inject() to break circular dependency
  private readonly router = inject(Router);
  private readonly activatedRoute = inject(ActivatedRoute);
  private readonly title = inject(Title);
  private readonly inAppNotificationService = inject(InAppNotificationService);
  private readonly authService = inject(AuthService);
  private readonly uiLanguageService = inject(UiLanguageService);

  ngOnInit(): void {
    this.currentLanguage = this.uiLanguageService.language;
    this._langSub = this.uiLanguageService.language$.subscribe((lang) => {
      this.currentLanguage = lang;
      this.refreshRouteMetadata();
    });

    if (!this.authService.isAuthenticated()) {
      console.warn('[HeaderComponent] User not authenticated. Skipping notifications.');
      return;
    }

    this.user = this.authService.getCurrentUser?.() || { username: 'Admin' };

    this.inAppNotificationService.list(0, 20).subscribe({
      next: (res) => {
        const list = res?.data?.content ?? [];
        this.notificationList = list.map((n) => ({
          id: n.id,
          title: n.title,
          message: n.body,
          type: 'in-app',
          read: n.isRead,
          createdAt: n.createdAt,
          targetUrl: null,
        }));
      },
      error: (err) => console.warn(' Failed to fetch notifications:', err),
    });

    this.inAppNotificationService.unreadCount$.subscribe((count) => {
      if (this.hasInteracted && count > this.previousUnreadCount) {
        this.playSound('/assets/audio/notification.wav');
      }
      this.previousUnreadCount = count;
      this.unreadCount = count;
    });

    // 🔤 Derive page title from deepest route or keep provided @Input; also build breadcrumbs
    this._routeSub = this.router.events
      .pipe(
        filter((e): e is NavigationEnd => e instanceof NavigationEnd),
        map(() => {
          let r = this.activatedRoute;
          while (r.firstChild) r = r.firstChild;
          return r;
        }),
        mergeMap((r) => r.data),
      )
      .subscribe(() => this.refreshRouteMetadata());
  }

  private refreshRouteMetadata(): void {
    let r = this.activatedRoute;
    while (r.firstChild) r = r.firstChild;
    const data = r.snapshot.data ?? {};
    const routeTitle = (data['title'] as string) || '';
    const current = this.title.getTitle();
    this.pageTitle = this.uiLanguageService.translateRouteLabel(
      routeTitle || current || 'Dashboard',
    );
    this.title.setTitle(`${this.pageTitle} — SVTRUCKING`);
    this.breadcrumbs = this.buildBreadcrumbs(this.activatedRoute.root);
  }

  private buildBreadcrumbs(
    route: ActivatedRoute,
    url: string = '',
    crumbs: { label: string; url: string }[] = [],
  ): { label: string; url: string }[] {
    const routeConfig = route.routeConfig;
    if (routeConfig && routeConfig.path) {
      const path = routeConfig.path;
      const params = route.snapshot.params;
      const segment = path
        .split('/')
        .map((s) => (s.startsWith(':') ? params[s.substring(1)] : s))
        .join('/');
      if (segment) {
        url += `/${segment}`;
        const data = route.snapshot.data || {};
        const rawLabel = (data['breadcrumb'] as string) || (data['title'] as string) || segment;
        const label = this.uiLanguageService.translateRouteLabel(rawLabel);
        crumbs.push({ label, url });
      }
    }
    const child = route.firstChild;
    return child ? this.buildBreadcrumbs(child, url, crumbs) : crumbs;
  }

  // 🎧 Mark interaction for autoplay permission
  @HostListener('window:click')
  @HostListener('window:keydown')
  onUserInteraction(): void {
    this.hasInteracted = true;
  }

  //  Auto-close dropdowns on outside click
  @HostListener('document:click', ['$event'])
  onDocumentClick(event: MouseEvent): void {
    const target = event.target as HTMLElement;
    const clickedInsideNotif = target.closest('app-notification-dropdown');
    const clickedInsideUserMenu = target.closest('.user-menu');

    if (!clickedInsideNotif) this.notificationDropdownOpen = false;
    if (!clickedInsideUserMenu) this.isDropdownOpen = false;
  }

  // 📁 Toggle sidebar
  onToggleSidebar(): void {
    this.sidebarToggled.emit();
  }

  // 🔄 Toggle user dropdown
  toggleDropdown(): void {
    this.isDropdownOpen = !this.isDropdownOpen;
    this.notificationDropdownOpen = false;
  }

  // 🔄 Toggle notification dropdown
  toggleNotificationDropdown(): void {
    this.notificationDropdownOpen = !this.notificationDropdownOpen;
    this.isDropdownOpen = false;
  }

  // 🔗 Navigate to notification page
  navigateToNotifications(): void {
    this.router.navigate(['/admin/notifications']);
    this.inAppNotificationService.markAllRead().subscribe(() => {
      this.notificationDropdownOpen = false;
      this.unreadCount = 0;
    });
  }

  // 🚪 Log user out
  logout(): void {
    this.authService.logout();
    this.user = null;
    this.router.navigate(['/login']);
  }

  // 🔊 Play notification sound
  playSound(path: string): void {
    if (!this.hasInteracted) return;

    const audio = new Audio(path);
    audio
      .play()
      .then(() => console.log('🔔 Sound played'))
      .catch((err) => console.warn('🔕 Autoplay blocked or failed:', err));
  }

  ngOnDestroy(): void {
    this._routeSub?.unsubscribe();
    this._langSub?.unsubscribe();
  }

  setLanguage(language: UiLanguage): void {
    this.uiLanguageService.setLanguage(language);
  }

  isLanguage(language: UiLanguage): boolean {
    return this.currentLanguage === language;
  }

  t(text: string): string {
    return this.uiLanguageService.translateText(text);
  }
}
