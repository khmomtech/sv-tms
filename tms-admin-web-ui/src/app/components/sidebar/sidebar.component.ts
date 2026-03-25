import { CommonModule } from '@angular/common';
import { HttpClient, HttpClientModule } from '@angular/common/http';
import type { OnDestroy, OnInit } from '@angular/core';
import { Component, EventEmitter, HostListener, Output, inject } from '@angular/core';
import { FormsModule } from '@angular/forms';
import { MatIconModule } from '@angular/material/icon';
import { TranslateModule } from '@ngx-translate/core';
import { Router } from '@angular/router';
import { RouterModule } from '@angular/router';
import type { Observable } from 'rxjs';
import { Subscription, forkJoin, of } from 'rxjs';
import { catchError } from 'rxjs/operators';

import { AdminNotificationService } from '../../services/admin-notification.service';
import { AuthService } from '../../services/auth.service';
import { UiLanguageService } from '../../shared/services/ui-language.service';
import { SIDEBAR_MENU_CONFIG } from './sidebar-menu.config';
import type { SidebarMenuItem } from './sidebar-menu.types';
import { containsRoute, filterMenuTree, hasMenuPermission } from './sidebar-menu.utils';

@Component({
  selector: 'app-sidebar',
  standalone: true,
  imports: [
    CommonModule,
    RouterModule,
    FormsModule,
    MatIconModule,
    HttpClientModule,
    TranslateModule,
  ],
  templateUrl: './sidebar.component.html',
  styleUrls: ['./sidebar.component.css'],
})
export class SidebarComponent implements OnInit, OnDestroy {
  // Use inject() to break circular dependency - MUST be first!
  private authService = inject(AuthService);
  private adminNotificationService = inject(AdminNotificationService);
  private router = inject(Router);
  private http = inject(HttpClient);
  private uiLanguageService = inject(UiLanguageService);
  private languageSub?: Subscription;

  user: any;
  sidebarOpen = true;
  showAdvanced = false;

  @Output() requestClose = new EventEmitter<void>();

  // Dropdown menu state
  dropdowns: Record<string, boolean> = {};

  // Observable for notification count
  unreadCount$!: Observable<number>;

  // Quick counts for key items (drivers, vehicles, work orders) - null = unknown/loading
  counts: { drivers: number | null; vehicles: number | null; workOrders: number | null } = {
    drivers: null,
    vehicles: null,
    workOrders: null,
  };

  // Search functionality
  showSearch = false;
  searchQuery = '';
  filteredNavItems: SidebarMenuItem[] = [];

  // Navigation structure
  navItems: SidebarMenuItem[] = SIDEBAR_MENU_CONFIG;
  currentLanguage: 'en' | 'kh' = 'en';

  ngOnInit(): void {
    this.currentLanguage = this.uiLanguageService.language;
    this.languageSub = this.uiLanguageService.language$.subscribe((lang) => {
      this.currentLanguage = lang;
      if (this.searchQuery.trim()) {
        this.filterMenuItems();
      }
    });

    this.user = this.authService.getUser();
    this.unreadCount$ = this.adminNotificationService.unreadCount$;

    // Initialize filtered nav items
    this.filteredNavItems = this.getVisibleNavItems();

    // Initialize dropdowns state (closed by default)
    this.getMenuSource()
      .filter((item) => item.children)
      .forEach((item) => {
        if (item.id) {
          this.dropdowns[item.id] = false;
        }
      });

    // Auto-expand dropdowns if current route is inside their subtree
    this.expandActiveGroups();

    // Try to fetch quick counts for sidebar badges (best-effort; endpoints may not exist)
    this.fetchCounts();
  }
  /**
   * Expand dropdown groups that contain the currently active route.
   * Scans the full menu tree (including advanced items) so that deep-linking
   * to an advanced route correctly reveals it and opens its parent group.
   */
  private expandActiveGroups(): void {
    const currentUrl = this.router.url;

    const expandIfMatches = (item: SidebarMenuItem) => {
      if (item.children && item.id) {
        const match = containsRoute(item.children, currentUrl);
        if (match) {
          this.dropdowns[item.id] = true;
          // If this group is marked advanced, reveal the advanced layer so the
          // user can actually see the active item in the sidebar.
          if (item.isAdvanced) {
            this.showAdvanced = true;
          }
        }
      }
    };

    // Always scan the full tree — not the filtered source — so advanced items
    // are reachable when the user navigates directly to an advanced route.
    this.navItems.forEach(expandIfMatches);

    // Re-compute visible items after potentially enabling showAdvanced.
    this.filteredNavItems = this.getVisibleNavItems();
  }

  isAdmin(): boolean {
    return this.user?.roles?.includes('ADMIN');
  }

  isAdminOrDispatcher(): boolean {
    return this.user?.roles?.includes('ADMIN') || this.user?.roles?.includes('DISPATCHER');
  }

  toggleDropdown(section: string): void {
    // Close all other dropdowns first
    Object.keys(this.dropdowns).forEach((key) => {
      if (key !== section) {
        this.dropdowns[key] = false;
      }
    });

    // Toggle the selected dropdown
    this.dropdowns[section] = !this.dropdowns[section];
  }

  /**
   * Check if a navigation item should be visible based on user permissions.
   * This now delegates to the hasPermission pipe in the template.
   * The method is kept for potential complex logic in the future but is currently unused.
   */
  isNavItemVisible(item: SidebarMenuItem): boolean {
    return hasMenuPermission(item, (permission) => this.authService.hasPermission(permission));
  }

  /**
   * TrackBy function for nav items to improve performance
   */
  trackByNavItem(index: number, item: SidebarMenuItem): string {
    return item.id || item.route || `menu-item-${index}`;
  }

  /**
   * TrackBy function for child nav items to improve performance
   */
  trackByChildNavItem(index: number, item: SidebarMenuItem): string {
    return item.id || item.route || `menu-child-${index}`;
  }

  /**
   * Check if a route is currently active
   */
  isActiveRoute(route: string): boolean {
    return this.router.isActive(route, {
      paths: 'exact',
      queryParams: 'exact',
      fragment: 'ignored',
      matrixParams: 'ignored',
    });
  }

  /**
   * Toggle search visibility
   */
  toggleSearch(): void {
    this.showSearch = !this.showSearch;
    if (!this.showSearch) {
      this.clearSearch();
    }
  }

  /**
   * Filter menu items based on search query
   */
  filterMenuItems(): void {
    this.filteredNavItems = filterMenuTree(this.getMenuSource(), this.searchQuery, (permission) =>
      this.authService.hasPermission(permission),
    );

    this.filteredNavItems
      .filter((item) => item.children?.length && item.id)
      .forEach((item) => {
        this.dropdowns[item.id as string] = true;
      });
  }

  /**
   * Clear search query and reset filtered items
   */
  clearSearch(): void {
    this.searchQuery = '';
    this.filteredNavItems = this.getVisibleNavItems();
    this.expandActiveGroups();
  }

  toggleAdvanced(): void {
    this.showAdvanced = !this.showAdvanced;
    this.filteredNavItems = this.getVisibleNavItems();
    if (this.searchQuery.trim()) {
      this.filterMenuItems();
    } else {
      this.expandActiveGroups();
    }
  }

  /**
   * Handle mobile sidebar close on navigation
   */
  onNavItemClick(): void {
    // Close sidebar on mobile after navigation
    if (window.innerWidth <= 768) {
      // This would typically be handled by the parent component
      // For now, we'll emit an event or use a service
      this.closeSidebarOnMobile();
    }
  }

  /**
   * Close sidebar on mobile devices
   */
  private closeSidebarOnMobile(): void {
    if (typeof window !== 'undefined' && window.innerWidth <= 768) {
      this.requestClose.emit();
    }
  }

  /**
   * Handle keyboard navigation for accessibility
   */
  onKeyDown(event: KeyboardEvent, item: SidebarMenuItem): void {
    if (event.key === 'Enter' || event.key === ' ') {
      event.preventDefault();
      if (item.children) {
        this.toggleDropdown(item.id || this.getLabel(item.label));
      } else if (item.route) {
        // Navigate to route for keyboard activation
        this.router.navigate([item.route]).then(() => this.onNavItemClick());
      }
    }
  }

  /**
   * Best-effort fetch of counts for a few sidebar items. These endpoints may not exist
   * in every deployment; failures are ignored and counts remain null.
   * Uses public endpoints (no auth required) for dev/early stages; can switch to
   * authenticated endpoints as needed.
   */
  private fetchCounts(): void {
    const cacheKey = 'svtms.sidebar.counts.v1';
    try {
      const raw = localStorage.getItem(cacheKey);
      if (raw) {
        const parsed = JSON.parse(raw);
        if (parsed?.ts && Date.now() - parsed.ts < 60_000) {
          // Use cached values for 60s to reduce backend calls during navigation
          this.counts = parsed.counts;
          return;
        }
      }
    } catch (e) {
      // ignore parsing errors and continue to fetch
    }

    // Batch the three requests and set counts once. Use catchError to avoid
    // the whole batch failing if one endpoint is missing; null indicates unknown.
    forkJoin([
      this.http
        .get<{ count: number }>('/api/public/counts/drivers')
        .pipe(catchError(() => of(null))),
      this.http
        .get<{ count: number }>('/api/public/counts/vehicles')
        .pipe(catchError(() => of(null))),
      this.http
        .get<{ count: number }>('/api/public/counts/work-orders')
        .pipe(catchError(() => of(null))),
    ]).subscribe({
      next: (results) => {
        const [d, v, w] = results as Array<{ count: number } | null>;
        this.counts.drivers = d?.count ?? null;
        this.counts.vehicles = v?.count ?? null;
        this.counts.workOrders = w?.count ?? null;

        // cache for short period
        try {
          localStorage.setItem(cacheKey, JSON.stringify({ ts: Date.now(), counts: this.counts }));
        } catch (e) {
          // ignore storage errors
        }
      },
      error: () => {
        this.counts.drivers = null;
        this.counts.vehicles = null;
        this.counts.workOrders = null;
      },
    });
  }

  /**
   * Return a display value for a count (handles loading/null/large values)
   */
  getCountDisplay(key: 'drivers' | 'vehicles' | 'workOrders'): string | number {
    const v = this.counts[key];
    if (v === null) return '—';
    if (v > 99) return '99+';
    return v;
  }

  /**
   * Return a short 2-letter code for group headings (e.g., Driver Management -> DR)
   */
  getGroupCode(label: string | undefined): string {
    if (!label) return '';
    const words = label.split(/\s+/).filter(Boolean);
    if (words.length === 0) return '';
    if (words.length === 1) return words[0].substring(0, 2).toUpperCase();
    return (words[0][0] + (words[1][0] || '')).toUpperCase();
  }

  /**
   * Check if device is mobile
   */
  isMobile(): boolean {
    return typeof window !== 'undefined' && window.innerWidth <= 768;
  }

  /**
   * Handle window resize for responsive behavior
   */
  @HostListener('window:resize', ['$event'])
  onResize(event: any): void {
    // Auto-close search on mobile when resizing to desktop
    if (window.innerWidth > 768 && this.showSearch) {
      this.showSearch = false;
      this.clearSearch();
    }
  }

  @HostListener('window:keydown', ['$event'])
  onGlobalKeyDown(event: KeyboardEvent): void {
    const key = event.key.toLowerCase();
    if ((event.ctrlKey || event.metaKey) && key === 'k') {
      event.preventDefault();
      this.showSearch = true;
      setTimeout(() => {
        const input = document.getElementById('menu-search-input') as HTMLInputElement | null;
        input?.focus();
      }, 0);
    }
  }

  /**
   * Handle logo image loading errors
   */
  handleLogoError(event: Event): void {
    const imgElement = event.target as HTMLImageElement;
    // Set a fallback icon or hide the image
    imgElement.style.display = 'none';
    // Optionally, you could show a text fallback or icon here
    console.warn('Logo failed to load:', imgElement.src);
  }

  private getVisibleNavItems(): SidebarMenuItem[] {
    return filterMenuTree(this.getMenuSource(), '', (permission) =>
      this.authService.hasPermission(permission),
    );
  }

  private getMenuSource(): SidebarMenuItem[] {
    if (this.showAdvanced) {
      return this.navItems;
    }
    return this.filterOutAdvanced(this.navItems);
  }

  private filterOutAdvanced(items: SidebarMenuItem[]): SidebarMenuItem[] {
    return items.reduce<SidebarMenuItem[]>((acc, item) => {
      if (item.isAdvanced) {
        return acc;
      }

      const children = item.children ? this.filterOutAdvanced(item.children) : undefined;
      const hasChildren = !!children?.length;

      if (item.route || hasChildren) {
        acc.push({
          ...item,
          children: hasChildren ? children : undefined,
        });
      }
      return acc;
    }, []);
  }

  getLabel(label: SidebarMenuItem['label']): string {
    return this.uiLanguageService.translateLabel(label);
  }

  t(text: string): string {
    return this.uiLanguageService.translateText(text);
  }

  menuLabelAria(label: SidebarMenuItem['label']): string {
    return this.getLabel(label);
  }

  ngOnDestroy(): void {
    this.languageSub?.unsubscribe();
  }
}
