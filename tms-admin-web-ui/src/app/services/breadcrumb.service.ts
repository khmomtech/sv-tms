import { Injectable } from '@angular/core';
import type { ActivatedRouteSnapshot } from '@angular/router';
// eslint-disable-next-line @typescript-eslint/consistent-type-imports
import { Router } from '@angular/router';
import type { Observable } from 'rxjs';
import { BehaviorSubject } from 'rxjs';

export interface Breadcrumb {
  label: string;
  url: string;
  isActive: boolean;
}

@Injectable({
  providedIn: 'root',
})
export class BreadcrumbService {
  private breadcrumbsSubject = new BehaviorSubject<Breadcrumb[]>([]);
  public breadcrumbs$: Observable<Breadcrumb[]> = this.breadcrumbsSubject.asObservable();

  constructor(private router: Router) {}

  /**
   * Build breadcrumbs from activated route snapshots
   */
  buildBreadcrumbs(
    route: ActivatedRouteSnapshot,
    url: string = '',
    breadcrumbs: Breadcrumb[] = [],
  ): Breadcrumb[] {
    // Add current route if it has a title
    if (route.data?.['title']) {
      const breadcrumb: Breadcrumb = {
        label: route.data['title'],
        url: url,
        isActive: true,
      };
      breadcrumbs.unshift(breadcrumb);
    }

    // Mark previous breadcrumbs as inactive
    breadcrumbs.forEach((crumb, index) => {
      if (index < breadcrumbs.length - 1) {
        crumb.isActive = false;
      }
    });

    // Recursively build breadcrumbs for parent routes
    if (route.parent) {
      return this.buildBreadcrumbs(route.parent, this.getParentUrl(route, url), breadcrumbs);
    }

    // Add dashboard as root if not present
    if (breadcrumbs.length === 0 || breadcrumbs[breadcrumbs.length - 1]?.url !== '/dashboard') {
      breadcrumbs.push({
        label: 'Dashboard',
        url: '/dashboard',
        isActive: breadcrumbs.length === 0,
      });
    }

    this.breadcrumbsSubject.next(breadcrumbs.reverse());
    return breadcrumbs;
  }

  /**
   * Get the parent URL for breadcrumb construction
   */
  private getParentUrl(route: ActivatedRouteSnapshot, currentUrl: string): string {
    if (!route.parent) return '';

    const parentSegments = currentUrl.split('/').filter((segment) => segment !== '');
    if (route.url.length > 0) {
      parentSegments.splice(-route.url.length);
    }

    return '/' + parentSegments.join('/');
  }

  /**
   * Set custom breadcrumbs (useful for dynamic routes)
   */
  setBreadcrumbs(breadcrumbs: Breadcrumb[]): void {
    this.breadcrumbsSubject.next(breadcrumbs);
  }

  /**
   * Clear breadcrumbs
   */
  clearBreadcrumbs(): void {
    this.breadcrumbsSubject.next([]);
  }
}
