import { CommonModule } from '@angular/common';
import type { OnInit } from '@angular/core';
import { Component } from '@angular/core';

@Component({
  selector: 'app-driver-performance',
  standalone: true,
  imports: [CommonModule],
  template: `
    <div class="p-6">
      <div class="flex items-center gap-3 mb-6">
        <div class="flex items-center justify-center w-12 h-12 bg-blue-100 rounded-lg">
          <i class="text-2xl text-blue-600 fas fa-chart-line"></i>
        </div>
        <div>
          <h1 class="text-2xl font-bold text-gray-900">Performance & Incidents</h1>
          <p class="text-gray-600">Monitor driver performance metrics and incident reports</p>
        </div>
      </div>

      <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6 mb-6">
        <!-- Performance Metrics -->
        <div class="bg-white rounded-lg shadow-sm border p-6">
          <div class="flex items-center justify-between">
            <div>
              <p class="text-2xl font-bold text-green-600">4.7</p>
              <p class="text-sm text-gray-600">Safety Score</p>
            </div>
            <div class="w-12 h-12 bg-green-100 rounded-lg flex items-center justify-center">
              <i class="text-green-600 fas fa-shield-alt"></i>
            </div>
          </div>
        </div>

        <div class="bg-white rounded-lg shadow-sm border p-6">
          <div class="flex items-center justify-between">
            <div>
              <p class="text-2xl font-bold text-blue-600">98.5%</p>
              <p class="text-sm text-gray-600">On-Time Rate</p>
            </div>
            <div class="w-12 h-12 bg-blue-100 rounded-lg flex items-center justify-center">
              <i class="text-blue-600 fas fa-clock"></i>
            </div>
          </div>
        </div>

        <div class="bg-white rounded-lg shadow-sm border p-6">
          <div class="flex items-center justify-between">
            <div>
              <p class="text-2xl font-bold text-orange-600">7.2</p>
              <p class="text-sm text-gray-600">MPG Average</p>
            </div>
            <div class="w-12 h-12 bg-orange-100 rounded-lg flex items-center justify-center">
              <i class="text-orange-600 fas fa-gas-pump"></i>
            </div>
          </div>
        </div>

        <div class="bg-white rounded-lg shadow-sm border p-6">
          <div class="flex items-center justify-between">
            <div>
              <p class="text-2xl font-bold text-red-600">2</p>
              <p class="text-sm text-gray-600">Open Incidents</p>
            </div>
            <div class="w-12 h-12 bg-red-100 rounded-lg flex items-center justify-center">
              <i class="text-red-600 fas fa-exclamation-triangle"></i>
            </div>
          </div>
        </div>
      </div>

      <div class="grid grid-cols-1 lg:grid-cols-2 gap-6">
        <!-- Recent Incidents -->
        <div class="bg-white rounded-lg shadow-sm border">
          <div class="px-6 py-4 border-b">
            <h3 class="font-semibold text-gray-900">Recent Incidents</h3>
          </div>
          <div class="p-6">
            <div class="space-y-4">
              <div class="flex items-start gap-3 p-4 bg-red-50 rounded-lg">
                <div class="w-2 h-2 bg-red-500 rounded-full mt-2"></div>
                <div class="flex-1">
                  <div class="flex items-center justify-between">
                    <h4 class="font-medium text-gray-900">Hard Braking Event</h4>
                    <span class="text-xs text-gray-500">2 hours ago</span>
                  </div>
                  <p class="text-sm text-gray-600">Highway 95, Mile Marker 15</p>
                  <p class="text-xs text-red-600 mt-1">Severity: High</p>
                </div>
              </div>

              <div class="flex items-start gap-3 p-4 bg-yellow-50 rounded-lg">
                <div class="w-2 h-2 bg-yellow-500 rounded-full mt-2"></div>
                <div class="flex-1">
                  <div class="flex items-center justify-between">
                    <h4 class="font-medium text-gray-900">Speed Violation</h4>
                    <span class="text-xs text-gray-500">1 day ago</span>
                  </div>
                  <p class="text-sm text-gray-600">Interstate 10, Construction Zone</p>
                  <p class="text-xs text-yellow-600 mt-1">Severity: Medium</p>
                </div>
              </div>

              <div class="flex items-start gap-3 p-4 bg-blue-50 rounded-lg">
                <div class="w-2 h-2 bg-blue-500 rounded-full mt-2"></div>
                <div class="flex-1">
                  <div class="flex items-center justify-between">
                    <h4 class="font-medium text-gray-900">Route Deviation</h4>
                    <span class="text-xs text-gray-500">3 days ago</span>
                  </div>
                  <p class="text-sm text-gray-600">Downtown District</p>
                  <p class="text-xs text-blue-600 mt-1">Severity: Low</p>
                </div>
              </div>
            </div>
          </div>
        </div>

        <!-- Performance Trends -->
        <div class="bg-white rounded-lg shadow-sm border">
          <div class="px-6 py-4 border-b">
            <h3 class="font-semibold text-gray-900">Performance Trends</h3>
          </div>
          <div class="p-6">
            <div class="space-y-6">
              <!-- Fuel Efficiency -->
              <div>
                <div class="flex items-center justify-between mb-2">
                  <span class="text-sm text-gray-600">Fuel Efficiency</span>
                  <span class="text-sm font-medium text-green-600">+5% vs last month</span>
                </div>
                <div class="w-full bg-gray-200 rounded-full h-2">
                  <div class="bg-green-600 h-2 rounded-full" style="width: 78%"></div>
                </div>
              </div>

              <!-- Safety Score -->
              <div>
                <div class="flex items-center justify-between mb-2">
                  <span class="text-sm text-gray-600">Safety Score</span>
                  <span class="text-sm font-medium text-green-600">+2% vs last month</span>
                </div>
                <div class="w-full bg-gray-200 rounded-full h-2">
                  <div class="bg-green-600 h-2 rounded-full" style="width: 94%"></div>
                </div>
              </div>

              <!-- On-Time Delivery -->
              <div>
                <div class="flex items-center justify-between mb-2">
                  <span class="text-sm text-gray-600">On-Time Delivery</span>
                  <span class="text-sm font-medium text-blue-600">+1% vs last month</span>
                </div>
                <div class="w-full bg-gray-200 rounded-full h-2">
                  <div class="bg-blue-600 h-2 rounded-full" style="width: 98%"></div>
                </div>
              </div>

              <!-- Customer Rating -->
              <div>
                <div class="flex items-center justify-between mb-2">
                  <span class="text-sm text-gray-600">Customer Rating</span>
                  <span class="text-sm font-medium text-yellow-600">-1% vs last month</span>
                </div>
                <div class="w-full bg-gray-200 rounded-full h-2">
                  <div class="bg-yellow-600 h-2 rounded-full" style="width: 85%"></div>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  `,
  styleUrls: [],
})
export class DriverPerformanceComponent implements OnInit {
  constructor() {}

  ngOnInit(): void {}
}
