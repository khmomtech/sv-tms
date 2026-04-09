import { CommonModule } from '@angular/common';
import type { OnInit } from '@angular/core';
import { Component } from '@angular/core';

@Component({
  selector: 'app-parts-inventory',
  standalone: true,
  imports: [CommonModule],
  template: `
    <div class="p-6">
      <div class="flex items-center justify-between mb-6">
        <div class="flex items-center gap-3">
          <div class="flex items-center justify-center w-12 h-12 bg-blue-100 rounded-lg">
            <i class="text-2xl text-blue-600 fas fa-boxes"></i>
          </div>
          <div>
            <h1 class="text-2xl font-bold text-gray-900">Parts & Inventory</h1>
            <p class="text-gray-600">Manage spare parts inventory and stock levels</p>
          </div>
        </div>
        <div class="flex gap-2">
          <button class="px-4 py-2 bg-green-600 text-white rounded-lg hover:bg-green-700">
            <i class="fas fa-plus mr-2"></i>Add Part
          </button>
          <button class="px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700">
            <i class="fas fa-download mr-2"></i>Import
          </button>
        </div>
      </div>

      <div class="grid grid-cols-1 md:grid-cols-4 gap-6 mb-6">
        <!-- Inventory Statistics -->
        <div class="bg-white rounded-lg shadow-sm border p-6">
          <div class="flex items-center justify-between">
            <div>
              <p class="text-2xl font-bold text-gray-900">2,458</p>
              <p class="text-sm text-gray-600">Total Parts</p>
            </div>
            <div class="w-12 h-12 bg-blue-100 rounded-lg flex items-center justify-center">
              <i class="text-blue-600 fas fa-cube"></i>
            </div>
          </div>
        </div>

        <div class="bg-white rounded-lg shadow-sm border p-6">
          <div class="flex items-center justify-between">
            <div>
              <p class="text-2xl font-bold text-red-600">47</p>
              <p class="text-sm text-gray-600">Low Stock</p>
            </div>
            <div class="w-12 h-12 bg-red-100 rounded-lg flex items-center justify-center">
              <i class="text-red-600 fas fa-exclamation-triangle"></i>
            </div>
          </div>
        </div>

        <div class="bg-white rounded-lg shadow-sm border p-6">
          <div class="flex items-center justify-between">
            <div>
              <p class="text-2xl font-bold text-green-600">$125,450</p>
              <p class="text-sm text-gray-600">Total Value</p>
            </div>
            <div class="w-12 h-12 bg-green-100 rounded-lg flex items-center justify-center">
              <i class="text-green-600 fas fa-dollar-sign"></i>
            </div>
          </div>
        </div>

        <div class="bg-white rounded-lg shadow-sm border p-6">
          <div class="flex items-center justify-between">
            <div>
              <p class="text-2xl font-bold text-orange-600">23</p>
              <p class="text-sm text-gray-600">On Order</p>
            </div>
            <div class="w-12 h-12 bg-orange-100 rounded-lg flex items-center justify-center">
              <i class="text-orange-600 fas fa-truck"></i>
            </div>
          </div>
        </div>
      </div>

      <div class="grid grid-cols-1 lg:grid-cols-3 gap-6 mb-6">
        <!-- Low Stock Alert -->
        <div class="bg-white rounded-lg shadow-sm border">
          <div class="px-6 py-4 border-b">
            <h3 class="font-semibold text-gray-900">Low Stock Alerts</h3>
          </div>
          <div class="p-6">
            <div class="space-y-4">
              <div
                class="flex items-center justify-between p-3 bg-red-50 border border-red-200 rounded-lg"
              >
                <div>
                  <h4 class="font-medium text-gray-900">Oil Filter - FL2016</h4>
                  <p class="text-sm text-gray-600">Current: 2 units</p>
                  <p class="text-xs text-red-600">Min Level: 10 units</p>
                </div>
                <span class="px-2 py-1 text-xs font-medium bg-red-100 text-red-800 rounded-full"
                  >Critical</span
                >
              </div>

              <div
                class="flex items-center justify-between p-3 bg-yellow-50 border border-yellow-200 rounded-lg"
              >
                <div>
                  <h4 class="font-medium text-gray-900">Brake Pads - BP450</h4>
                  <p class="text-sm text-gray-600">Current: 6 units</p>
                  <p class="text-xs text-yellow-600">Min Level: 15 units</p>
                </div>
                <span
                  class="px-2 py-1 text-xs font-medium bg-yellow-100 text-yellow-800 rounded-full"
                  >Low</span
                >
              </div>

              <div
                class="flex items-center justify-between p-3 bg-orange-50 border border-orange-200 rounded-lg"
              >
                <div>
                  <h4 class="font-medium text-gray-900">Air Filter - AF2023</h4>
                  <p class="text-sm text-gray-600">Current: 8 units</p>
                  <p class="text-xs text-orange-600">Min Level: 12 units</p>
                </div>
                <span
                  class="px-2 py-1 text-xs font-medium bg-orange-100 text-orange-800 rounded-full"
                  >Low</span
                >
              </div>
            </div>
          </div>
        </div>

        <!-- Top Categories -->
        <div class="bg-white rounded-lg shadow-sm border">
          <div class="px-6 py-4 border-b">
            <h3 class="font-semibold text-gray-900">Top Categories</h3>
          </div>
          <div class="p-6">
            <div class="space-y-4">
              <div class="flex items-center justify-between">
                <div class="flex items-center gap-3">
                  <div class="w-3 h-3 bg-blue-500 rounded-full"></div>
                  <span class="text-sm text-gray-700">Engine Parts</span>
                </div>
                <div class="text-right">
                  <p class="text-sm font-medium">645 items</p>
                  <p class="text-xs text-gray-500">$45,230</p>
                </div>
              </div>

              <div class="flex items-center justify-between">
                <div class="flex items-center gap-3">
                  <div class="w-3 h-3 bg-red-500 rounded-full"></div>
                  <span class="text-sm text-gray-700">Brake System</span>
                </div>
                <div class="text-right">
                  <p class="text-sm font-medium">423 items</p>
                  <p class="text-xs text-gray-500">$28,450</p>
                </div>
              </div>

              <div class="flex items-center justify-between">
                <div class="flex items-center gap-3">
                  <div class="w-3 h-3 bg-green-500 rounded-full"></div>
                  <span class="text-sm text-gray-700">Filters</span>
                </div>
                <div class="text-right">
                  <p class="text-sm font-medium">289 items</p>
                  <p class="text-xs text-gray-500">$15,620</p>
                </div>
              </div>

              <div class="flex items-center justify-between">
                <div class="flex items-center gap-3">
                  <div class="w-3 h-3 bg-yellow-500 rounded-full"></div>
                  <span class="text-sm text-gray-700">Electrical</span>
                </div>
                <div class="text-right">
                  <p class="text-sm font-medium">234 items</p>
                  <p class="text-xs text-gray-500">$18,340</p>
                </div>
              </div>
            </div>
          </div>
        </div>

        <!-- Recent Orders -->
        <div class="bg-white rounded-lg shadow-sm border">
          <div class="px-6 py-4 border-b">
            <h3 class="font-semibold text-gray-900">Recent Orders</h3>
          </div>
          <div class="p-6">
            <div class="space-y-4">
              <div class="flex items-center justify-between p-3 border rounded-lg">
                <div>
                  <h4 class="font-medium text-gray-900">PO-2025-045</h4>
                  <p class="text-sm text-gray-600">AutoZone Supply</p>
                  <p class="text-xs text-gray-500">Nov 12, 2025</p>
                </div>
                <div class="text-right">
                  <p class="text-sm font-medium">$2,450</p>
                  <span
                    class="px-2 py-1 text-xs font-medium bg-green-100 text-green-800 rounded-full"
                    >Delivered</span
                  >
                </div>
              </div>

              <div class="flex items-center justify-between p-3 border rounded-lg">
                <div>
                  <h4 class="font-medium text-gray-900">PO-2025-046</h4>
                  <p class="text-sm text-gray-600">Fleet Parts Direct</p>
                  <p class="text-xs text-gray-500">Nov 10, 2025</p>
                </div>
                <div class="text-right">
                  <p class="text-sm font-medium">$1,850</p>
                  <span
                    class="px-2 py-1 text-xs font-medium bg-yellow-100 text-yellow-800 rounded-full"
                    >In Transit</span
                  >
                </div>
              </div>

              <div class="flex items-center justify-between p-3 border rounded-lg">
                <div>
                  <h4 class="font-medium text-gray-900">PO-2025-047</h4>
                  <p class="text-sm text-gray-600">OEM Parts Co</p>
                  <p class="text-xs text-gray-500">Nov 8, 2025</p>
                </div>
                <div class="text-right">
                  <p class="text-sm font-medium">$3,250</p>
                  <span class="px-2 py-1 text-xs font-medium bg-blue-100 text-blue-800 rounded-full"
                    >Ordered</span
                  >
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>

      <!-- Parts Inventory Table -->
      <div class="bg-white rounded-lg shadow-sm border">
        <div class="px-6 py-4 border-b flex items-center justify-between">
          <h3 class="font-semibold text-gray-900">Parts Inventory</h3>
          <div class="flex items-center gap-2">
            <input
              type="text"
              placeholder="Search parts..."
              class="px-3 py-2 border border-gray-300 rounded-lg text-sm focus:outline-none focus:ring-2 focus:ring-blue-500"
            />
            <select
              class="px-3 py-2 border border-gray-300 rounded-lg text-sm focus:outline-none focus:ring-2 focus:ring-blue-500"
            >
              <option value="">All Categories</option>
              <option value="engine">Engine Parts</option>
              <option value="brakes">Brake System</option>
              <option value="filters">Filters</option>
              <option value="electrical">Electrical</option>
            </select>
          </div>
        </div>
        <div class="overflow-x-auto">
          <table class="w-full">
            <thead class="bg-gray-50">
              <tr>
                <th
                  class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider"
                >
                  Part Number
                </th>
                <th
                  class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider"
                >
                  Description
                </th>
                <th
                  class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider"
                >
                  Category
                </th>
                <th
                  class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider"
                >
                  Stock
                </th>
                <th
                  class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider"
                >
                  Min Level
                </th>
                <th
                  class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider"
                >
                  Unit Cost
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
                <td class="px-6 py-4 whitespace-nowrap">
                  <div class="text-sm font-medium text-gray-900">FL2016</div>
                  <div class="text-sm text-gray-500">Oil Filter</div>
                </td>
                <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-900">
                  Premium Oil Filter for Freightliner
                </td>
                <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-500">Filters</td>
                <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-900">2</td>
                <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-500">10</td>
                <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-900">$25.50</td>
                <td class="px-6 py-4 whitespace-nowrap">
                  <span class="px-2 py-1 text-xs font-medium bg-red-100 text-red-800 rounded-full"
                    >Critical</span
                  >
                </td>
              </tr>
              <tr>
                <td class="px-6 py-4 whitespace-nowrap">
                  <div class="text-sm font-medium text-gray-900">BP450</div>
                  <div class="text-sm text-gray-500">Brake Pads</div>
                </td>
                <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-900">
                  Heavy Duty Brake Pads Set
                </td>
                <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-500">Brake System</td>
                <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-900">6</td>
                <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-500">15</td>
                <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-900">$125.00</td>
                <td class="px-6 py-4 whitespace-nowrap">
                  <span
                    class="px-2 py-1 text-xs font-medium bg-yellow-100 text-yellow-800 rounded-full"
                    >Low Stock</span
                  >
                </td>
              </tr>
              <tr>
                <td class="px-6 py-4 whitespace-nowrap">
                  <div class="text-sm font-medium text-gray-900">EN2045</div>
                  <div class="text-sm text-gray-500">Spark Plug</div>
                </td>
                <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-900">
                  High Performance Spark Plug
                </td>
                <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-500">Engine Parts</td>
                <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-900">45</td>
                <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-500">20</td>
                <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-900">$18.75</td>
                <td class="px-6 py-4 whitespace-nowrap">
                  <span
                    class="px-2 py-1 text-xs font-medium bg-green-100 text-green-800 rounded-full"
                    >In Stock</span
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
export class PartsInventoryComponent implements OnInit {
  constructor() {}

  ngOnInit(): void {}
}
