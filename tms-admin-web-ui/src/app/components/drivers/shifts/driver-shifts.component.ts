import { CommonModule } from '@angular/common';
import type { OnInit } from '@angular/core';
import { Component } from '@angular/core';

@Component({
  selector: 'app-driver-shifts',
  standalone: true,
  imports: [CommonModule],
  template: `
    <div class="p-6">
      <div class="flex items-center gap-3 mb-6">
        <div class="flex items-center justify-center w-12 h-12 bg-blue-100 rounded-lg">
          <i class="text-2xl text-blue-600 fas fa-clock"></i>
        </div>
        <div>
          <h1 class="text-2xl font-bold text-gray-900">Shifts & Hours</h1>
          <p class="text-gray-600">
            Monitor driver hours, shifts, and compliance with HOS regulations
          </p>
        </div>
      </div>

      <div class="grid grid-cols-1 lg:grid-cols-2 gap-6 mb-6">
        <!-- Daily Hours Summary -->
        <div class="bg-white rounded-lg shadow-sm border p-6">
          <h3 class="font-semibold text-gray-900 mb-4">Today's Hours Summary</h3>
          <div class="space-y-4">
            <div class="flex justify-between items-center">
              <span class="text-gray-600">On Duty</span>
              <span class="font-semibold">8h 45m</span>
            </div>
            <div class="flex justify-between items-center">
              <span class="text-gray-600">Driving</span>
              <span class="font-semibold">6h 30m</span>
            </div>
            <div class="flex justify-between items-center">
              <span class="text-gray-600">Remaining Drive Time</span>
              <span class="font-semibold text-green-600">4h 30m</span>
            </div>
            <div class="flex justify-between items-center">
              <span class="text-gray-600">Next Break Required</span>
              <span class="font-semibold text-orange-600">1h 15m</span>
            </div>
          </div>
        </div>

        <!-- HOS Compliance Status -->
        <div class="bg-white rounded-lg shadow-sm border p-6">
          <h3 class="font-semibold text-gray-900 mb-4">HOS Compliance Status</h3>
          <div class="space-y-4">
            <div class="flex items-center gap-3">
              <div class="w-3 h-3 bg-green-500 rounded-full"></div>
              <span class="text-gray-700">Daily Hours: Compliant</span>
            </div>
            <div class="flex items-center gap-3">
              <div class="w-3 h-3 bg-yellow-500 rounded-full"></div>
              <span class="text-gray-700">Weekly Hours: Warning</span>
            </div>
            <div class="flex items-center gap-3">
              <div class="w-3 h-3 bg-green-500 rounded-full"></div>
              <span class="text-gray-700">Rest Periods: Compliant</span>
            </div>
            <div class="flex items-center gap-3">
              <div class="w-3 h-3 bg-green-500 rounded-full"></div>
              <span class="text-gray-700">Break Requirements: Compliant</span>
            </div>
          </div>
        </div>
      </div>

      <!-- Shift Schedule Table -->
      <div class="bg-white rounded-lg shadow-sm border">
        <div class="px-6 py-4 border-b">
          <h3 class="font-semibold text-gray-900">Weekly Shift Schedule</h3>
        </div>
        <div class="overflow-x-auto">
          <table class="w-full">
            <thead class="bg-gray-50">
              <tr>
                <th
                  class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider"
                >
                  Date
                </th>
                <th
                  class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider"
                >
                  Shift Start
                </th>
                <th
                  class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider"
                >
                  Shift End
                </th>
                <th
                  class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider"
                >
                  Total Hours
                </th>
                <th
                  class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider"
                >
                  Drive Time
                </th>
                <th
                  class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider"
                >
                  Status
                </th>
              </tr>
            </thead>
            <tbody class="bg-white divide-y divide-gray-200">
              <tr>
                <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-900">Nov 14, 2025</td>
                <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-500">06:00 AM</td>
                <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-500">02:45 PM</td>
                <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-900">8h 45m</td>
                <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-900">6h 30m</td>
                <td class="px-6 py-4 whitespace-nowrap">
                  <span
                    class="px-2 py-1 text-xs font-medium bg-green-100 text-green-800 rounded-full"
                    >Active</span
                  >
                </td>
              </tr>
              <tr>
                <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-900">Nov 13, 2025</td>
                <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-500">05:30 AM</td>
                <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-500">03:30 PM</td>
                <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-900">10h 00m</td>
                <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-900">8h 15m</td>
                <td class="px-6 py-4 whitespace-nowrap">
                  <span class="px-2 py-1 text-xs font-medium bg-gray-100 text-gray-800 rounded-full"
                    >Completed</span
                  >
                </td>
              </tr>
            </tbody>
          </table>
        </div>
      </div>
    </div>
  `,
  styleUrls: [],
})
export class DriverShiftsComponent implements OnInit {
  constructor() {}

  ngOnInit(): void {}
}
