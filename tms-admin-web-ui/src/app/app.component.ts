import { CommonModule } from '@angular/common';
import type { OnInit, OnDestroy } from '@angular/core';
import { Component, inject } from '@angular/core';
import { GoogleMapsModule } from '@angular/google-maps';
import { NavigationEnd, Router, RouterModule } from '@angular/router';
import type { Subscription } from 'rxjs';
import { filter } from 'rxjs/operators';
import { distinctUntilChanged } from 'rxjs/operators';

import { ConnectionStatusBannerComponent } from './components/connection-status-banner/connection-status-banner.component';
import { HeaderComponent } from './components/header/header.component';
import { SidebarComponent } from './components/sidebar/sidebar.component';
import { environment } from './environments/environment';
import { AuthService } from './services/auth.service';
import { ConnectionMonitorService } from './services/connection-monitor.service';
import { PermissionGuardService } from './services/permission-guard.service';
import { SocketService } from './services/socket.service';

@Component({
  selector: 'app-root',
  standalone: true,
  imports: [
    CommonModule,
    RouterModule,
    GoogleMapsModule,
    SidebarComponent,
    HeaderComponent,
    ConnectionStatusBannerComponent,
  ],
  templateUrl: './app.component.html',
  styleUrls: ['./app.component.css'],
})
export class AppComponent implements OnInit, OnDestroy {
  private readonly router = inject(Router);
  private readonly socketService = inject(SocketService);
  private readonly connectionMonitor = inject(ConnectionMonitorService);
  private readonly authService = inject(AuthService);
  private readonly permissionGuardService = inject(PermissionGuardService);
  private statusSub?: Subscription;
  private routeSub?: Subscription;

  sidebarOpen = true;
  apiKey = environment.googleMapsApiKey;

  ngOnInit(): void {
    this.statusSub = this.connectionMonitor.status$
      .pipe(distinctUntilChanged())
      .subscribe((status) => {
        console.log('[AppComponent] WebSocket Status:', status);
      });

    this.handleRouteChange(this.router.url);
    this.routeSub = this.router.events
      .pipe(filter((event): event is NavigationEnd => event instanceof NavigationEnd))
      .subscribe((event) => this.handleRouteChange(event.urlAfterRedirects));
  }

  isLoginPage(): boolean {
    return this.router.url === '/login';
  }

  /**
   * Check if current route is a public page (no auth required)
   * Public pages: /login, /tracking, /tracking/:ref
   */
  isPublicPage(): boolean {
    const url = this.router.url;
    return this.isPublicUrl(url);
  }

  private isPublicUrl(url: string): boolean {
    return url === '' || url === '/' || url === '/login' || url.startsWith('/tracking');
  }

  private handleRouteChange(url: string): void {
    if (this.isPublicUrl(url)) {
      this.socketService.disconnect();
      return;
    }

    if (!this.authService.isAuthenticated()) {
      console.warn('[AppComponent] Token is missing or expired. Logging out...');
      this.socketService.disconnect();
      this.authService.logout();
      return;
    }

    this.socketService.connect([], 'app-root');
    this.permissionGuardService.loadEffectivePermissions().subscribe();
  }

  toggleSidebar(): void {
    this.sidebarOpen = !this.sidebarOpen;
  }

  ngOnDestroy(): void {
    this.statusSub?.unsubscribe();
    this.routeSub?.unsubscribe();
    this.socketService.disconnectContext('app-root');
  }
}
