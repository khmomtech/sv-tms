/**
 * Shipment Tracking Component
 * Public-facing component for tracking shipments in real-time
 * Features: Search, timeline, map, summary, proof of delivery
 */

import { CommonModule } from '@angular/common';
import type { OnInit, OnDestroy } from '@angular/core';
import { Component, ChangeDetectionStrategy, inject } from '@angular/core';
import { FormsModule } from '@angular/forms';
import { ActivatedRoute } from '@angular/router';
import { Subject } from 'rxjs';
import { takeUntil } from 'rxjs/operators';

import type {
  DriverInfo,
  GeoLocation,
  OrderPoint,
  ProofOfDelivery,
  ShipmentStatus,
  ShipmentSummary,
  StatusTimeline,
  TrackingResponse,
} from '../../models/shipment-tracking.model';
import { STATUS_COLORS, STATUS_DISPLAY_NAMES } from '../../models/shipment-tracking.model';
import { ShipmentTrackingService } from '../../services/shipment-tracking.service';

import { TrackingMapComponent } from './tracking-map.component';

/**
 * Main Shipment Tracking Component
 * Standalone Angular component for public shipment tracking
 * Imports: CommonModule, FormsModule, TrackingTimelineComponent, TrackingMapComponent
 */
@Component({
  selector: 'app-shipment-tracking',
  standalone: true,
  changeDetection: ChangeDetectionStrategy.OnPush,
  imports: [CommonModule, FormsModule, TrackingMapComponent],
  template: `
    <!-- Outer wrapper with background -->
    <div class="min-h-screen bg-slate-50">
      <!-- Header -->
      <header
        class="bg-gradient-to-r from-slate-900 via-slate-800 to-slate-900 border-b border-slate-700 sticky top-0 z-40 shadow-lg"
      >
        <div class="max-w-5xl mx-auto px-4 py-4 flex items-center gap-3 justify-between">
          <div class="flex items-center gap-3 flex-1">
            <div
              class="h-10 w-10 rounded-xl bg-gradient-to-br from-orange-400 to-orange-600 text-white flex items-center justify-center font-black text-sm shadow-md"
            >
              SV
            </div>
            <div>
              <div class="text-xs uppercase tracking-widest text-slate-400 font-bold">
                SV Trucking
              </div>
              <div class="font-extrabold text-lg text-white">Track Shipment</div>
            </div>
          </div>
          <!-- Public badge -->
          <div class="text-xs bg-emerald-500 text-white px-3 py-1.5 rounded-lg font-bold shadow-md">
            🌐 Public Access
          </div>
        </div>
      </header>

      <main class="max-w-5xl mx-auto px-4 py-10 space-y-6 pb-20">
        <!-- Search Section -->
        <section
          class="bg-gradient-to-br from-white to-slate-50 border border-slate-200 rounded-2xl shadow-md p-6 sm:p-8 space-y-4 mt-4"
        >
          <div>
            <h1 class="text-3xl sm:text-4xl font-extrabold text-slate-900">Track Your Shipment</h1>
            <p class="text-slate-600 mt-2 text-sm sm:text-base">
              Enter your booking or order reference for real-time tracking updates.
            </p>
          </div>

          <!-- Search Input -->
          <div class="flex flex-col sm:flex-row gap-2">
            <input
              type="text"
              [(ngModel)]="searchReference"
              (keyup.enter)="onTrack()"
              (change)="onSearchChange()"
              placeholder="e.g. BK-2026-00125 or ORD-2026-00088"
              class="flex-1 rounded-xl border-2 border-slate-200 px-4 py-3 text-slate-900 placeholder-slate-400 focus:outline-none focus:ring-2 focus:ring-orange-500 focus:border-transparent transition duration-200 text-sm sm:text-base"
              [disabled]="!!(loading$ | async)"
              aria-label="Enter booking or order reference"
              aria-describedby="search-help"
              aria-autocomplete="off"
            />
            <button
              (click)="onTrack()"
              [disabled]="!!(loading$ | async) || !searchReference"
              class="rounded-xl bg-gradient-to-r from-slate-900 to-slate-800 text-white px-6 sm:px-8 py-3 font-bold hover:from-slate-800 hover:to-slate-700 disabled:opacity-50 disabled:cursor-not-allowed transition duration-200 shadow-md hover:shadow-lg text-sm sm:text-base whitespace-nowrap"
              aria-label="Track shipment"
              aria-busy="!!(loading$ | async)"
            >
              <span *ngIf="!(loading$ | async)">🔍 Track</span>
              <span *ngIf="loading$ | async" class="flex items-center gap-2 justify-center">
                <span
                  class="inline-block w-4 h-4 border-2 border-white border-t-transparent rounded-full animate-spin"
                ></span>
                <span class="hidden sm:inline">Searching...</span>
              </span>
            </button>
            <!-- Refresh button when tracking is loaded -->
            <button
              *ngIf="currentTracking$ | async"
              (click)="onTrack()"
              [disabled]="!!(loading$ | async)"
              class="rounded-xl bg-gradient-to-r from-emerald-600 to-emerald-700 text-white px-6 py-3 font-bold hover:from-emerald-700 hover:to-emerald-800 disabled:opacity-50 disabled:cursor-not-allowed transition duration-200 shadow-md hover:shadow-lg"
              title="Refresh tracking data"
              aria-label="Refresh tracking data"
            >
              <span *ngIf="!(loading$ | async)">🔄</span>
              <span
                *ngIf="loading$ | async"
                class="inline-block w-4 h-4 border-2 border-white border-t-transparent rounded-full animate-spin"
              ></span>
            </button>
          </div>
          <div id="search-help" class="text-xs text-slate-500 font-medium">
            📌 Enter 10-12 character reference code
          </div>

          <!-- Live region for screen readers -->
          <div class="sr-only" aria-live="polite">{{ liveMessage }}</div>

          <!-- Error Alert -->
          <div
            *ngIf="error$ | async as error"
            role="alert"
            class="p-4 sm:p-5 rounded-xl bg-red-50 border-2 border-red-300 text-red-800 animate-in fade-in slide-in-from-top shadow-md"
          >
            <div class="font-bold flex items-center gap-2 text-base">
              <span class="text-xl">⚠️</span> {{ error.message }}
            </div>
            <div
              *ngIf="error.details"
              class="text-sm text-red-700 mt-2 bg-white rounded-lg p-2 border border-red-200"
            >
              {{ error.details }}
            </div>
          </div>

          <!-- Info message when no tracking -->
          <div
            *ngIf="!(currentTracking$ | async) && !(loading$ | async) && !(error$ | async)"
            class="p-4 sm:p-5 rounded-xl bg-blue-50 border-2 border-blue-300 text-blue-900 text-sm sm:text-base font-medium shadow-md"
          >
            <div class="flex items-center gap-2">
              <span class="text-lg">ℹ️</span> Enter a booking reference above to get started
            </div>
          </div>
        </section>

        <!-- Tracking Results -->
        <ng-container *ngIf="currentTracking$ | async as tracking">
          <!-- Journey Progress Bar -->
          <section
            class="bg-gradient-to-br from-white to-slate-50 border-2 border-slate-200 rounded-2xl shadow-md p-6 sm:p-8 animate-in fade-in"
          >
            <div
              class="flex flex-col sm:flex-row items-start sm:items-center justify-between gap-2 mb-4"
            >
              <h2 class="font-bold text-xl sm:text-2xl text-slate-900">🚚 Journey Progress</h2>
              <span
                class="text-base sm:text-lg font-bold text-orange-600 bg-orange-50 px-4 py-1 rounded-full"
                >{{ getProgressPercentage(tracking) }}% Complete</span
              >
            </div>
            <div class="relative">
              <!-- Progress bar background -->
              <div class="h-4 bg-slate-200 rounded-full overflow-hidden shadow-inner">
                <div
                  class="h-full bg-gradient-to-r from-emerald-500 via-blue-500 to-blue-600 rounded-full transition-all duration-700 ease-out shadow-md"
                  [style.width.%]="getProgressPercentage(tracking)"
                ></div>
              </div>
              <!-- Milestones -->
              <div class="grid grid-cols-2 sm:grid-cols-4 gap-3 mt-5">
                <div
                  class="text-center p-2 rounded-lg"
                  [class.bg-emerald-50]="hasStarted(tracking)"
                  [class.bg-slate-50]="!hasStarted(tracking)"
                >
                  <div
                    class="w-3 h-3 mx-auto mb-2 rounded-full shadow-sm"
                    [class.bg-emerald-600]="hasStarted(tracking)"
                    [class.bg-slate-300]="!hasStarted(tracking)"
                    [class.animate-pulse]="hasStarted(tracking)"
                  ></div>
                  <div
                    class="text-xs font-bold"
                    [class.text-emerald-700]="hasStarted(tracking)"
                    [class.text-slate-500]="!hasStarted(tracking)"
                  >
                    Started
                  </div>
                </div>
                <div
                  class="text-center p-2 rounded-lg"
                  [class.bg-blue-50]="isInTransit(tracking)"
                  [class.bg-slate-50]="!isInTransit(tracking)"
                >
                  <div
                    class="w-3 h-3 mx-auto mb-2 rounded-full shadow-sm"
                    [class.bg-blue-600]="isInTransit(tracking)"
                    [class.bg-slate-300]="!isInTransit(tracking)"
                    [class.animate-pulse]="isInTransit(tracking)"
                  ></div>
                  <div
                    class="text-xs font-bold"
                    [class.text-blue-700]="isInTransit(tracking)"
                    [class.text-slate-500]="!isInTransit(tracking)"
                  >
                    In Transit
                  </div>
                </div>
                <div
                  class="text-center p-2 rounded-lg"
                  [class.bg-orange-50]="isNearDelivery(tracking)"
                  [class.bg-slate-50]="!isNearDelivery(tracking)"
                >
                  <div
                    class="w-3 h-3 mx-auto mb-2 rounded-full shadow-sm"
                    [class.bg-orange-600]="isNearDelivery(tracking)"
                    [class.bg-slate-300]="!isNearDelivery(tracking)"
                    [class.animate-pulse]="isNearDelivery(tracking)"
                  ></div>
                  <div
                    class="text-xs font-bold"
                    [class.text-orange-700]="isNearDelivery(tracking)"
                    [class.text-slate-500]="!isNearDelivery(tracking)"
                  >
                    Near Delivery
                  </div>
                </div>
                <div
                  class="text-center p-2 rounded-lg"
                  [class.bg-green-50]="isDelivered(tracking)"
                  [class.bg-slate-50]="!isDelivered(tracking)"
                >
                  <div
                    class="w-3 h-3 mx-auto mb-2 rounded-full shadow-sm"
                    [class.bg-green-600]="isDelivered(tracking)"
                    [class.bg-slate-300]="!isDelivered(tracking)"
                    [class.animate-pulse]="isDelivered(tracking)"
                  ></div>
                  <div
                    class="text-xs font-bold"
                    [class.text-green-700]="isDelivered(tracking)"
                    [class.text-slate-500]="!isDelivered(tracking)"
                  >
                    Delivered
                  </div>
                </div>
              </div>
            </div>
            <!-- Estimated time remaining -->
            <div
              *ngIf="getEstimatedTimeRemaining(tracking) && !isDelivered(tracking)"
              class="mt-5 p-4 bg-blue-50 border-2 border-blue-300 rounded-xl shadow-md"
            >
              <div class="text-base font-bold text-blue-900 flex items-center gap-2">
                <span class="text-xl">⏱️</span>
                <span>{{ getEstimatedTimeRemaining(tracking) }} remaining</span>
              </div>
            </div>
            <!-- Delivered badge -->
            <div
              *ngIf="isDelivered(tracking)"
              class="mt-5 p-4 bg-green-50 border-2 border-green-300 rounded-xl shadow-md"
            >
              <div class="text-base font-bold text-green-900 flex items-center gap-2">
                <span class="text-2xl">✅</span>
                <span>Delivered successfully</span>
              </div>
            </div>
          </section>

          <!-- Status Overview -->
          <section
            class="bg-white border-2 border-slate-200 rounded-2xl shadow-md p-6 sm:p-8 animate-in fade-in"
          >
            <div class="flex flex-col gap-4 sm:flex-row sm:items-center sm:justify-between mb-6">
              <h2 class="font-bold text-xl sm:text-2xl text-slate-900">📊 Shipment Overview</h2>
              <div class="flex flex-col sm:flex-row items-start sm:items-center gap-3">
                <span class="text-xs uppercase text-slate-600 font-bold tracking-wider"
                  >Current Status</span
                >
                <span
                  class="font-bold text-sm sm:text-base inline-block px-4 py-2 rounded-xl shadow-md"
                  [ngClass]="getStatusColor(tracking.shipmentSummary.status)"
                >
                  {{ getStatusDisplayName(tracking.shipmentSummary.status) }}
                </span>
              </div>
            </div>
            <div class="grid grid-cols-1 sm:grid-cols-2 md:grid-cols-4 gap-4">
              <!-- Reference with copy button -->
              <div
                class="p-4 bg-gradient-to-br from-orange-50 to-orange-100 rounded-xl border-2 border-orange-200 shadow-sm hover:shadow-md transition"
              >
                <div class="text-xs uppercase text-orange-700 font-bold tracking-wider">
                  Order Reference
                </div>
                <div class="flex items-center gap-2 mt-3">
                  <div class="font-bold text-xl text-orange-900 flex-1 break-all">
                    {{
                      tracking.shipmentSummary.orderReference ||
                        tracking.shipmentSummary.bookingReference
                    }}
                  </div>
                  <button
                    (click)="
                      copyToClipboard(
                        tracking.shipmentSummary.orderReference ||
                          tracking.shipmentSummary.bookingReference
                      )
                    "
                    class="p-2 hover:bg-orange-200 rounded-lg transition text-orange-700 hover:text-orange-900 flex-shrink-0 text-lg"
                    title="Copy reference"
                    aria-label="Copy reference to clipboard"
                  >
                    <span *ngIf="!copied">📋</span>
                    <span *ngIf="copied" class="text-green-700 animate-bounce">✅</span>
                  </button>
                </div>
                <div
                  *ngIf="copied"
                  class="text-xs text-green-700 mt-2 font-semibold animate-in fade-in"
                >
                  ✓ Copied to clipboard!
                </div>
              </div>

              <!-- Customer -->
              <div
                class="p-4 bg-gradient-to-br from-blue-50 to-blue-100 rounded-xl border-2 border-blue-200 shadow-sm hover:shadow-md transition"
              >
                <div class="text-xs uppercase text-blue-700 font-bold tracking-wider">
                  Customer Name
                </div>
                <div class="font-bold text-lg text-blue-900 mt-3">
                  {{ tracking.shipmentSummary.customerName || '—' }}
                </div>
                <div
                  *ngIf="tracking.shipmentSummary.billTo"
                  class="text-xs text-blue-700 mt-2 font-medium"
                >
                  Bill To: {{ tracking.shipmentSummary.billTo }}
                </div>
              </div>

              <!-- Service Type -->
              <div
                class="p-4 bg-gradient-to-br from-purple-50 to-purple-100 rounded-xl border-2 border-purple-200 shadow-sm hover:shadow-md transition"
              >
                <div class="text-xs uppercase text-purple-700 font-bold tracking-wider">
                  Service Type
                </div>
                <div class="font-bold text-lg text-purple-900 mt-3">
                  {{ tracking.shipmentSummary.serviceType }}
                </div>
              </div>

              <!-- ETA with countdown -->
              <div
                class="p-4 bg-gradient-to-br from-green-50 to-green-100 rounded-xl border-2 border-green-200 shadow-sm hover:shadow-md transition"
              >
                <div class="text-xs uppercase text-green-700 font-bold tracking-wider">
                  Est. Delivery
                </div>
                <div class="font-bold text-lg text-green-900 mt-3">
                  {{ tracking.shipmentSummary.estimatedDelivery | date: 'dd-MMM-yyyy' }}
                </div>
                <div class="text-xs text-green-700 mt-2 font-medium">
                  {{ tracking.shipmentSummary.estimatedDelivery | date: 'HH:mm' }}
                </div>
              </div>
            </div>
          </section>

          <!-- Delivery Note Style Summary -->
          <section
            class="bg-white border-2 border-slate-200 rounded-2xl shadow-md p-6 sm:p-8 animate-in fade-in delay-100"
          >
            <h2 class="font-bold text-xl sm:text-2xl text-slate-900 mb-6">
              📄 Delivery Note Summary
            </h2>
            <div class="grid grid-cols-1 md:grid-cols-3 gap-4">
              <!-- Trip Info -->
              <div class="p-4 bg-slate-50 rounded-xl border border-slate-200">
                <div class="text-slate-500 font-semibold">Trip Info</div>
                <div class="text-sm text-slate-700 mt-2 space-y-1">
                  <div>
                    Trip No:
                    <span class="font-semibold">{{
                      getPrimaryDispatch(tracking)?.tripNo || 'N/A'
                    }}</span>
                  </div>
                  <div>
                    Route:
                    <span class="font-semibold">{{
                      getPrimaryDispatch(tracking)?.route || 'N/A'
                    }}</span>
                  </div>
                  <div>
                    Dispatch ID:
                    <span class="font-semibold">{{
                      getPrimaryDispatch(tracking)?.dispatchId || 'N/A'
                    }}</span>
                  </div>
                </div>
              </div>

              <!-- Timing -->
              <div class="p-4 bg-slate-50 rounded-xl border border-slate-200">
                <div class="text-slate-500 font-semibold">Timing</div>
                <div class="text-sm text-slate-700 mt-2 space-y-1">
                  <div>
                    Start:
                    <span class="font-semibold">{{
                      getPrimaryDispatch(tracking)?.createdAt | date: 'dd-MMM-yyyy HH:mm'
                    }}</span>
                  </div>
                  <div>
                    ETA:
                    <span class="font-semibold">{{
                      tracking.shipmentSummary.estimatedDelivery | date: 'dd-MMM-yyyy HH:mm'
                    }}</span>
                  </div>
                  <div>
                    Deliver By:
                    <span class="font-semibold">{{
                      tracking.shipmentSummary.actualDelivery ||
                        tracking.shipmentSummary.estimatedDelivery | date: 'dd-MMM-yyyy HH:mm'
                    }}</span>
                  </div>
                </div>
              </div>

              <!-- Driver & Vehicle -->
              <div class="p-4 bg-slate-50 rounded-xl border border-slate-200">
                <div class="text-slate-500 font-semibold">Driver & Vehicle</div>
                <div class="text-sm text-slate-700 mt-2 space-y-1">
                  <div>
                    Name:
                    <span class="font-semibold">{{
                      getPrimaryDispatch(tracking)?.driver?.name || 'N/A'
                    }}</span>
                  </div>
                  <div>
                    Phone:
                    <a
                      *ngIf="getPrimaryDispatch(tracking)?.driver?.phone"
                      [href]="'tel:' + getPrimaryDispatch(tracking)?.driver?.phone"
                      class="font-semibold text-blue-700 hover:underline"
                      >{{ getPrimaryDispatch(tracking)?.driver?.phone }}</a
                    ><span *ngIf="!getPrimaryDispatch(tracking)?.driver?.phone">N/A</span>
                  </div>
                  <div>
                    Plate:
                    <span class="font-semibold">{{
                      getPrimaryDispatch(tracking)?.vehicle?.vehicleNumber || 'N/A'
                    }}</span>
                  </div>
                </div>
              </div>
            </div>

            <!-- Locations -->
            <div class="grid grid-cols-1 md:grid-cols-2 gap-4 mt-4">
              <div class="p-4 bg-slate-50 rounded-xl border border-slate-200">
                <div class="text-slate-500 font-semibold flex items-center gap-2">
                  <span class="inline-block w-2 h-2 bg-emerald-500 rounded-full"></span> Loading
                </div>
                <div class="text-sm text-slate-700 mt-2 space-y-1">
                  <div class="font-semibold">{{ primaryPickupLabel(tracking) }}</div>
                  <div class="text-slate-600">
                    {{ displayLocation(tracking.shipmentSummary.pickupLocation) }}
                  </div>
                  <!-- Detailed pickup points -->
                  <div
                    *ngFor="let p of getPickupPoints(tracking)"
                    class="flex items-start justify-between gap-3 py-1"
                  >
                    <div class="text-slate-700 text-xs">
                      <div class="font-medium text-slate-800">{{ p.name || 'Loading Point' }}</div>
                      <div class="text-slate-600">{{ p.address || '—' }}</div>
                      <div class="flex flex-wrap items-center gap-2 mt-1">
                        <span
                          *ngIf="p.count && p.count > 1"
                          class="px-1.5 py-0.5 bg-slate-100 text-slate-600 rounded-md text-[11px]"
                          >×{{ p.count }}</span
                        >
                        <span
                          *ngIf="p.status"
                          class="inline-flex items-center gap-1 px-1.5 py-0.5 bg-slate-100 rounded-md text-[11px] text-slate-700"
                        >
                          <span
                            class="inline-block w-1.5 h-1.5 rounded-full"
                            [ngClass]="getPointStatusColor(p.status)"
                          ></span>
                          {{ getPointStatusDisplay(p.status) }}
                        </span>
                        <span
                          *ngIf="p.eta"
                          class="px-1.5 py-0.5 bg-slate-100 text-slate-600 rounded-md text-[11px]"
                          >ETA: {{ p.eta | date: 'dd-MMM-yyyy HH:mm' }}</span
                        >
                        <span
                          *ngIf="p.plannedArrival"
                          class="px-1.5 py-0.5 bg-slate-100 text-slate-600 rounded-md text-[11px]"
                          >Planned: {{ p.plannedArrival | date: 'dd-MMM-yyyy HH:mm' }}</span
                        >
                        <span
                          *ngIf="p.actualArrival"
                          class="px-1.5 py-0.5 bg-slate-100 text-slate-600 rounded-md text-[11px]"
                          >Arrived: {{ p.actualArrival | date: 'dd-MMM-yyyy HH:mm' }}</span
                        >
                        <span
                          *ngIf="p.actualDeparture"
                          class="px-1.5 py-0.5 bg-slate-100 text-slate-600 rounded-md text-[11px]"
                          >Departed: {{ p.actualDeparture | date: 'dd-MMM-yyyy HH:mm' }}</span
                        >
                        <span
                          *ngIf="p.confirmedBy"
                          class="px-1.5 py-0.5 bg-slate-100 text-slate-700 rounded-md text-[11px]"
                          >By: {{ p.confirmedBy }}</span
                        >
                        <a
                          *ngIf="p.contactPhone"
                          [href]="'tel:' + p.contactPhone"
                          class="px-1.5 py-0.5 bg-blue-50 text-blue-700 rounded-md text-[11px] hover:underline"
                          >{{ p.contactPhone }}</a
                        >
                        <a
                          *ngIf="p.proofImageUrl"
                          [href]="p.proofImageUrl"
                          target="_blank"
                          rel="noopener"
                          class="px-1.5 py-0.5 bg-emerald-50 text-emerald-700 rounded-md text-[11px] hover:underline"
                          >Proof</a
                        >
                      </div>
                      <div *ngIf="p.remarks" class="text-[11px] text-slate-500 mt-1 truncate">
                        {{ p.remarks }}
                      </div>
                    </div>
                    <div class="text-[11px] text-slate-500">Seq {{ p.sequence || '—' }}</div>
                  </div>
                  <!-- Additional loading stops (no coordinates) -->
                  <div
                    *ngFor="let s of getAdditionalLoadingStops(tracking)"
                    class="text-slate-500 text-xs"
                  >
                    • {{ s }}
                  </div>
                </div>
              </div>
              <div class="p-4 bg-slate-50 rounded-xl border border-slate-200">
                <div class="text-slate-500 font-semibold flex items-center gap-2">
                  <span class="inline-block w-2 h-2 bg-blue-600 rounded-full"></span> Unloading
                </div>
                <div class="text-sm text-slate-700 mt-2 space-y-1">
                  <div class="font-semibold">{{ primaryDeliveryLabel(tracking) }}</div>
                  <div class="text-slate-600">
                    {{ displayLocation(tracking.shipmentSummary.deliveryLocation) }}
                  </div>
                  <!-- Detailed delivery points -->
                  <div
                    *ngFor="let d of getDeliveryPoints(tracking)"
                    class="flex items-start justify-between gap-3 py-1"
                  >
                    <div class="text-slate-700 text-xs">
                      <div class="font-medium text-slate-800">{{ d.name || 'Delivery Point' }}</div>
                      <div class="text-slate-600">{{ d.address || '—' }}</div>
                      <div class="flex flex-wrap items-center gap-2 mt-1">
                        <span
                          *ngIf="d.count && d.count > 1"
                          class="px-1.5 py-0.5 bg-slate-100 text-slate-600 rounded-md text-[11px]"
                          >×{{ d.count }}</span
                        >
                        <span
                          *ngIf="d.status"
                          class="inline-flex items-center gap-1 px-1.5 py-0.5 bg-slate-100 rounded-md text-[11px] text-slate-700"
                        >
                          <span
                            class="inline-block w-1.5 h-1.5 rounded-full"
                            [ngClass]="getPointStatusColor(d.status)"
                          ></span>
                          {{ getPointStatusDisplay(d.status) }}
                        </span>
                        <span
                          *ngIf="d.eta"
                          class="px-1.5 py-0.5 bg-slate-100 text-slate-600 rounded-md text-[11px]"
                          >ETA: {{ d.eta | date: 'dd-MMM-yyyy HH:mm' }}</span
                        >
                        <span
                          *ngIf="d.plannedArrival"
                          class="px-1.5 py-0.5 bg-slate-100 text-slate-600 rounded-md text-[11px]"
                          >Planned: {{ d.plannedArrival | date: 'dd-MMM-yyyy HH:mm' }}</span
                        >
                        <span
                          *ngIf="d.actualArrival"
                          class="px-1.5 py-0.5 bg-slate-100 text-slate-600 rounded-md text-[11px]"
                          >Arrived: {{ d.actualArrival | date: 'dd-MMM-yyyy HH:mm' }}</span
                        >
                        <span
                          *ngIf="d.actualDeparture"
                          class="px-1.5 py-0.5 bg-slate-100 text-slate-600 rounded-md text-[11px]"
                          >Departed: {{ d.actualDeparture | date: 'dd-MMM-yyyy HH:mm' }}</span
                        >
                        <span
                          *ngIf="d.confirmedBy"
                          class="px-1.5 py-0.5 bg-slate-100 text-slate-700 rounded-md text-[11px]"
                          >By: {{ d.confirmedBy }}</span
                        >
                        <a
                          *ngIf="d.contactPhone"
                          [href]="'tel:' + d.contactPhone"
                          class="px-1.5 py-0.5 bg-blue-50 text-blue-700 rounded-md text-[11px] hover:underline"
                          >{{ d.contactPhone }}</a
                        >
                        <a
                          *ngIf="d.proofImageUrl"
                          [href]="d.proofImageUrl"
                          target="_blank"
                          rel="noopener"
                          class="px-1.5 py-0.5 bg-emerald-50 text-emerald-700 rounded-md text-[11px] hover:underline"
                          >Proof</a
                        >
                      </div>
                      <div *ngIf="d.remarks" class="text-[11px] text-slate-500 mt-1 truncate">
                        {{ d.remarks }}
                      </div>
                    </div>
                    <div class="text-[11px] text-slate-500">Seq {{ d.sequence || '—' }}</div>
                  </div>
                  <!-- Additional unloading stops (no coordinates) -->
                  <div
                    *ngFor="let s of getAdditionalUnloadingStops(tracking)"
                    class="text-slate-500 text-xs"
                  >
                    • {{ s }}
                  </div>
                </div>
              </div>
            </div>
          </section>

          <!-- Live Map -->
          <section
            class="bg-white border-2 border-slate-200 rounded-2xl shadow-md p-6 sm:p-8 animate-in fade-in delay-100"
          >
            <h2 class="font-bold text-xl sm:text-2xl text-slate-900 mb-4">📍 Current Location</h2>
            <app-tracking-map
              [location]="(locationUpdates$ | async) || undefined"
              [tracking]="tracking"
              [pickupPoints]="getPickupPoints(tracking)"
              [deliveryPoints]="getDeliveryPoints(tracking)"
            ></app-tracking-map>
            <div
              class="flex flex-col sm:flex-row items-start sm:items-center justify-between mt-4 gap-2"
            >
              <p class="text-sm font-medium text-slate-600 flex items-center gap-2">
                <span class="inline-block w-2 h-2 bg-green-500 rounded-full animate-pulse"></span>
                <span class="text-green-700 font-semibold">Live</span> Location updates in real-time
              </p>
              <p class="text-xs font-medium text-slate-500">
                Last updated:
                <span class="text-slate-700">{{
                  getLastUpdated(tracking) | date: 'dd-MMM HH:mm'
                }}</span>
              </p>
            </div>
          </section>

          <!-- Order Items (minimalist table) -->
          <section
            *ngIf="tracking.shipmentSummary.items && tracking.shipmentSummary.items.length > 0"
            class="bg-white border-2 border-slate-200 rounded-2xl shadow-md p-6 sm:p-8 animate-in fade-in delay-100"
          >
            <h2 class="font-bold text-xl sm:text-2xl text-slate-900 mb-5">📋 Order Items</h2>
            <div class="overflow-x-auto rounded-xl border border-slate-200">
              <table class="min-w-full divide-y divide-slate-200 text-sm">
                <thead class="bg-blue-600">
                  <tr class="text-left text-white">
                    <th class="px-4 py-2 font-semibold">#</th>
                    <th class="px-4 py-2 font-semibold">Item Code</th>
                    <th class="px-4 py-2 font-semibold">Item Name</th>
                    <th class="px-4 py-2 font-semibold">Type</th>
                    <th class="px-4 py-2 font-semibold">Qty</th>
                    <th class="px-4 py-2 font-semibold">UOM</th>
                    <th class="px-4 py-2 font-semibold">Pallet</th>
                    <th class="px-4 py-2 font-semibold">From</th>
                    <th class="px-4 py-2 font-semibold">To</th>
                    <th class="px-4 py-2 font-semibold">Warehouse</th>
                  </tr>
                </thead>
                <tbody class="divide-y divide-slate-200">
                  <tr
                    *ngFor="let item of tracking.shipmentSummary.items; let i = index"
                    class="hover:bg-slate-50"
                  >
                    <td class="px-4 py-2 text-slate-700 font-medium">{{ i + 1 }}</td>
                    <td class="px-4 py-2 text-slate-700">-</td>
                    <td class="px-4 py-2 text-slate-900 font-medium">{{ item.description }}</td>
                    <td class="px-4 py-2 text-slate-700">OTHERS</td>
                    <td class="px-4 py-2 text-slate-700 font-medium">{{ item.quantity }}</td>
                    <td class="px-4 py-2 text-slate-700">{{ item.uom || '-' }}</td>
                    <td class="px-4 py-2 text-slate-700">{{ item.pallets || '-' }}</td>
                    <td class="px-4 py-2 text-slate-700">{{ item.loadingPlace || '-' }}</td>
                    <td class="px-4 py-2 text-slate-700">{{ item.unloadingPlace || '-' }}</td>
                    <td class="px-4 py-2 text-slate-700">{{ item.warehouse || '-' }}</td>
                  </tr>
                </tbody>
              </table>
            </div>
          </section>

          <!-- Dispatch Status History -->
          <section
            *ngIf="getTimeline(tracking).length > 0"
            class="bg-gradient-to-br from-white to-slate-50 border-2 border-slate-200 rounded-2xl shadow-md p-6 sm:p-8 animate-in fade-in delay-150"
          >
            <div
              class="flex flex-col sm:flex-row items-start sm:items-center justify-between gap-4 mb-8"
            >
              <div>
                <h2 class="font-bold text-2xl sm:text-3xl text-slate-900 flex items-center gap-2">
                  <span class="text-3xl">📜</span> Dispatch Status History
                </h2>
                <p class="text-sm text-slate-500 mt-1">
                  Complete timeline of your shipment journey
                </p>
              </div>
              <span
                class="text-xs font-bold px-4 py-2 rounded-full bg-gradient-to-r from-blue-100 to-blue-50 text-blue-700 border border-blue-200"
                >⬇️ Latest first</span
              >
            </div>

            <!-- Timeline -->
            <div class="relative">
              <!-- Vertical line -->
              <div
                class="absolute left-5 top-0 bottom-0 w-0.5 bg-gradient-to-b from-slate-300 via-slate-300 to-transparent"
              ></div>

              <!-- Timeline items -->
              <div
                *ngFor="let item of getTimeline(tracking); let i = index; let isLast = last"
                class="relative mb-8 last:mb-0 animate-in fade-in slide-in-from-left-4"
                [style.animation-delay]="i * 100 + 'ms'"
              >
                <!-- Timeline dot -->
                <div
                  class="absolute left-0 top-1 w-10 h-10 rounded-full border-4 flex items-center justify-center transition-all duration-300 hover:scale-125"
                  [ngClass]="getStatusColor(item.status) + ' shadow-lg'"
                >
                  <div class="w-4 h-4 rounded-full bg-white"></div>
                </div>

                <!-- Content card -->
                <div
                  class="ml-16 p-4 bg-white rounded-xl border-2 border-slate-200 hover:border-slate-300 hover:shadow-md transition-all duration-200"
                >
                  <div
                    class="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-2 mb-2"
                  >
                    <div class="flex items-center gap-2">
                      <span
                        class="text-sm font-black text-slate-700 bg-slate-100 px-3 py-1 rounded-lg text-xs"
                        >{{ i + 1 }}</span
                      >
                      <h3 class="text-base sm:text-lg font-bold text-slate-900">
                        {{ item.displayName || item.status }}
                      </h3>
                    </div>
                    <span
                      class="text-xs font-bold text-slate-500 bg-slate-50 px-3 py-1 rounded-lg whitespace-nowrap"
                    >
                      {{ item.timestamp ? (item.timestamp | date: 'dd-MMM-yyyy') : '—' }}
                    </span>
                  </div>

                  <!-- Time -->
                  <div class="text-sm font-semibold text-blue-700 mb-3 flex items-center gap-1">
                    <span>🕰️</span>
                    {{ item.timestamp ? (item.timestamp | date: 'HH:mm:ss') : 'N/A' }}
                  </div>

                  <!-- Notes -->
                  <div
                    *ngIf="item.notes"
                    class="p-3 bg-blue-50 border-l-4 border-blue-400 rounded mb-3"
                  >
                    <p class="text-sm text-blue-900">{{ item.notes }}</p>
                  </div>

                  <!-- Updated by -->
                  <div
                    *ngIf="item.updatedBy"
                    class="flex items-center gap-2 text-xs text-slate-600 bg-slate-50 px-3 py-2 rounded-lg w-fit"
                  >
                    <span>👤</span>
                    <span>{{ item.updatedBy }}</span>
                  </div>
                </div>

                <!-- Connector line for non-last items -->
                <div
                  *ngIf="!isLast"
                  class="absolute left-9 top-10 w-0.5 h-6 bg-gradient-to-b from-slate-200 to-transparent"
                ></div>
              </div>
            </div>

            <!-- Summary footer -->
            <div class="mt-8 pt-6 border-t-2 border-slate-200">
              <div class="flex flex-col sm:flex-row sm:items-center justify-between gap-3 text-sm">
                <div class="text-slate-600">
                  <span class="font-bold text-slate-900">{{ getTimeline(tracking).length }}</span>
                  <span class="ml-1"
                    >status update{{ getTimeline(tracking).length !== 1 ? 's' : '' }}</span
                  >
                </div>
                <div class="text-slate-500 text-xs">
                  <span *ngIf="getFirstStatusTimestamp(tracking)">
                    Started:
                    <span class="font-semibold text-slate-700">{{
                      getFirstStatusTimestamp(tracking) | date: 'dd-MMM-yyyy HH:mm'
                    }}</span>
                  </span>
                </div>
              </div>
            </div>
          </section>
        </ng-container>

        <!-- Empty State -->
        <section
          *ngIf="!(currentTracking$ | async) && !(loading$ | async) && !(error$ | async)"
          class="bg-white border border-slate-200 rounded-2xl shadow-sm p-12 text-center animate-in fade-in"
        >
          <div class="text-6xl mb-4">🔍</div>
          <h2 class="text-xl font-bold text-slate-900 mb-2">Ready to Track Your Shipment?</h2>
          <p class="text-slate-600 mb-4">
            Enter your booking or order reference in the search field above to get real-time
            tracking updates.
          </p>
          <div class="mt-6 space-y-2">
            <p class="text-sm font-semibold text-slate-700">📦 Accepted Reference Formats:</p>
            <div class="flex flex-wrap justify-center gap-2 mt-2">
              <span class="px-3 py-1.5 bg-slate-100 text-slate-700 rounded-lg text-sm font-mono"
                >BK-2026-00125</span
              >
              <span class="px-3 py-1.5 bg-slate-100 text-slate-700 rounded-lg text-sm font-mono"
                >ORD-2026-00088</span
              >
              <span class="px-3 py-1.5 bg-slate-100 text-slate-700 rounded-lg text-sm font-mono"
                >2025345-00001</span
              >
            </div>
          </div>
          <div
            class="mt-8 p-4 bg-blue-50 border border-blue-200 rounded-xl text-left max-w-md mx-auto"
          >
            <p class="text-sm font-semibold text-blue-900 mb-2">💡 Helpful Tips:</p>
            <ul class="text-sm text-blue-800 space-y-1 list-disc list-inside">
              <li>Check your booking confirmation email for the reference number</li>
              <li>Reference numbers are case-insensitive</li>
              <li>Remove any spaces before searching</li>
              <li>Contact support if you can't find your reference</li>
            </ul>
          </div>
        </section>
      </main>

      <!-- Footer -->
      <footer class="border-t border-slate-200 bg-white mt-20">
        <div class="max-w-5xl mx-auto px-4 py-6">
          <div class="text-sm text-slate-600 text-center mb-4">
            <p class="font-semibold text-slate-900">Need Help?</p>
            <p class="mt-1">
              📧 support&#64;svtrucking.com · 📞 +855 23 999 888 · 🌐 www.svtrucking.com
            </p>
          </div>
          <div class="border-t border-slate-200 pt-4 text-xs text-slate-500 text-center">
            © 2026 SV Trucking Co., Ltd · <span class="font-semibold">🌐 Public Tracking</span> ·
            Made with ❤️ for our customers
          </div>
        </div>
      </footer>
    </div>
  `,
  styles: [
    `
      :host {
        display: block;
        min-height: 100vh;
        background-color: rgb(248 250 252);
      }

      @keyframes slideInFromTop {
        from {
          opacity: 0;
          transform: translateY(-10px);
        }
        to {
          opacity: 1;
          transform: translateY(0);
        }
      }

      @keyframes fadeIn {
        from {
          opacity: 0;
        }
        to {
          opacity: 1;
        }
      }

      .animate-in {
        animation: fadeIn 0.3s ease-in-out forwards;
      }

      .animate-in.slide-in-from-top {
        animation: slideInFromTop 0.3s ease-in-out forwards;
      }

      .delay-100 {
        animation-delay: 100ms;
      }

      .animate-spin {
        animation: spin 1s linear infinite;
      }

      .sr-only {
        position: absolute;
        width: 1px;
        height: 1px;
        padding: 0;
        margin: -1px;
        overflow: hidden;
        clip: rect(0, 0, 0, 0);
        white-space: nowrap;
        border: 0;
      }

      @keyframes spin {
        from {
          transform: rotate(0deg);
        }
        to {
          transform: rotate(360deg);
        }
      }
    `,
  ],
})
export class ShipmentTrackingComponent implements OnInit, OnDestroy {
  searchReference = '';
  liveMessage = '';
  copied = false;

  private trackingService = inject(ShipmentTrackingService);
  private route = inject(ActivatedRoute);

  loading$ = this.trackingService.loading$;
  error$ = this.trackingService.error$;
  currentTracking$ = this.trackingService.currentTracking$;
  locationUpdates$ = this.trackingService.locationUpdates$;

  private destroy$ = new Subject<void>();
  private memoizedTimeline: Map<string, StatusTimeline[]> = new Map();

  ngOnInit(): void {
    // Subscribe to location updates for map display
    this.trackingService.locationUpdates$.pipe(takeUntil(this.destroy$)).subscribe();

    // Auto-load tracking from URL parameter or query param
    // Supports: /tracking/2025345-00001 or /tracking?ref=2025345-00001
    const refFromPath = this.route.snapshot.paramMap.get('ref');
    const refFromQuery = this.route.snapshot.queryParamMap.get('ref');
    const referenceFromUrl = refFromPath || refFromQuery;

    if (referenceFromUrl) {
      this.searchReference = referenceFromUrl;
      // Auto-trigger tracking after component renders
      setTimeout(() => this.onTrack(), 100);
    }
  }

  ngOnDestroy(): void {
    this.memoizedTimeline.clear();
    this.destroy$.next();
    this.destroy$.complete();
  }

  /**
   * Initiates tracking search for the provided reference
   * Validates input and calls tracking service
   * Implements automatic reference validation and suggestion
   */
  onTrack(): void {
    if (!this.searchReference.trim()) {
      return;
    }

    this.trackingService
      .trackShipment(this.searchReference)
      .pipe(takeUntil(this.destroy$))
      .subscribe({
        next: (tracking) => {
          console.log('[Shipment Tracking] Loaded pickup points:', tracking.pickupPoints);
          console.log('[Shipment Tracking] Loaded delivery points:', tracking.deliveryPoints);
          // Announce to screen readers
          this.announceTrackingSuccess(tracking);
        },
        error: (error) => {
          // Error handled by service
          this.announceError(error);
        },
      });
  }

  /**
   * Handle search input changes with debouncing for auto-suggestions
   */
  onSearchChange(): void {
    // Normalize input: trim and uppercase
    this.searchReference = this.searchReference.trim().toUpperCase();

    // Clear any previous error when user modifies input
    if (this.searchReference.length === 0) {
      // Optionally clear tracking data on empty input
    }
  }

  /**
   * Announce tracking success to screen readers
   */
  private announceTrackingSuccess(tracking: TrackingResponse): void {
    const msg = `Shipment ${tracking.shipmentSummary.bookingReference} status: ${tracking.shipmentSummary.status}`;
    this.liveMessage = msg;
  }

  /**
   * Announce errors to screen readers
   */
  private announceError(error: any): void {
    this.liveMessage = error?.message || 'Tracking error occurred';
  }

  /**
   * Gets the timeline for a shipment with memoization
   * @param tracking - The tracking response object
   * @returns Array of status timeline entries
   */
  getTimeline(tracking: TrackingResponse): StatusTimeline[] {
    const key = tracking.shipmentSummary.bookingReference;
    if (!this.memoizedTimeline.has(key)) {
      this.memoizedTimeline.set(key, this.trackingService.getTimeline(tracking));
    }
    return this.memoizedTimeline.get(key)!;
  }

  /**
   * Get the oldest (first) status timeline event - the actual start time
   */
  getFirstStatusTimestamp(tracking: TrackingResponse): string | null {
    const timeline = this.getTimeline(tracking);
    if (!timeline || timeline.length === 0) {
      return null;
    }
    // After reversing sort (newest first), the last item is the oldest
    return timeline[timeline.length - 1]?.timestamp || null;
  }

  /**
   * Gets CSS class for status color coding
   * @param status - Shipment status
   * @returns CSS class string
   */
  getStatusColor(status: ShipmentStatus): string {
    return STATUS_COLORS[status] || 'bg-slate-600';
  }

  /**
   * Gets human-readable display name for shipment status
   * @param status - Shipment status
   * @returns Display name string
   */
  getStatusDisplayName(status: ShipmentStatus): string {
    return STATUS_DISPLAY_NAMES[status] || status;
  }

  /**
   * Safely converts transportation order status to ShipmentStatus type
   * @param status - The transportation order status value (may be null/undefined)
   * @returns Casted ShipmentStatus or default 'PENDING'
   */
  getTransportStatus(status: string | null | undefined): ShipmentStatus {
    return (status || 'PENDING') as ShipmentStatus;
  }

  getDriverInfo(): DriverInfo | undefined {
    return this.trackingService.getDriverInfo();
  }

  getPickupPoints(tracking: TrackingResponse): OrderPoint[] {
    return this.sortPoints(tracking.pickupPoints);
  }

  getDeliveryPoints(tracking: TrackingResponse): OrderPoint[] {
    return this.sortPoints(tracking.deliveryPoints);
  }

  getPrimaryDispatch(tracking: TrackingResponse) {
    return tracking.dispatches && tracking.dispatches.length > 0
      ? tracking.dispatches[0]
      : undefined;
  }

  primaryPickupLabel(tracking: TrackingResponse): string {
    const p = this.getPickupPoints(tracking)[0];
    return p?.name ? p.name : tracking.shipmentSummary.pickupLocation || 'Pickup';
  }

  primaryDeliveryLabel(tracking: TrackingResponse): string {
    const d = this.getDeliveryPoints(tracking)[0];
    return d?.name ? d.name : tracking.shipmentSummary.deliveryLocation || 'Delivery';
  }

  private sortPoints(points: OrderPoint[] | undefined): OrderPoint[] {
    if (!points || points.length === 0) return [];

    return [...points]
      .filter((p): p is OrderPoint => !!p)
      .sort((a, b) => (a.sequence ?? 0) - (b.sequence ?? 0));
  }

  private uniqueStrings(values: Array<string | undefined | null>): string[] {
    const set = new Set<string>();
    values
      .map((v) => (v || '').trim())
      .filter((v) => v.length > 0)
      .forEach((v) => set.add(v));
    return Array.from(set);
  }

  getAdditionalLoadingStops(tracking: TrackingResponse): string[] {
    const existing = new Set<string>(
      (tracking.pickupPoints || [])
        .map((p) => (p.address || '').trim())
        .filter((s) => s.length > 0),
    );
    const candidates = [
      tracking.shipmentSummary.pickupLocation,
      ...(tracking.shipmentSummary.items || []).map((i) => i.loadingPlace),
    ];
    return this.uniqueStrings(candidates).filter((s) => !existing.has(s));
  }

  getAdditionalUnloadingStops(tracking: TrackingResponse): string[] {
    const existing = new Set<string>(
      (tracking.deliveryPoints || [])
        .map((p) => (p.address || '').trim())
        .filter((s) => s.length > 0),
    );
    const candidates = [
      tracking.shipmentSummary.deliveryLocation,
      ...(tracking.shipmentSummary.items || []).map((i) => i.unloadingPlace),
      ...(tracking.shipmentSummary.items || []).map((i) => i.warehouse),
    ];
    return this.uniqueStrings(candidates).filter((s) => !existing.has(s));
  }

  displayLocation(value: string | undefined | null): string {
    const v = (value || '').trim();
    if (!v) return '—';
    const lower = v.toLowerCase();
    if (lower === 'n/a' || lower === 'na' || v === '-' || v === '—') return '—';
    return v;
  }

  private normalizeStop(value: string | undefined | null): string {
    const v = (value || '').trim();
    if (!v) return '';
    const lower = v.toLowerCase();
    if (lower === 'n/a' || lower === 'na' || v === '-' || v === '—') return '';
    return v;
  }

  buildLoadingStops(tracking: TrackingResponse): string[] {
    const set = new Set<string>();
    const push = (s: string | undefined | null) => {
      const n = this.normalizeStop(s);
      if (n) set.add(n);
    };
    // Summary + items
    push(tracking.shipmentSummary.pickupLocation);
    (tracking.shipmentSummary.items || []).forEach((i) => push(i.loadingPlace));
    // Points addresses
    (tracking.pickupPoints || []).forEach((p) => push(p.address));
    return Array.from(set);
  }

  buildUnloadingStops(tracking: TrackingResponse): string[] {
    const set = new Set<string>();
    const push = (s: string | undefined | null) => {
      const n = this.normalizeStop(s);
      if (n) set.add(n);
    };
    // Summary + items
    push(tracking.shipmentSummary.deliveryLocation);
    (tracking.shipmentSummary.items || []).forEach((i) => {
      push(i.unloadingPlace);
      push(i.warehouse);
    });
    // Points addresses
    (tracking.deliveryPoints || []).forEach((p) => push(p.address));
    return Array.from(set);
  }

  getPointStatusDisplay(status?: 'PENDING' | 'ARRIVED' | 'DEPARTED' | 'COMPLETED'): string {
    if (!status) return '—';
    const map: Record<string, string> = {
      PENDING: 'Pending',
      ARRIVED: 'Arrived',
      DEPARTED: 'Departed',
      COMPLETED: 'Completed',
    };
    return map[status] || status;
  }

  getPointStatusColor(status?: 'PENDING' | 'ARRIVED' | 'DEPARTED' | 'COMPLETED'): string {
    switch (status) {
      case 'PENDING':
        return 'bg-yellow-500';
      case 'ARRIVED':
        return 'bg-emerald-600';
      case 'DEPARTED':
        return 'bg-blue-600';
      case 'COMPLETED':
        return 'bg-green-600';
      default:
        return 'bg-slate-400';
    }
  }

  getCurrentLocation(): GeoLocation | null {
    return this.trackingService.getCurrentLocation();
  }

  /**
   * Open Google Maps with the point coordinates
   */
  viewRouteOnMap(point: OrderPoint): void {
    if (point.coordinates) {
      const mapUrl = `https://maps.google.com/?q=${point.coordinates.latitude},${point.coordinates.longitude}`;
      window.open(mapUrl, '_blank');
    }
  }

  getPOD(): ProofOfDelivery | undefined {
    return this.trackingService.getProofOfDelivery();
  }

  /**
   * Copy text to clipboard with visual feedback
   */
  copyToClipboard(text: string): void {
    navigator.clipboard.writeText(text).then(
      () => {
        this.copied = true;
        setTimeout(() => {
          this.copied = false;
        }, 2000);
      },
      (err) => {
        console.error('Failed to copy:', err);
      },
    );
  }

  /**
   * Calculate journey progress percentage
   */
  getProgressPercentage(tracking: TrackingResponse): number {
    const status = tracking.shipmentSummary.status;

    // Map status to progress percentage
    const progressMap: Record<string, number> = {
      PENDING: 0,
      SCHEDULED: 10,
      CONFIRMED: 20,
      IN_PREPARATION: 30,
      READY_FOR_PICKUP: 40,
      PICKED_UP: 50,
      IN_TRANSIT: 60,
      OUT_FOR_DELIVERY: 75,
      ARRIVED: 85,
      DELIVERED: 100,
      COMPLETED: 100,
      CANCELLED: 0,
      ON_HOLD: 45,
    };

    return progressMap[status] ?? 0;
  }

  /**
   * Check if shipment has started
   */
  hasStarted(tracking: TrackingResponse): boolean {
    const status = tracking.shipmentSummary.status;
    return !['PENDING', 'SCHEDULED'].includes(status);
  }

  /**
   * Check if shipment is in transit
   */
  isInTransit(tracking: TrackingResponse): boolean {
    const status = tracking.shipmentSummary.status;
    return ['PICKED_UP', 'IN_TRANSIT'].includes(status);
  }

  /**
   * Check if shipment is near delivery
   */
  isNearDelivery(tracking: TrackingResponse): boolean {
    const status = tracking.shipmentSummary.status;
    return ['OUT_FOR_DELIVERY', 'ARRIVED'].includes(status);
  }

  /**
   * Check if shipment is delivered
   */
  isDelivered(tracking: TrackingResponse): boolean {
    const status = tracking.shipmentSummary.status;
    return ['DELIVERED', 'COMPLETED'].includes(status);
  }

  /**
   * Get estimated time remaining as human-readable string
   */
  getEstimatedTimeRemaining(tracking: TrackingResponse): string | null {
    if (!tracking.shipmentSummary.estimatedDelivery) {
      return null;
    }

    const now = new Date();
    const eta = new Date(tracking.shipmentSummary.estimatedDelivery);
    const diff = eta.getTime() - now.getTime();

    if (diff <= 0) {
      return 'Delivery time reached';
    }

    const hours = Math.floor(diff / (1000 * 60 * 60));
    const days = Math.floor(hours / 24);
    const remainingHours = hours % 24;

    if (days > 0) {
      return `Estimated ${days} day${days > 1 ? 's' : ''} ${remainingHours}h remaining`;
    } else if (hours > 0) {
      const minutes = Math.floor((diff % (1000 * 60 * 60)) / (1000 * 60));
      return `Estimated ${hours}h ${minutes}m remaining`;
    } else {
      const minutes = Math.floor(diff / (1000 * 60));
      return `Estimated ${minutes} minute${minutes !== 1 ? 's' : ''} remaining`;
    }
  }

  /**
   * Get last updated timestamp
   */
  getLastUpdated(tracking: TrackingResponse): Date {
    // Try to get the most recent update from various sources
    const dispatch = this.getPrimaryDispatch(tracking);
    if (dispatch?.completedAt) {
      return new Date(dispatch.completedAt);
    }
    if (dispatch?.createdAt) {
      return new Date(dispatch.createdAt);
    }
    return new Date();
  }
}
