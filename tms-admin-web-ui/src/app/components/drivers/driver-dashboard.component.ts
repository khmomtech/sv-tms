/* eslint-disable @typescript-eslint/consistent-type-imports */
import { CommonModule } from '@angular/common';
import type { OnInit, OnDestroy } from '@angular/core';
import { Component } from '@angular/core';
import { Router } from '@angular/router';

import type { ApiResponse } from '../../models/api-response.model';
import { DriverService } from '../../services/driver.service';

interface DriverStats {
  totalDrivers: number;
  activeDrivers: number;
  onDutyDrivers: number;
  pendingDocuments: number;
}

interface QuickAction {
  id: string;
  label: string;
  icon: string;
  route: string;
  color: string;
  description: string;
}

interface RecentActivity {
  id: string;
  type: 'login' | 'trip_completed' | 'trip_assigned' | 'document_uploaded' | 'rating_received';
  driverName: string;
  driverId: number;
  message: string;
  timestamp: string;
  icon: string;
  color: string;
}

@Component({
  selector: 'app-driver-dashboard',
  standalone: true,
  imports: [CommonModule],
  templateUrl: './driver-dashboard.component.html',
  styleUrls: ['./driver-dashboard.component.css'],
})
export class DriverDashboardComponent implements OnInit, OnDestroy {
  stats: DriverStats = {
    totalDrivers: 0,
    activeDrivers: 0,
    onDutyDrivers: 0,
    pendingDocuments: 0,
  };

  recentActivities: RecentActivity[] = [];
  isLoading = true;
  private refreshInterval: any;

  quickActions: QuickAction[] = [
    {
      id: 'add-driver',
      label: 'Add Driver',
      icon: '👤',
      route: '/drivers/add',
      color: 'bg-blue-500 hover:bg-blue-600',
      description: 'Register a new driver',
    },
    {
      id: 'send-message',
      label: 'Send Message',
      icon: '💬',
      route: '/drivers/communication/messages',
      color: 'bg-green-500 hover:bg-green-600',
      description: 'Communicate with drivers',
    },
    {
      id: 'view-map',
      label: 'Live Map',
      icon: '🗺️',
      route: '/live/map',
      color: 'bg-purple-500 hover:bg-purple-600',
      description: 'Track driver locations',
    },
    {
      id: 'performance',
      label: 'Analytics',
      icon: '📊',
      route: '/drivers/analytics/performance',
      color: 'bg-orange-500 hover:bg-orange-600',
      description: 'View performance metrics',
    },
  ];

  constructor(
    private driverService: DriverService,
    private router: Router,
  ) {}

  ngOnInit(): void {
    this.loadDashboardData();
    // Refresh data every 30 seconds
    this.refreshInterval = setInterval(() => {
      this.loadDashboardData();
    }, 30000);
  }

  ngOnDestroy(): void {
    if (this.refreshInterval) {
      clearInterval(this.refreshInterval);
    }
  }

  loadDashboardData(): void {
    this.isLoading = true;

    // Load driver statistics
    this.driverService.getDriverStats().subscribe({
      next: (response: ApiResponse<DriverStats>) => {
        this.stats = response.data;
        this.isLoading = false;
      },
      error: () => {
        this.isLoading = false;
        this.driverService.showToast('Failed to load dashboard data');
      },
    });

    // Load recent activities
    this.loadRecentActivities();
  }

  loadRecentActivities(): void {
    // This would typically come from a dedicated service
    // For now, we'll simulate some recent activities
    this.recentActivities = [
      {
        id: '1',
        type: 'login',
        driverName: 'John Smith',
        driverId: 1,
        message: 'Driver logged in to the system',
        timestamp: new Date(Date.now() - 5 * 60 * 1000).toISOString(),
        icon: '🔑',
        color: 'text-green-600',
      },
      {
        id: '2',
        type: 'trip_completed',
        driverName: 'Sarah Johnson',
        driverId: 2,
        message: 'Completed delivery to Downtown Office',
        timestamp: new Date(Date.now() - 15 * 60 * 1000).toISOString(),
        icon: '✅',
        color: 'text-blue-600',
      },
      {
        id: '3',
        type: 'rating_received',
        driverName: 'Mike Davis',
        driverId: 3,
        message: 'Received 5-star rating from customer',
        timestamp: new Date(Date.now() - 30 * 60 * 1000).toISOString(),
        icon: '⭐',
        color: 'text-yellow-600',
      },
      {
        id: '4',
        type: 'document_uploaded',
        driverName: 'Lisa Chen',
        driverId: 4,
        message: 'Uploaded updated license document',
        timestamp: new Date(Date.now() - 45 * 60 * 1000).toISOString(),
        icon: '📄',
        color: 'text-purple-600',
      },
    ];
  }

  getStatusPercentage(status: keyof DriverStats): number {
    if (this.stats.totalDrivers === 0) return 0;
    return Math.round((this.stats[status] / this.stats.totalDrivers) * 100);
  }

  getCompletionRate(): number {
    // For now, return a placeholder since we don't have trip data
    return 0;
  }

  formatTimeAgo(timestamp: string): string {
    const now = new Date();
    const time = new Date(timestamp);
    const diffInMinutes = Math.floor((now.getTime() - time.getTime()) / (1000 * 60));

    if (diffInMinutes < 1) return 'Just now';
    if (diffInMinutes < 60) return `${diffInMinutes}m ago`;

    const diffInHours = Math.floor(diffInMinutes / 60);
    if (diffInHours < 24) return `${diffInHours}h ago`;

    const diffInDays = Math.floor(diffInHours / 24);
    return `${diffInDays}d ago`;
  }

  navigateTo(route: string): void {
    this.router.navigate([route]);
  }

  viewDriver(driverId: number): void {
    this.router.navigate(['/drivers', driverId]);
  }

  refreshData(): void {
    this.loadDashboardData();
  }
}
